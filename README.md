# 🚀 openshift-sno-automation (Bash version)

This project provides an automated setup for **Single Node OpenShift (SNO)** 4.18 clusters on **VirtualBox** running on **Fedora 42 Server**.  
It is designed for repeatable and self-contained deployments using bridged networking.

No `.j2` templating is used. Everything is generated dynamically using Bash scripting for transparency and reproducibility.

---

## 📁 Directory Structure

```
openshift-sno-automation/
├── 📂 ansible/                     # 📜 Ansible playbooks to drive installation
│   ├── 📂 common/                  # ⏱️ Shared tasks (e.g., start/end timer)
│   ├── 📂 playbooks/               # ▶️ Step-by-step Ansible workflows
│   ├── 📂 vars/                    # 📌 Runtime variables (e.g., timestamps)
│   └── 🧾 inventory.yaml           # 🧭 Inventory for local + sno1 node
│
├── 📂 contrib/                     # 🛠️ Helper scripts (VirtualBox, CLI tools, kickstart)
│
├── 📂 deployment/                  # 📦 All generated files (install-config, manifests, ignition, ISO)
│   ├── 🔐 auth/                    # 🔑 kubeadmin credentials, kubeconfig
│   ├── 🕒 previous-run/            # 🗂️ Timestamped backups of previous runs
│   └── 🧾 openshift/               # 🧩 Custom OpenShift manifests
│
├── 📂 secrets/                     # 🔐 SSH keys and pull-secret.txt (manually placed)
│   ├── 🔑 id_rsa.pub
│   └── 🧾 pull-secret.txt
│
└── 🧰 create-openshift-sno-structure.sh  # 🚀 Main script for generating structure and configs
```

---

## 🔧 What `create-openshift-sno-structure.sh` Does

This script is the main entry point. It:

- Creates all required folders
- Generates:
  - `install-config.yaml`
  - `agent-config.yaml`
  - `inventory.yaml`
  - `98-core-passwd.yaml` (injects core password)
  - `99-sno1-set-kargs.yaml` (kernel arguments)
- Runs `openshift-install agent create ignition-configs`
- Generates the `agent.x86_64.iso`
- Sets up tmux environment for easy monitoring
- Backs up previous artifacts to `deployment/previous-run/`

---

## 🚀 Quick Start

### 1. Prepare the Environment

- Run on Fedora 42 Server
- Use bridged networking on VirtualBox
- Ensure the following files exist:

```bash
mkdir -p secrets/
cp ~/.ssh/id_rsa.pub secrets/id_rsa.pub
cp ~/Downloads/pull-secret.txt secrets/pull-secret.txt
```

### 2. Install Required Tools

```bash
./contrib/install-required-rpms.sh
./contrib/install-openshift-bin.sh
./contrib/install-virtualbox-vnc.sh
```

### 3. Run the Main Script

```bash
bash create-openshift-sno-structure.sh
```

This will interactively prompt for cleanup and generate deployment files.

---

## ✅ Logging In

```bash
export KUBECONFIG=deployment/auth/kubeconfig
oc login -u kubeadmin -p "$(cat deployment/auth/kubeadmin-password)" \
  https://api.sno-cluster.test:6443 --insecure-skip-tls-verify
```

---

## 🧪 First Run Example

After generation:

```bash
ansible-playbook -i openshift-sno-automation/ansible/inventory.yaml \
  openshift-sno-automation/ansible/playbooks/site.yaml
```

---

## 📌 Notes

- No `.j2` templates or `template` module used
- Designed for easy debugging and reusability
- Works entirely offline after binary and ISO download
- ❗ **Important**: Before executing Ansible playbooks, ensure that your `inventory.yaml` contains correct values for your laptop's **Wi-Fi interface** if using bridged networking. Specifically:
  - `ansible_host`: Static IP address assigned to the VirtualBox SNO VM
  - `ansible_interface`: Name of the Wi-Fi interface on your host (e.g. `wlp3s0`, `wlan0`)
  - `ipv4_gateway`: Your Wi-Fi router’s IP address (default gateway)
  - `dns_servers`: Usually your router (e.g. `192.168.1.1`) or public DNS like `8.8.8.8`
  
Example snippet:
```yaml
all:
  hosts:
    sno1:
      ansible_host: 192.168.1.100
      ansible_interface: wlp3s0
      ipv4_gateway: 192.168.1.1
      dns_servers:
        - 192.168.1.1
```

Ensure these values reflect your actual laptop network configuration before deployment.
