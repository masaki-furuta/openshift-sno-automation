#!/bin/bash

# 実行時チェック
if [[ "$0" == "$BASH_SOURCE" ]]; then
  echo "🚀 このスクリプトは直接実行されます。ログイン後、KUBECONFIG を維持した新しいシェルに入ります。"
else
  echo "⚠ このスクリプトは source せず直接実行してください:"
  echo "    ./oc-login_v3.sh"
  return 1
fi

MODE="$1"

# 場所を更新
sudo updatedb
# パスワードファイル候補を取得（テンプレやGoソースを除外）
PWLST=$(locate kubeadmin-password 2>/dev/null | grep -v '\.bak' | while read -r f; do
  [[ -f "$f" ]] || continue
  head -n 1 "$f" | grep -Eq '^[a-zA-Z0-9\-]{10,}$' && echo "$f"
done)

if [ -z "$PWLST" ]; then
  echo "❌ 有効な kubeadmin-password ファイルが見つかりません。"
  exit 1
fi

IFS=$'\n' read -rd '' -a FILES <<< "$PWLST"

# 🔁 自動モード: 上から順に試す
if [[ "$MODE" == "auto" ]]; then
  echo "🔄 自動ログインモードを開始します..."
  for FILE in "${FILES[@]}"; do
    DIR=$(dirname "$FILE")
    KUBECONFIG_PATH="$DIR/kubeconfig"
    [[ -f "$KUBECONFIG_PATH" ]] || continue

    PASSWORD=$(< "$FILE")
    [[ "$PASSWORD" =~ ^[a-zA-Z0-9\-]{10,}$ ]] || continue

    export KUBECONFIG="$KUBECONFIG_PATH"
    API_URL=$(grep -Eom1 'https://api\.[^ ]+' "$KUBECONFIG_PATH")
    API_URL=${API_URL:-"https://api.sno-cluster.local:6443"}

    echo "👉 試行中: $KUBECONFIG_PATH"
    oc login -u kubeadmin -p "$PASSWORD" "$API_URL" --insecure-skip-tls-verify
    if [ $? -eq 0 ]; then
      echo "✅ ログイン成功: $KUBECONFIG_PATH"
      exec bash --rcfile <(echo "export KUBECONFIG=$KUBECONFIG; exec bash")
      exit 0
    else
      echo "❌ ログイン失敗: $KUBECONFIG_PATH"
    fi
  done

  echo "🚫 全候補でログインに失敗しましたが、KUBECONFIG を維持したシェルに入ります。"
  exec bash --rcfile <(echo "export KUBECONFIG=$KUBECONFIG; exec bash")
fi

# 🎛 対話モード
echo "🔐 利用可能な kubeadmin-password ファイル:"
for i in "${!FILES[@]}"; do
  printf " %2d. %s\n" "$((i+1))" "${FILES[$i]}"
done

echo
read -rp "番号を選んでください: " SEL
if ! [[ "$SEL" =~ ^[0-9]+$ ]] || (( SEL < 1 || SEL > ${#FILES[@]} )); then
  echo "❌ 無効な番号です。"
  exit 1
fi

FILE="${FILES[$((SEL-1))]}"
DIR=$(dirname "$FILE")
KUBECONFIG_PATH="$DIR/kubeconfig"

if [ ! -f "$KUBECONFIG_PATH" ]; then
  echo "❌ kubeconfig が見つかりません: $KUBECONFIG_PATH"
  exit 1
fi

PASSWORD=$(< "$FILE")
if ! [[ "$PASSWORD" =~ ^[a-zA-Z0-9\-]{10,}$ ]]; then
  echo "❌ パスワード形式が不正です。"
  exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"
API_URL=$(grep -Eom1 'https://api\.[^ ]+' "$KUBECONFIG_PATH")
API_URL=${API_URL:-"https://api.sno-cluster.local:6443"}

echo "👉 oc login を実行中..."
oc login -u kubeadmin -p "$PASSWORD" "$API_URL" --insecure-skip-tls-verify
if [ $? -ne 0 ]; then
  echo "❌ oc login に失敗しました。"
  exit 1
fi

echo "✅ ログイン成功！KUBECONFIG を保持した新しいシェルを起動します。"
echo "👉 'exit' で戻るまで、oc コマンドが使用可能です。"
exec bash --rcfile <(echo "export KUBECONFIG=$KUBECONFIG; exec bash")

