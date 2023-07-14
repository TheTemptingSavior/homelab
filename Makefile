reqs:
	python3 -m venv venv
	venv/bin/pip3 install -r requirements.txt
	venv/bin/ansible-galaxy collection install -p ./galaxy_collections community.general
	venv/bin/ansible-galaxy collection install -p ./galaxy_collections kubernetes.core
	venv/bin/ansible-galaxy install -p ./galaxy_roles geerlingguy.glusterfs


ping:
	ansible all -m ping -i inventory/homelab/hosts.ini


run:
	ansible-playbook -i inventory/$(INVENTORY)/hosts.ini --vault-password-file=.vault-password playbooks/$(PLAYBOOK)

