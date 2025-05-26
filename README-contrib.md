# 📂 contrib/

This directory contains supplementary scripts and configuration files to assist in setting up a local OpenShift 4.18 Single Node (SNO) cluster on Fedora Server 42 running on a ThinkPad W541.

---

## 🛠️ Installation & Setup Scripts

The following scripts are designed to install and prepare the host environment. Run them in the order below:

### 🧰 `anaconda-ks.cfg`
- Kickstart file for headless automated Fedora Server 42 installation
- Optimized for ThinkPad W541 hardware with virtualization enabled

### 📦 `install-required-rpms.sh`
- Installs essential packages needed before running any VirtualBox or OpenShift-related tools (e.g. kernel headers, libvirt, socat, etc.)

### 🔧 `install-openshift-bin.sh`
- Installs OpenShift CLI tools: `oc`, `openshift-install`, `butane`
- Installs them into `$HOME/.local/bin`

### 💻 `install-virtualbox-vnc.sh`
- Installs VirtualBox and enables VNC support
- Ensures VirtualBox is correctly configured for Wi-Fi bridged networking

---

## 🧩 Utility Scripts

These scripts are optional but useful for operating and maintaining the cluster environment.

### 🔐 `oc-login.sh`
- CLI-based login helper to select and use kubeconfig files interactively

### 🧹 `select-failed-pods-to-delete.sh`
- Finds and deletes failed pods either in a specific namespace or across all

### 🌡️ `tp-fan-control.sh`
- Controls fan speed for ThinkPad laptops to reduce overheating during OCP operation

### 🧲 `set-max-cpu-speed.sh`
- Sets CPU to maximum performance mode for VirtualBox and OCP workloads

### 🚦 `set-virtualbox-priority.sh`
- Sets VirtualBox VM process to real-time priority using `chrt`

### 📶 `disable-iwlwifi-powersave.sh`
- Disables power-saving on Intel Wi-Fi adapters to ensure stable connectivity during bridged networking

---

## 📌 Requirements

- Fedora Server 42 (preferably installed using the provided kickstart)
- SSH key and OCP pull-secret must be prepared manually
- Internet connectivity for downloading dependencies

---

## 🚀 Usage Flow

1. Install Fedora using `anaconda-ks.cfg`
2. Run `install-required-rpms.sh`
3. Run `install-virtualbox-vnc.sh`
4. Run `install-openshift-bin.sh`
5. Use `oc-login.sh` to access the cluster
6. Optionally use other utility scripts as needed

