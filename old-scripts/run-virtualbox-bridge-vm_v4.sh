#!/bin/bash
# Fedora42 + VirtualBox + bridge network PoC 最強版 v2c
# 再実行安全・起動中VM保護・console=ttyS0設定・socat自動接続付き

set -e

### --- 設定 ---
VM_NAME="testvm-bridge"
VM_RAM=4096
VM_CPUS=2
VM_DISK_SIZE=20000   # MB
BRIDGE_IF="wlp61s0"
ISO_PATH="/root/Fedora-Server-dvd-x86_64-42-1.1.iso"
VBOX_VDI_PATH="$HOME/VirtualBox VMs/$VM_NAME/$VM_NAME.vdi"
SERIAL_SOCKET="/tmp/$VM_NAME-serial"

### --- 事前チェック ---
echo "✅ kernel-devel チェック"
if ! rpm -q kernel-devel-$(uname -r) > /dev/null 2>&1; then
    echo "⚠️ kernel-devel が $(uname -r) に不足。自動インストールします。"
    sudo dnf install -y kernel-devel-$(uname -r)
else
    echo "✅ kernel-devel $(uname -r) OK"
fi

echo "✅ akmods + vboxdrv check"
sudo akmods --kernels $(uname -r)
sudo systemctl restart vboxdrv.service
lsmod | grep vboxdrv > /dev/null && echo "✅ vboxdrv OK" || (echo "❌ vboxdrv未ロード" && exit 1)

### --- VirtualBox VM作成 or チェック ---
VBoxManage controlvm "$VM_NAME" poweroff || true
VBoxManage unregistervm "$VM_NAME" --delete-all || true
echo "✅ VirtualBox VM作成準備"
if VBoxManage list vms | grep "\"$VM_NAME\"" > /dev/null 2>&1; then
    echo "⚠️ 既にVM $VM_NAME は存在します。createvmはスキップします。"
else
    echo "✅ VM $VM_NAME を新規作成"
    VBoxManage createvm --name "$VM_NAME" --register
fi

### --- 起動中VMチェック ---
if VBoxManage list runningvms | grep "\"$VM_NAME\"" > /dev/null 2>&1; then
    echo "⚠️ $VM_NAME は現在起動中のため設定変更はスキップします。"
else
    echo "✅ $VM_NAME 設定を更新します。"
    VBoxManage modifyvm "$VM_NAME" --memory "$VM_RAM" --cpus "$VM_CPUS" --ioapic on
    VBoxManage modifyvm "$VM_NAME" --nic1 bridged --bridgeadapter1 "$BRIDGE_IF" --nictype1 virtio
    VBoxManage modifyvm "$VM_NAME" --uart1 0x3F8 4 --uartmode1 server "$SERIAL_SOCKET"

    if [ ! -f "$VBOX_VDI_PATH" ]; then
        VBoxManage createmedium disk --filename "$VBOX_VDI_PATH" --size "$VM_DISK_SIZE"
    fi

    VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci || true
    VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd \
        --medium "$VBOX_VDI_PATH" || true
    VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive \
        --medium "$ISO_PATH" || true

    ### --- console=ttyS0 カーネルパラメータ設定 ---
    #VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/pcbios/0/Config/BootArgs" "console=ttyS0,115200n8"
fi

### --- 起動順序設定 (光学ドライブ -> 仮想ディスク) ---
VBoxManage modifyvm "$VM_NAME" --boot1 dvd
VBoxManage modifyvm "$VM_NAME" --boot2 disk
VBoxManage modifyvm "$VM_NAME" --boot3 none
VBoxManage modifyvm "$VM_NAME" --boot4 none

### --- VM起動 + socat接続 ---
echo "✅ VM 起動"
VBoxManage list extpacks
#VBoxManage setproperty vrdeextpack "Oracle VirtualBox Extension Pack"
#VBoxManage modifyvm "$VM_NAME" --vrdeport 3389
VBoxManage setproperty vrdeextpack VNC
VBoxManage modifyvm "$VM_NAME" --vrdeport 5900
VBoxManage modifyvm "$VM_NAME" --vrdeproperty VNCPassword=vnc

VBoxManage modifyvm "$VM_NAME" --vrde on
VBoxManage startvm "$VM_NAME" --type headless || echo "⚠ 起動済みでした"
ss -tlnp
VBoxManage list runningvms


echo "✅ socat確認"
if ! command -v socat >/dev/null 2>&1; then
    echo "⚠️ socat 未検出。自動インストールします。"
    sudo dnf install -y socat
fi

echo "✅ 5秒待機後にシリアルコンソール接続開始"
sleep 5
socat -,raw,echo=0 "$SERIAL_SOCKET"

