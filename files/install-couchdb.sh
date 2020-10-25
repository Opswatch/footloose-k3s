#!/bin/bash

: ${NODES_NUMBER:="3"}
: ${RELEASE_NAME:="my-couch"}
: ${PVC_SIZE:="100Mi"}
: ${INGRESS_DOMAIN:="localhost.local"}

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

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out ingress-tls.crt \
    -keyout ingress-tls.key \
    -subj "/CN=$INGRESS_DOMAIN/O=ingress-tls-secret"

kubectl create secret tls ingress-tls-secret \
    --key ingress-tls.key \
    --cert ingress-tls.crt

helm repo add couchdb https://apache.github.io/couchdb-helm
helm install  \
  --name $RELEASE_NAME \
  --set couchdbConfig.couchdb.uuid=$(curl https://www.uuidgenerator.net/api/version4 2>/dev/null | tr -d -)   \
  --set persistentVolume.storageClass=manual  \
  --set persistentVolume.enabled=true  \
  --set persistentVolume.size=$PVC_SIZE  \
  --set ingress.enabled=true \
  --set ingress.tls[0].hosts[0]="$INGRESS_DOMAIN"  \
  --set ingress.tls[0].secretName='ingress-tls-secret'  \
  --set ingress.hosts={"$INGRESS_DOMAIN"}  \
  couchdb/couchdb
