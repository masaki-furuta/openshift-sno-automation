#!/bin/bash -xv

for NS_POD in $(oc get pods -A | grep CrashLoopBackOff | awk '{print $1 ":" $2}'); do
  NS=${NS_POD%%:*}
  POD=${NS_POD##*:}
  echo "Restarting pod: $POD in namespace: $NS"
  oc describe pod "$POD" -n "$NS"
  oc delete pod "$POD" -n "$NS"
done

