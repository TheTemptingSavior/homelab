- name: Install Dependencies
  apt:
    name: ['python3-pip', 'python3-setuptools', 'python3', 'python3-venv']
    state: latest
    update_cache: yes

- name: Install kubernetes pip package
  pip:
    name: kubernetes