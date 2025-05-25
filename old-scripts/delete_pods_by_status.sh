#!/bin/bash

# 使用法: ./delete_pods_by_status.sh [STATUS]
# 例: ./delete_pods_by_status.sh Error

if [ -z "$1" ]; then
  echo "Usage: $0 <STATUS>"
  echo "Example: $0 Error"
  exit 1
fi

TARGET_STATUS="$1"

echo "Looking for pods with status: $TARGET_STATUS"

oc get pods -A --no-headers | awk -v status="$TARGET_STATUS" '$4 == status {print $1 ":" $2}' | while IFS=: read -r NS POD; do
  echo "Deleting pod: $POD in namespace: $NS"
  oc delete pod "$POD" -n "$NS"
done

