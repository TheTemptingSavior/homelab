# Build a Kubernetes cluster using k3s via Ansible

## Usage

```bash
make install
```

## Kubeconfig

To get access to your **Kubernetes** cluster just

```bash
scp ubuntu@master_ip:~/.kube/config ~/.kube/config
```

## Setup ArgoCD

Run the following playbook against the new inventory:

```bash
make bootstrap
```

Once [ArgoCD](https://github.com/argoproj/argo-cd) is installed, you can access the dashboard from
`argocd.codekernel.co.uk`. 


## Secrets

Some applications require secrets. Kubernetes secrets, by default, are not encrypted and therefore not safe to store
within a Git repo. The solution used here is [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets). However,
if you are resetting the cluster, or for some  other reason, end up removing the sealed secrets deployment, then all
the secrets will no longer be accessible and will need to be remade.

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
  --from-literal=JWT_TOKEN=helloworld \
  --from-literal=SESSION_ENCRYPTION_KEY=helloworld \
  --from-literal=STORAGE_ENCRYPTION_KEY=helloworld \
  | kubeseal -o yaml > ./manifests/apps/00-core/01-authelia/02-sealed-secret.yml
```

### Development

#### Gitea
```bash
kubectl create secret generic postgres-secret \
    --output=yaml \
    --dry-run=client \
    --namespace=gitea \
    --from-literal=POSTGRES_PASSWORD=helloworld \
    | kubeseal -o yaml > ./manifests/apps/02-development/01-gitea/03-postgres-secret-sealed.yml
```

```bash
kubectl create secret generic gitea-secret \
    --output=yaml \
    --dry-run=client \
    --namespace=gitea \
    --from-literal=GITEA__database__PASSWD=hello_world_but_32_characters_XX \
    --from-literal=GITEA__security__SECRET_KEY=helloworld \
    | kubeseal -o yaml > ./manifests/apps/02-development/01-gitea/09-gitea-secret-sealed.yml
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