# Build a Kubernetes cluster using k3s via Ansible

## Usage

```bash
make install
```

## Kubeconfig

To get access to your **Kubernetes** cluster just

```bash
scp debian@master_ip:~/.kube/config ~/.kube/config
```

## Setup ArgoCD

Run the following playbook against the new inventory:

```bash
make bootstrap
```

Once ArgoCD is installed, you can access the dashboard from `argocd.codekernel.co.uk`. 


## Notes
```bash
    ansible-vault encrypt_string \
        --vault-password-file=.vault-password \
        --name='the_secret' \
        'super_secret_thing'
```