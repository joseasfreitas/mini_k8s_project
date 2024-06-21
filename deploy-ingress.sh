#!/bin/bash

kubectl create secret generic jwdenta.cloudns.be \
  --from-file=fullchain.pem=../jwdenta.cloudns.be/fullchain.pem \
  --from-file=privkey.pem=../jwdenta.cloudns.be/privkey.pem \
  -n default

kubectl apply -f nginx-ingress-controller.yaml

# Wait for the NGINX deployment to be ready
kubectl rollout status deployment/nginx-proxy
