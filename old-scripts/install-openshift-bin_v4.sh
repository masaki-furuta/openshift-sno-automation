#!/bin/bash
set -euo pipefail

# インストール先ディレクトリ
BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"

echo
echo "🔧 OpenShift CLI ツールのインストール先: $BIN_DIR"
echo "--------------------------------------------------"

#
# Butane
#
echo
echo "📥 Butane をダウンロード中..."
curl -fsSL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/butane/latest/butane \
  -o "${BIN_DIR}/butane"
chmod +x "${BIN_DIR}/butane"

# PATH に追加済みなら hash -r で反映（不要な場合もあるが念のため）
hash -r

# Webアクセスが発生する場合があるため --version 出力は抑制
echo -n "🔎 butane バージョン: "
"${BIN_DIR}/butane" --version 2>/dev/null || true
echo "✅ Butane のインストール完了"

#
# openshift-install
#
echo
echo "📥 openshift-install をダウンロード中..."
curl -fsSL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux.tar.gz \
  | tar -xz -C "$BIN_DIR" openshift-install
chmod +x "${BIN_DIR}/openshift-install"
hash -r
echo -n "🔎 openshift-install バージョン: "
openshift-install version 2>/dev/null | perl -pe 's/\n/, /g' || true
echo
echo "✅ openshift-install のインストール完了"

#
# oc および kubectl
#
echo
echo "📥 oc / kubectl をダウンロード中..."
curl -fsSL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz \
  | tar -xz -C "$BIN_DIR" oc kubectl
chmod +x "${BIN_DIR}/oc" "${BIN_DIR}/kubectl"
hash -r

echo -n "🔎 oc バージョン: "
"${BIN_DIR}/oc" version 2>/dev/null | perl -pe 's/\n/, /g' || true
echo
echo -n "🔎 kubectl バージョン: "
"${BIN_DIR}/kubectl" version 2>/dev/null | perl -pe 's/\n/, /g' || true
echo
echo "✅ oc / kubectl のインストール完了"

echo
echo "🎉 OpenShift CLI ツールのインストールがすべて完了しました！"
echo "--------------------------------------------------"
echo

# 補足:
# 各コマンドは --version でも外部に接続することがあるため、出力を抑制しています（2>/dev/null）。
# bin ディレクトリが PATH に通っていない場合は以下を追加してください:
#   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
#   source ~/.bashrc

