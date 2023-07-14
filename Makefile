install:
	ansible-playbook -i inventory/homelab/hosts.ini install.yml

uninstall:
	ansible-playbook -i inventory/homelab/hosts.ini uninstall.yml