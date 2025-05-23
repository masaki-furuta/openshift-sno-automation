#!/bin/bash

# 一時ファイルに非Running/CompletedのPod一覧を取得
TMPFILE=$(mktemp)
oc get pods -A --no-headers | grep -Ev 'Compl|Run' > "$TMPFILE"

# 該当なしチェック
if [ ! -s "$TMPFILE" ]; then
  echo "No pods found with status other than Completed or Running."
  rm -f "$TMPFILE"
  exit 0
fi

# 番号付きで一覧表示
echo "Pods with status other than Completed/Running:"
nl -w2 -s'. ' "$TMPFILE"

# ユーザー選択受付
echo
read -rp "Enter the number(s) of the pod(s) to delete (comma-separated): " SELECTION

# 数値からPod名とNamespaceを抽出して削除
IFS=',' read -ra NUMBERS <<< "$SELECTION"
for num in "${NUMBERS[@]}"; do
  LINE=$(sed -n "${num}p" "$TMPFILE")
  if [ -z "$LINE" ]; then
    echo "Invalid selection: $num"
    continue
  fi
  NS=$(echo "$LINE" | awk '{print $1}')
  POD=$(echo "$LINE" | awk '{print $2}')
  echo "Deleting pod $POD in namespace $NS..."
  oc delete pod "$POD" -n "$NS"
done

# 後片付け
rm -f "$TMPFILE"
