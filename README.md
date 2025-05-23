# 🚀 openshift-sno-automation

A self-contained automation project to set up a **Single Node OpenShift (SNO)** cluster for OpenShift 4.18 on a **VirtualBox** running on **Fedora 42 Server**.  
The setup is ideal for reproducible, isolated local labs using bridge-mode networking.

This project offers a lightweight alternative to full-blown templating by **directly generating YAML and Ansible configurations via Bash scripting**, focusing on clarity and version-controlled structure.

---

## 📁 Project Structure

```
openshift-sno-automation/
├── 📂 ansible/                     # 📜 Ansible playbooks to drive installation
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
└── 🧰 create-openshift-sno-structure_v88.sh  # 🚀 Main script for generating structure and configs
```

---

## 🔧 What This Script Does

The main script `create-openshift-sno-structure_v83.sh` performs the following:

- Creates and sanitizes the working directory layout
- Copies the user-provided `id_rsa.pub` and `pull-secret.txt` into `secrets/`
- Generates:
  - `install-config.yaml`
  - `agent-config.yaml`
  - `agent.x86_64.iso` (boot media)
  - ignition config  - NMState network YAML files via `openshift-install`
  - Password-injection manifest (`98-core-passwd.yaml`)
  - kargs set manifest (`99-sno-set-kargs.yaml`)
- Detects and uses predefined cluster name and base domain
- Automatically backs up previously generated artifacts
- Leaves Ansible playbooks ready to execute under `ansible/`

---

## 🚀 Getting Started

### 1. Prepare your Fedora 42 Server

You should already have a minimal Fedora 42 Server running in VirtualBox with a bridged NIC.

### 2. Install dependencies

Install required CLI tools manually or use the helpers in `contrib/`:

```
$ ./contrib/install-openshift-bin.sh  # Downloads openshift-install, oc, butane
$ ./contrib/install-virtualbox.sh     # (Optional) Installs VirtualBox
```

### 3. Place required secrets

```
mkdir -p secrets/
cp ~/.ssh/id_rsa.pub secrets/id_rsa.pub
cp ~/Downloads/pull-secret.txt secrets/pull-secret.txt
```

### 4. Run the setup script

```
$ bash ./create-openshift-sno-structure_v83.sh
```

This will generate everything under `generated/`, and print output like:

```
✅ install-config.yaml created.
✅ ignition files generated.
✅ agent.x86_64.iso created.
📁 backed up previously generated artifacts to previous-run/2025-05-21_00-30
```

---

## 📦 What You'll Get

- `deployment/agent.x86_64.iso`: Bootable ISO for the SNO node
- `deployment/openshift/*.yaml`: Hostname + password override manifests
- `deployment/auth/`: Includes `kubeadmin-password`, `kubeconfig`
- `ansible/*.yml`: Playbooks to automate next steps

---

## 💡 Tips

- The script is **idempotent** — you can rerun it after modifying `secrets/` or base variables.
- All generated configurations are tagged and archived by timestamp for reproducibility.
- Designed for **clarity over complexity**: no `.j2` templates or dynamic inventory required.

---

## ✅ Next Steps

To login into the cluster:
```
$ export KUBECONFIG=deployment/auth/kubeconfig
$ oc login -u kubeadmin -p "$PASSWORD" "$API_URL" --insecure-skip-tls-verify
```
---
## 🧪 First Run Example

After downloading the following files into your working directory:

- `create-openshift-sno-structure_v87.sh`
- `install-openshift-bin_v3.sh`
- `install-virtualbox-vnc.sh`
- `oc-login_v4.sh`
- `select-failed-pods-to-delete.sh`
- `tp-fan-control.sh`
- `id_rsa.pub`
- `pull-secret.txt`

You can execute the main script. Here's what the initial run typically looks like:

```
# ./create-openshift-sno-structure_v88.sh 
Creating directories...
Creating files with template content...
Delete openshift-sno-automation/deployment/* and dotfiles? (y/N)

All directories and files with content have been created successfully.

openshift-sno-automation
├── ansible
│   ├── group_vars
│   ├── inventory.yaml
│   ├── playbooks
│   │   ├── 01_generate_timestamp.yml
│   │   ├── 02_configure_tmux_and_env.yaml
│   │   ├── 03_create_agent_iso.yaml
│   │   ├── 04_prepare_hypervisor_dns.yaml
│   │   ├── 05_create_virtualbox_vm.yaml
│   │   ├── 06_check_node_ready.yaml
│   │   └── site.yaml
│   └── vars
│       └── timestamp.yml
├── contrib
│   ├── install-openshift-bin_v3.sh
│   ├── install-virtualbox-vnc.sh
│   ├── oc-login_v4.sh
│   ├── select-failed-pods-to-delete.sh
│   └── tp-fan-control.sh
├── deployment
│   ├── agent-config.yaml
│   ├── install-config.yaml
│   ├── openshift
│   │   ├── 98-core-passwd.yaml
│   │   └── 99-sno1-set-kargs.yaml
│   ├── .openshift_install.log
│   └── previous-run
│       ├── 2025-05-23_07-05
│       │   ├── agent-config.yaml
│       │   ├── agent.x86_64.iso
│       │   ├── auth
│       │   │   ├── kubeadmin-password
│       │   │   └── kubeconfig
│       │   ├── install-config.yaml
│       │   ├── openshift
│       │   │   ├── 98-core-passwd.yaml
│       │   │   └── 99-sno1-set-kargs.yaml
│       │   ├── .openshift_install.log
│       │   └── .openshift_install_state.json
│       ├── 2025-05-23_09-59
│       │   ├── agent-config.yaml
│       │   ├── install-config.yaml
│       │   └── openshift
│       │       ├── 98-core-passwd.yaml
│       │       └── 99-sno1-set-kargs.yaml
│       └── 2025-05-23_10-04
│           ├── agent-config.yaml
│           ├── install-config.yaml
│           └── openshift
│               ├── 98-core-passwd.yaml
│               └── 99-sno1-set-kargs.yaml
└── secrets
    ├── id_rsa.pub
    └── pull-secret.txt

17 directories, 38 files

Run: ansible-playbook -v -i openshift-sno-automation/ansible/inventory.yaml openshift-sno-automation/ansible/playbooks/site.yaml
Do you want to run this command? (y/N): 
Canceled.

```

This script sets up the full structure and prepares everything needed to proceed with Ansible-driven automation.

---

## 📜 License

MIT License. See `LICENSE` file for details.

---

## 📬 Author

Masaki Furuta (GitHub: [masaki-furuta](https://github.com/masaki-furuta))  
Feel free to open Issues or PRs for suggestions.
