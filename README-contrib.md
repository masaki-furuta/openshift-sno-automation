# 📂 contrib/

This directory provides helper scripts and configurations to assist in building a local OpenShift 4.18 Single Node (SNO) cluster on Fedora Server 42 running on ThinkPad W541 with VirtualBox over Wi-Fi (bridged mode). These tools are not mandatory but ease host system preparation before running the main Ansible automation.

---

## 📄 Included Scripts & Files

### 🧰 `anaconda-ks.cfg`
- Kickstart file for automatic Fedora Server 42 installation
- Optimized for ThinkPad W541
- Prepares system for virtualization and OpenShift

### 📦 `install-virtualbox-vnc.sh`
- Installs VirtualBox + dependencies + VNC support
- Required to run OCP VM with bridged networking

### 🧪 `install-openshift-bin_v3.sh`
- Installs CLI tools: `oc`, `openshift-install`, `butane`
- Installs into `$HOME/.local/bin`

### 🔐 `oc-login_v4.sh`
- CLI login helper for OpenShift cluster
- Supports interactive and automatic login

### 🧹 `select-failed-pods-to-delete.sh`
- Deletes failed Pods in current or all namespaces
- Useful for cleanup during repeated testing

### 🌡️ `tp-fan-control.sh`
- Fan control for ThinkPad to manage thermal load
- Recommended during VM/cluster operation

---

## 🛠️ Requirements

- Fedora Server 42 (recommended via `anaconda-ks.cfg`)
- Manually prepare your SSH public key for manifests
- OCP Pull Secret must be obtained separately

---

## 🚀 Usage Flow

1. 🖥️ Install Fedora using `anaconda-ks.cfg`
2. 📥 Run `install-virtualbox-vnc.sh` to prepare VirtualBox
3. 🔧 Run `install-openshift-bin_v3.sh` to install CLI tools
4. 🔐 Use `oc-login_v4.sh` to connect to the cluster
5. 🌬️ Optionally run `tp-fan-control.sh` for fan tuning
6. 🧹 Use `select-failed-pods-to-delete.sh` for cleanup
