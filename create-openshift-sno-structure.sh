#!/bin/bash

set -euo pipefail

ROOT_DIR="openshift-sno-automation"
DIRS=(
  "$ROOT_DIR/ansible/group_vars"
  "$ROOT_DIR/ansible/playbooks"
  "$ROOT_DIR/ansible/vars"
  "$ROOT_DIR/deployment/openshift"
  "$ROOT_DIR/deployment/previous-run"
  "$ROOT_DIR/contrib"
  "$ROOT_DIR/devel"
  "$ROOT_DIR/old-scripts"
  "$ROOT_DIR/secrets"
)

echo "Creating directories..."
for dir in "${DIRS[@]}"; do
  mkdir -p "$dir"
done

echo "Creating files with template content..."

cat > "$ROOT_DIR/ansible/inventory.yaml" <<EOF
---
all:
  hosts:
    localhost:
      ansible_connection: local
      ansible_user: root
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
      bridge_if: "wlp3s0"
    sno1:
      ansible_host: 192.168.1.100
      ansible_user: core
      ip: 192.168.1.100
      cidr: 192.168.1.0/24
      mac: "525400aabbcc"
      mac_addr: "52:54:00:aa:bb:cc"
      raw_path: "/root/VirtualBox VMs/sno1/sno1.raw"
      iso_path: "../../deployment/agent.x86_64.iso"
      dns: 192.168.1.1
      gateway: 192.168.1.1
EOF

SNO_CIDR=$(grep     -E '^ *cidr:'     "$ROOT_DIR/ansible/inventory.yaml"|cut -d: -f2-|sed -e 's/ *//g')
SNO_IP=$(grep       -E '^ *ip:'       "$ROOT_DIR/ansible/inventory.yaml"|cut -d: -f2-|sed -e 's/ *//g')
SNO_MAC_ADDR=$(grep -E '^ *mac_addr:' "$ROOT_DIR/ansible/inventory.yaml"|cut -d: -f2-|sed -e 's/ *//g')
SNO_DNS=$(grep      -E '^ *dns:'      "$ROOT_DIR/ansible/inventory.yaml"|cut -d: -f2-|sed -e 's/ *//g')
SNO_GATEWAY=$(grep  -E '^ *gateway:'  "$ROOT_DIR/ansible/inventory.yaml"|cut -d: -f2-|sed -e 's/ *//g')

cp secrets/{id_rsa.pub,pull-secret.txt} "$ROOT_DIR/secrets/"
PULL_SECRET_CONTENT=$(cat "$ROOT_DIR/secrets/pull-secret.txt")
SSH_KEY_CONTENT=$(cat "$ROOT_DIR/secrets/id_rsa.pub")

cp contrib/{install-openshift-bin.sh,install-virtualbox-vnc.sh,oc-login.sh,select-failed-pods-to-delete.sh,tp-fan-control.sh,set-max-cpu-speed.sh} "$ROOT_DIR/contrib/"

cp devel/new-version.sh "$ROOT_DIR/devel/"

echo "Delete $ROOT_DIR/deployment/* and dotfiles? (y/N)"
read -r ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  rm -f  "$ROOT_DIR/deployment/"*    2>/dev/null || true
  rm -f  "$ROOT_DIR/deployment/".*    2>/dev/null || true
  rm -rf "$ROOT_DIR/deployment/auth" 2>/dev/null || true
fi

cat > "$ROOT_DIR/deployment/install-config.yaml" <<EOF
---
apiVersion: v1
baseDomain: local
compute:
  - name: worker
    replicas: 0
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  replicas: 1
metadata:
  name: sno-cluster
networking:
  machineNetwork:
    - cidr: $SNO_CIDR
platform:
  none: {}
pullSecret: '$PULL_SECRET_CONTENT'
sshKey: '$SSH_KEY_CONTENT'
EOF

cat > "$ROOT_DIR/deployment/agent-config.yaml" <<EOF
---
apiVersion: v1beta1
kind: AgentConfig
metadata:
  name: sno-cluster
rendezvousIP: $SNO_IP
hosts:
  - hostname: sno1
    role: master
    interfaces:
      - name: enp0s3
        macAddress: $SNO_MAC_ADDR
    rootDeviceHints:
      deviceName: /dev/sda
    networkConfig:
      interfaces:
        - name: enp0s3
          type: ethernet
          state: up
          mac-address: $SNO_MAC_ADDR
          ipv4:
            enabled: true
            address:
              - ip: $SNO_IP
                prefix-length: 24
            dhcp: false
      dns-resolver:
        config:
          server:
            - $SNO_DNS
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: $SNO_GATEWAY
            next-hop-interface: enp0s3
            table-id: 254
EOF

cat > "$ROOT_DIR/deployment/openshift/99-sno1-set-kargs.yaml" <<EOF
---
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  name: 99-sno-kernel-and-resolvconf
  labels:
    machineconfiguration.openshift.io/role: master
spec:
  config:
    ignition:
      version: 3.2.0
    kernelArguments:
      - console=tty0
      - console=ttyS0
      - processor.max_cstate=0
      - intel_idle.max_cstate=0
EOF

cat > "$ROOT_DIR/deployment/openshift/98-core-passwd.yaml" <<EOF
---
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  name: 98-master-core-pass
  labels:
    machineconfiguration.openshift.io/role: master
spec:
  config:
    ignition:
      version: 3.2.0
    systemd:
      units:
      - name: core-password.service
        enabled: true
        contents: |
          [Unit]
          Description=Changes core password
          [Service]
          Type=oneshot
          ExecStart=/bin/bash -c "echo core:redhat | chpasswd"
          [Install]
          WantedBy=multi-user.target
EOF

# 01_generate_timestamp.yml
cat > "$ROOT_DIR/ansible/playbooks/01_generate_timestamp.yml" <<EOF
---
- name: Generate timestamp variable and save to file
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Generate timestamp and save to vars file
      copy:
        dest: "../vars/timestamp.yml"
        content: |
          backup_time: "{{ lookup('pipe', 'date +%Y-%m-%d_%H-%M') }}"
EOF

# 02_configure_tmux_and_env.yaml
TMUX="${TMUX:-}"
cat > "$ROOT_DIR/ansible/playbooks/02_configure_tmux_and_env.yaml" <<EOF
---
# Configure tmux and interactive shell behavior
- name: Configure tmux and bash environment
  hosts: localhost
  become: true
  tasks:
    - name: Check if tmux default command is already in ~/.tmux.conf
      stat:
        path: "{{ ansible_env.HOME }}/.tmux.conf"
      register: tmux_conf_file

    - name: Set tmux default command to bash --login
      lineinfile:
        path: "{{ ansible_env.HOME }}/.tmux.conf"
        line: 'set-option -g default-command "bash --login"'
        create: true
      when: tmux_conf_file.stat.exists == false or
            "'set-option -g default-command \"bash --login\"' not in lookup('file', ansible_env.HOME + '/.tmux.conf')"

    - name: Enable mouse mode in tmux
      lineinfile:
        path: "{{ ansible_env.HOME }}/.tmux.conf"
        line: 'set-option -g mouse on'
        create: true
      when: tmux_conf_file.stat.exists == false or
            "'set-option -g mouse on' not in lookup('file', ansible_env.HOME + '/.tmux.conf')"

    - name: Set scrollback history to 10000 lines
      lineinfile:
        path: "{{ ansible_env.HOME }}/.tmux.conf"
        line: 'set-option -g history-limit 10000'
        create: true
      when: tmux_conf_file.stat.exists == false or
            "'set-option -g history-limit 10000' not in lookup('file', ansible_env.HOME + '/.tmux.conf')"

    - name: Check if tmux session logic exists in ~/.bashrc
      stat:
        path: "{{ ansible_env.HOME }}/.bashrc"
      register: bashrc_file

    - name: Insert tmux auto-start block in ~/.bashrc
      blockinfile:
        path: "{{ ansible_env.HOME }}/.bashrc"
        block: |
          if [ -z "\$TMUX" ] && [[ \$- == *i* ]] && [ -t 0 ]; then
              read -r -p "Do you want to start tmux and run OCP installation? [y/N] " answer
              case "\$answer" in
                  [Yy]*)
                      tmux new-session -d
                      tmux attach-session
                      ;;
                  *)
                      ;;
              esac
          fi
        create: true
      when: bashrc_file.stat.exists == false or "'if command -v tmux' not in lookup('file', ansible_env.HOME + '/.bashrc')"
      #when: bashrc_file.stat.exists == false or "'if command -v tmux &>/dev/null && [ -z \"$TMUX\" ]; then' not in lookup('file', ansible_env.HOME + '/.bashrc')"

    - name: End Playbook and prompt re-login
      meta: end_play
      when: tmux_conf_file.stat.exists == false or bashrc_file.stat.exists == false
EOF

# 03_create_agent_iso.yaml
cat > "$ROOT_DIR/ansible/playbooks/03_create_agent_iso.yaml" <<EOF
---
# Generate OpenShift agent ISO and perform backup
- name: Create and customize agent ISO
  hosts: localhost
  become: true
  gather_facts: false
  tasks:
    - name: Load shared timestamp
      include_vars: "../vars/timestamp.yml"
  
    - name: Set backup_path
      set_fact:
        backup_path: "../../deployment/previous-run/{{ backup_time }}"

    - name: Ensure timestamped backup directory exists
      file:
        path: "{{ backup_path }}"
        state: directory

    - name: Backup yaml files from deployment to backup
      copy:
        src: "../../deployment/{{ item }}"
        dest: "{{ backup_path }}/{{ item }}"
        remote_src: true
        force: true
      loop:
        - agent-config.yaml
        - install-config.yaml

    - name: Backup openshift directory
      synchronize:
        src: "../../deployment/openshift/"
        dest: "{{ backup_path }}/openshift/"
        mode: push

    - name: Run openshift-install agent create image
      command:
        cmd: openshift-install agent create image --dir ../../deployment --log-level debug
      args:
        chdir: "{{ playbook_dir }}"

    - name: Backup deployment ISO
      copy:
        src: "../../deployment/agent.x86_64.iso"
        dest: "{{ backup_path }}/agent.x86_64.iso"
        remote_src: true
        force: true

    - name: Backup auth directory
      synchronize:
        src: "../../deployment/auth/"
        dest: "{{ backup_path }}/auth/"
        mode: push

    - name: Launch OpenShift installer monitor via tmux
      shell: >
        tmux split-window -h "sleep 20;openshift-install --dir /root/ocp/openshift-sno-automation/deployment agent wait-for install-complete --log-level=debug;read -p 'Finished.'" \; resize-pane -L 50 \; split-window -h "bash" \; resize-pane -R 10 \; select-pane -t 2
      async: 10
      poll: 0
EOF

# 04_configure_hypervisor_access.yaml
cat > "$ROOT_DIR/ansible/playbooks/04_configure_hypervisor_access.yaml" <<EOF
---
# Prepare DNS and SSH settings on hypervisor
- name: Configure SSH settings for root
  hosts: localhost
  become: true
  gather_facts: false
  tasks:
    - name: Create /root/.ssh/config
      copy:
        dest: /root/.ssh/config
        content: |
          Host sno1
              Hostname              192.168.1.100
              User                  core

          Host *
              StrictHostKeyChecking no
              UserKnownHostsFile    /dev/null
              LogLevel              QUIET
        owner: root
        group: root
        mode: '0644'

- name: Add /etc/hosts entries for sno-cluster
  hosts: localhost
  become: true
  gather_facts: false
  tasks:
    - name: Add SNO DNS entries to /etc/hosts
      lineinfile:
        path: /etc/hosts
        line: "{{ item }}"
        state: present
      loop:
        - "192.168.1.100 sno1.sno-cluster.local"
        - "192.168.1.100 api.sno-cluster.local"
        - "192.168.1.100 oauth-openshift.apps.sno-cluster.local"
        - "192.168.1.100 console-openshift-console.apps.sno-cluster.local"
EOF

# 05_create_virtualbox_vm.yaml
cat > "$ROOT_DIR/ansible/playbooks/05_create_virtualbox_vm.yaml" <<EOF
---
# Create VirtualBox VM with disk, ISO and boot setup
- name: Create VirtualBox VM for OpenShift
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Remove existing VM if exists
      shell: |
        if VBoxManage list vms | grep -q "\"{{ item }}\""; then
          VBoxManage controlvm "{{ item }}" poweroff || true
          VBoxManage unregistervm "{{ item }}" --delete-all
        fi
      loop:
        - sno1

    - name: Remove existing disk image
      shell: |
        if [ -f "{{ hostvars['sno1'].raw_path }}" ]; then
          echo "Deleting existing VDI: {{ hostvars['sno1'].raw_path }}"
          VBoxManage closemedium disk "{{ hostvars['sno1'].raw_path }}" --delete || true
        fi
      loop:
        - sno1

    - name: Create disk image
      shell: |
        VBoxManage createmedium disk --filename "{{ hostvars['sno1'].raw_path }}" --size 153600 --format raw --variant Fixed
      loop:
        - sno1

    - name: Create and configure VirtualBox VM
      shell: |
        VBoxManage createvm --name "{{ item }}" --register
        VBoxManage modifyvm "{{ item }}" --memory 20480 --cpus 8 --ioapic on
        VBoxManage modifyvm "{{ item }}" --nic1 bridged --bridgeadapter1 "{{ hostvars['localhost'].bridge_if }}" --nictype1 virtio
        VBoxManage modifyvm "{{ item }}" --macaddress1 "{{ hostvars['sno1'].mac }}"
        VBoxManage modifyvm "{{ item }}" --vrde on --vrdeport 5900 --vrdeproperty VNCPassword=vnc
        VBoxManage storagectl "{{ item }}" --name "VirtIO Controller" --add virtio --controller VirtIO --hostiocache on
        VBoxManage storageattach "{{ item }}" --storagectl "VirtIO Controller" --port 0 --device 0 --type hdd --medium "{{ hostvars['sno1'].raw_path }}" --nonrotational on || true
        VBoxManage storageattach "{{ item }}" --storagectl "VirtIO Controller" --port 1 --device 0 --type dvddrive --medium "{{ hostvars['sno1'].iso_path }}" || true
        VBoxManage modifyvm "{{ item }}" --boot1 disk --boot2 dvd --boot3 none --boot4 none
      loop:
        - sno1

    - name: Start VirtualBox VM
      shell: |
        VBoxManage startvm "{{ item }}" --type headless
      loop:
        - sno1
EOF

# 06_check_node_ready.yaml
cat > "$ROOT_DIR/ansible/playbooks/06_check_node_ready.yaml" <<'EOF'
---
# Final readiness check of OpenShift nodes
- name: Wait for OpenShift nodes to become ready
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Load shared timestamp
      include_vars: "../vars/timestamp.yml"

    - name: Set backup_path
      set_fact:
        backup_path: "../../deployment/previous-run/{{ backup_time }}"
  
    - name: Pause for 3600 seconds
      pause:
        seconds: 3600

    - name: Backup install log files from deployment to backup
      copy:
        src: "../../deployment/{{ item }}"
        dest: "{{ backup_path }}/{{ item }}"
        remote_src: true
        force: true
      loop:
        - .openshift_install.log
        - .openshift_install_state.json

    - name: Show oc login command
      shell: |
          oc login -u kubeadmin -p $(cat ../../deployment/auth/kubeadmin-password) \
            https://api.sno-cluster.local:6443 --insecure-skip-tls-verify

    - name: Check nodes readiness
      shell: oc get nodes --kubeconfig ../../deployment/auth/kubeconfig  --no-headers | grep -v Ready || true
      register: result
      retries: 60
      delay: 30
      until: result.stdout_lines | length == 0
      failed_when: false
EOF

cat > "$ROOT_DIR/ansible/playbooks/site.yaml" <<EOF
---
- import_playbook: 01_generate_timestamp.yml
- import_playbook: 02_configure_tmux_and_env.yaml
- import_playbook: 03_create_agent_iso.yaml
- import_playbook: 04_configure_hypervisor_access.yaml
- import_playbook: 05_create_virtualbox_vm.yaml
- import_playbook: 06_check_node_ready.yaml
EOF

echo "All directories and files with content have been created successfully."
echo ""
tree -a $ROOT_DIR
echo ""
echo "Run: ansible-playbook -v -i openshift-sno-automation/ansible/inventory.yaml openshift-sno-automation/ansible/playbooks/site.yaml"
read -p "Do you want to run this command? (y/N): " answer

if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
  ansible-playbook -v -i openshift-sno-automation/ansible/inventory.yaml openshift-sno-automation/ansible/playbooks/site.yaml
else
  echo "Canceled."
fi
