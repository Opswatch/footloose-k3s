#!/bin/bash

: ${NODES_NUMBER:="3"}
: ${RELEASE_NAME:="my-couch"}
: ${PVC_SIZE:="100Mi"}

rm -rf pv.yaml
for i in `seq 0 $((NODES_NUMBER-1))`;
do
cat <<EOF >> pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: database-storage-$RELEASE_NAME-couchdb-$i
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: $PVC_SIZE
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
---
EOF
done

cat pv.yaml | kubectl apply -f -

helm repo add couchdb https://apache.github.io/couchdb-helm
helm install  \
  --name $RELEASE_NAME \
  --set couchdbConfig.couchdb.uuid=$(curl https://www.uuidgenerator.net/api/version4 2>/dev/null | tr -d -)   \
  --set persistentVolume.storageClass=manual  \
  --set persistentVolume.enabled=true  \
  --set persistentVolume.size=$PVC_SIZE  \
  couchdb/couchdb
