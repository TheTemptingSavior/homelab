install:
	ansible-playbook -i inventory/homelab/hosts.ini --vault-password-file=.vault-password install.yml

uninstall:
	ansible-playbook -i inventory/homelab/hosts.ini --vault-password-file=.vault-password uninstall.yml

bootstrap:
	ansible-playbook \
		-i inventory/homelab/hosts.ini \
		--vault-password-file=.vault-password \
		bootstrap.yml

ping:
	ansible all -m ping -i inventory/homelab/hosts.ini

decrypt:
	ansible-vault decrypt \
		--vault-password-file=.vault-password \
		inventory/homelab/group_vars/vault.yml

encrypt:
	ansible-vault encrypt \
		--vault-password-file=.vault-password \
		inventory/homelab/group_vars/vault.yml

gitinit:
	@./git-init.sh
	@echo "ansible vault pre-commit hook installed"
	@echo "don't forget to create a .vault-password too"