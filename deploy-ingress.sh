#!/bin/bash

source public-ip-addresses

kubectl create secret generic jwdenta.cloudns.be \
  --from-file=fullchain.pem=../jwdenta.cloudns.be/fullchain.pem \
  --from-file=privkey.pem=../jwdenta.cloudns.be/privkey.pem \
  -n default
# Apply the Ingress resource
#kubectl apply -f ingress-resource.yaml

kubectl apply -f nginx-ingress-controller.yaml

#kubectl get all -n ingress-nginx

echo "Ingress resource creation completed."

