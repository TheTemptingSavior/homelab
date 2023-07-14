# Build a Kubernetes cluster using k3s via Ansible

## Notes
- Chosen `flannel` backend is `host-gw`. This is because there are known issues with the `externalTrafficPolicy` being
  set to `local` when using `ingress-nginx` and getting the real IPs of remote clients

## Usage

Create a file called `.vault-password` in the root of this repository and paste your password for the encrypted Ansible
variables here. If you don't have one yet, create a new password now.

By default, the install process will set up a custom registry in DigitalOcean. If you do not have one you should set
`custom_registries` to `no` in `inventory/homelab/group_vars/all.yml`. If you do have a custom registry in DigitalOcean
update the `do_registry_key` using the `encrypt_string` command at the bottom of this README.

Then install the basic K3S cluster:
```bash
make install
```

## Kubeconfig

To get access to your **Kubernetes** cluster just

```bash
scp ubuntu@master_ip:~/.kube/config ~/.kube/config
kubectl get nodes -o wide
```

## Secrets

The encrypted secrets in this repository are for an example cluster and have been encrypted using the sealed-secrets
controller previously installed on it. You will need to re-encrypt all the secrets used in this repository using your 
own Sealed Secrets controller with its own certificate.

The method used here is to create a custom certificate/key pair and encrypt it in `inventory/homelab/group_vars/all.yml`
where it can then be templated into the remote cluster. This means that across cluster setups and teardowns you can use
one set of encrypted secrets because Sealed Secrets will use the same certificate/key pair each time.

### Setting Up Certificates

If you don't already have a certificate/key pair in your Ansible vars file then you should run the following to generate
them now:
```bash
export PRIVATEKEY="mytls.key"
export PUBLICKEY="mytls.crt"
export NAMESPACE="kube-system"
export SECRETNAME="mycustomkeys"

openssl req -x509 \
            -nodes \
            -newkey rsa:4096 \
            -days 3650 \
            -keyout "$PRIVATEKEY" \
            -out "$PUBLICKEY" \
            -subj "/CN=sealed-secret/O=sealed-secret"

CRT=$(cat $PUBLICKEY | base64)
KEY=$(cat $PRIVATEKEY | base64)
# Make sure to remove the newlines from the output
# Paste the outputs into the all.yml file
ansible-vault encrypt_string \
        --vault-password-file=.vault-password \
        --name='sealed_secrets_crt' "$CRT"
ansible-vault encrypt_string \
        --vault-password-file=.vault-password \
        --name='sealed_secrets_key' "$KEY"
```

Now that you have the certificates setup, you can run the bootstrap playbook to install ArgoCD, Cert Manager, Ingress
Nginx and Sealed Secrets. Once this is done you should go down this README and rerun all the secret creation so that
the encrypted secrets all use the new certificate/key that you created earlier. Make sure to change the default values.

## Setup Core Services

Before starting you need to make sure you reset the variables to your own values:
```bash
ansible-vault encrypt_string \
        --vault-password-file=.vault-password \
        --name='email_address' 'admin@example.com'
ansible-vault encrypt_string \
        --vault-password-file=.vault-password \
        --name='do_access_token' 'token'
ansible-vault encrypt_string \
        --vault-password-file=.vault-password \
        --name='do_access_token_base64' 'base64_encoded_token'
```

By default, this setup will install a DigitalOcean wildcard DNS certificate using Let's Encrypt. You may want to remove
these parts from the `roles/k3s-yaml/cert-manager` folder if this doesn't apply here. I would strongly recommend it
though as creating a wildcard certificate means you can use HTTPS across the services in the cluster using the default
certificate.

Run the following playbook against the new inventory:

```bash
make bootstrap
```

Once [ArgoCD](https://github.com/argoproj/argo-cd) is installed, you can access the dashboard from
`argocd.codekernel.co.uk`. 

## System

The system manifests folder contains YAML to setup [Rancher](https://github.com/rancher/rancher) for managing the
cluster, [Longhorn](https://github.com/longhorn/longhorn) for persistent, highly-available, storage and a
[Prometheus-based](https://github.com/prometheus-operator/kube-prometheus) monitoring stack (includes 
[Grafana](https://github.com/grafana/grafana)).

The monitoring stack is a modified version of `prometheus-community/kube-prometheus-stack` specifically to tie in well
with the Rancher management system.

### Core

#### Authelia
```bash
kubectl create secret generic authelia-secret \
  --output=yaml \
  --dry-run=client \
  --namespace=authelia \
  --from-literal=JWT_SECRET=helloworld \
  --from-literal=SESSION_SECRET=helloworld \
  --from-literal=STORAGE_PASSWORD=helloworld \
  --from-literal=SESSION_ENCRYPTION_KEY=helloworld \
  --from-literal=STORAGE_ENCRYPTION_KEY=helloworld \
  | kubeseal -o yaml --cert=./inventory/homelab/group_vars/mytls.crt > ./manifests/apps/00-core/01-authelia/04-sealed-secret.yml
```

#### Gotify
```bash
kubectl create secret generic gotify-secret \
  --output=yaml \
  --dry-run=client \
  --namespace=gotify \
  --from-literal=GOTIFY_DEFAULTUSER_NAME=admin \
  --from-literal=GOTIFY_DEFAULTUSER_PASS=admin \
  | kubeseal -o yaml --cert=./inventory/homelab/group_vars/mytls.crt > ./manifests/apps/00-core/03-gotify/02-sealed-secret.yml
```

### Development

#### Gitea
```bash
kubectl create secret generic postgres-secret \
    --output=yaml \
    --dry-run=client \
    --namespace=gitea \
    --from-literal=POSTGRES_PASSWORD=helloworld \
    | kubeseal -o yaml --cert=./inventory/homelab/group_vars/mytls.crt > ./manifests/apps/02-development/01-gitea/02-postgres-secret-sealed.yml
```

```bash
kubectl create secret generic gitea-secret \
    --output=yaml \
    --dry-run=client \
    --namespace=gitea \
    --from-literal=GITEA__database__PASSWD=helloworld \
    --from-literal=GITEA__security__SECRET_KEY=hello_world_but_32_characters_XX \
    | kubeseal -o yaml --cert=./inventory/homelab/group_vars/mytls.crt > ./manifests/apps/02-development/01-gitea/08-gitea-secret-sealed.yml
```

#### Drone
```bash
kubectl create secret generic drone-secret \
    --output=yaml \
    --dry-run=client \
    --namespace=drone \
    --from-literal=DRONE_RPC_SECRET=helloworld \
    --from-literal=DRONE_GITEA_CLIENT_ID=helloworld \
    --from-literal=DRONE_GITEA_CLIENT_SECRET=helloworld \
    | kubeseal -o yaml --cert=./inventory/homelab/group_vars/mytls.crt > ./manifests/apps/02-development/02-drone/01-secret-sealed.yml
```

```bash
kubectl create secret generic drone-runner-secret \
  --output=yaml \
  --dry-run=client \
  --namespace=drone \
  --from-literal=DRONE_RPC_SECRET=helloworld \
  | kubeseal -o yaml --cert=./inventory/homelab/group_vars/mytls.crt > ./manifests/apps/02-development/02-drone/09-runner-secret-sealed.yml
```

### Files

#### Nextcloud

```bash
kubectl create secret generic mariadb-secret \
    --output=yaml \
    --dry-run=client \
    --namespace=nextcloud \
    --from-literal=MYSQL_PASSWORD=helloworld \
    | kubeseal -o yaml --cert=./inventory/homelab/group_vars/mytls.crt > ./manifests/apps/03-files/01-nextcloud/02-mariadb-secret-sealed.yml
```

```bash
kubectl create secret generic nextcloud-secret \
    --output=yaml \
    --dry-run=client \
    --namespace=nextcloud \
    --from-literal=MYSQL_PASSWORD=helloworld \
    | kubeseal -o yaml --cert=./inventory/homelab/group_vars/mytls.crt > ./manifests/apps/03-files/01-nextcloud/08-nextcloud-secret-sealed.yml
```

## Notes

### Ansible Vault

The encrypted variables in the vars file can be created with the following

```bash
    ansible-vault encrypt_string \
        --vault-password-file=.vault-password \
        --name='the_secret' \
        'super_secret_thing'
```

### Get Your Certificate Back

```bash
 ansible master \
      --vault-password-file=.vault-password \
      -i ./inventory/homelab/hosts.ini \
      -m debug \
      -a 'var=sealed_secrets_crt'
 echo "<base64 encoded secret here>" | base64 -d > ./inventory/homelab/group_vars/mytls.crt
```