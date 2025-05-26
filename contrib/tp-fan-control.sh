#!/bin/bash

FAN_CTRL="/proc/acpi/ibm/fan"

if [[ $EUID -ne 0 ]]; then
  echo "このスクリプトは root 権限で実行してください。"
  exit 1
fi

CONF_FILE="/etc/modprobe.d/thinkpad_acpi.conf"
MODULE="thinkpad_acpi"
OPTION_LINE="options thinkpad_acpi fan_control=1"

# 1. 設定ファイルにオプションが存在するか確認
if ! grep -Fxq "$OPTION_LINE" "$CONF_FILE" 2>/dev/null; then
  echo "✅ Adding fan control option to $CONF_FILE"
  echo "$OPTION_LINE" | sudo tee -a "$CONF_FILE"
else
  echo "✅ Fan control option already set in $CONF_FILE"
fi

# 2. カーネルモジュールがロード済みか確認してリロード
if lsmod | grep -q "^$MODULE"; then
  echo "🔁 Reloading $MODULE with fan_control=1"
  sudo modprobe -r $MODULE
  sudo modprobe $MODULE fan_control=1
else
  echo "ℹ️ $MODULE not loaded yet. It will be loaded with correct option at next boot."
fi

echo "===== ThinkPad Fan Control ====="
echo "1. 自動制御 (auto)"
echo "2. 最大回転 (disengaged)"
echo "3. 手動レベル指定 (0〜7)"
echo ""
current=$(grep '^level:' "$FAN_CTRL" | awk '{print $2}')
echo "💡 現在のファンレベル：$current"
echo ""
read -rp "選択肢を数字で入力してください [1-3]: " choice

case "$choice" in
  1)
    echo "level auto" | sudo tee "$FAN_CTRL" > /dev/null
    echo "✅ ファンを自動制御モードに戻しました。"
    ;;
  2)
    echo "level disengaged" | sudo tee "$FAN_CTRL" > /dev/null
    echo "✅ ファンを最大速度で回転させています（disengaged）。"
    ;;
  3)
    echo "0〜7 の範囲でファンレベルを入力してください。"
    read -rp "レベルを入力（例: 4）: " level
    if [[ "$level" =~ ^[0-7]$ ]]; then
      echo "level $level" | sudo tee "$FAN_CTRL" > /dev/null
      echo "✅ ファンを level $level に設定しました。"
    else
      echo "❌ 入力が無効です。0〜7の数字で入力してください。"
      exit 1
    fi
    ;;
  *)
    echo "❌ 無効な選択です。1〜3を入力してください。"
    exit 1
    ;;
esac

logger "[tp-fan-control] Fan set to level $level by $(whoami)"
