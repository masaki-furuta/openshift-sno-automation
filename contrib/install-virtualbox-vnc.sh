#!/bin/bash

#set -e

WORKDIR_PATH=~/extpack

# RPMFusionの有効化
echo "Enabling RPMFusion repositories..."
sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# VirtualBoxのインストール
echo "Installing VirtualBox..."
sudo dnf install -y VirtualBox

# VirtualBox-vnc パッケージのダウンロードと展開
echo "Downloading and extracting VirtualBox-vnc package..."
mkdir -pv $WORKDIR_PATH/VirtualBox-vnc
cd $WORKDIR_PATH/VirtualBox-vnc
dnf download VirtualBox-vnc

# ダウンロードした .rpm ファイルの解凍
RPM_FILE=$(ls $WORKDIR_PATH/VirtualBox-vnc/*.rpm)
rpm2cpio $RPM_FILE | cpio -imd

# VNC Extension Packのインストール
echo "Installing VirtualBox VNC Extension Pack..."
sudo VBoxManage extpack install $WORKDIR_PATH/VirtualBox-vnc/usr/lib64/virtualbox/ExtensionPacks/VNC/*-extpack

# Oracle VirtualBox Extension Pack のダウンロード
EXTENSION_URL="https://download.virtualbox.org/virtualbox/7.1.8/Oracle_VirtualBox_Extension_Pack-7.1.8.vbox-extpack"
EXT_PACK_PATH="$WORKDIR_PATH/Oracle_VirtualBox_Extension_Pack-7.1.8.vbox-extpack"

echo "Downloading Oracle VirtualBox Extension Pack..."
wget -O $EXT_PACK_PATH $EXTENSION_URL

# ダウンロードした拡張パックをインストール
echo "Installing Oracle VirtualBox Extension Pack..."
sudo VBoxManage extpack install $EXT_PACK_PATH

# libvncserver パッケージをインストール
echo "Installing libvncserver..."
sudo dnf install -y libvncserver

# VBoxRT.so のシンボリックリンク作成
echo "Creating symlink for VBoxRT.so..."
sudo ln -siv /usr/lib64/virtualbox/VBoxRT.so /usr/lib64/virtualbox/ExtensionPacks/VNC/

# シンボリックリンクを更新するために ldconfig を実行
echo "Running ldconfig..."
sudo ldconfig

# インストール確認
echo "Checking the installation and symbolic link..."
VBoxManage list extpacks

# 完了メッセージ
echo "Setup completed successfully!"
echo "Both VirtualBox VNC and Oracle VirtualBox Extension Pack have been successfully installed."
