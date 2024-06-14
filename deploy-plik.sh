#!/bin/bash

source public-ip-addresses

# Define variables
PlikCertSecretName="plik-tls-secret"

# Apply the Plik deployment YAML
kubectl apply -f plik-deployment.yaml

# Wait for the Plik deployment to be ready
kubectl rollout status deployment/plik

# Expose the Plik service using a NodePort
if ! kubectl get service plik-nodeport; then
  kubectl expose deployment plik --type=NodePort --name=plik-nodeport --port=8080
fi

# Create the TLS secret for Plik if not exists
if ! kubectl get secret $PlikCertSecretName; then
  kubectl create secret tls $PlikCertSecretName \
    --cert=certs/test.crt \
    --key=certs/test.key
fi

# Apply the Ingress configuration for Plik
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: plik-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - plik.example.com
    secretName: $PlikCertSecretName
  rules:
  - host: plik.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: plik
            port:
              number: 80
EOF

# Wait for the Ingress to be created
kubectl get ingress plik-ingress

# Expose the Plik service using a NodePort
#kubectl expose deployment plik --port 443 --type NodePort

# Retrieve the node port assigned to the plik service
#NODE_PORT=$(kubectl get svc plik \
#  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
# Wait for the service to be created and get the assigned node port
NODE_PORT=$(kubectl get svc plik-nodeport --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
echo "NODE_PORT: ${NODE_PORT}" # Add this line for debugging

echo "Allow remote access to the plik node port"
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=kubernetes-the-hard-way" \
  --output text --query 'SecurityGroups[0].GroupId')

aws ec2 authorize-security-group-ingress \
  --group-id "${SECURITY_GROUP_ID}" \
  --protocol tcp \
  --port "${NODE_PORT}" \
  --cidr 0.0.0.0/0

echo "Retrieve the external IP address of a worker instance"
EXTERNAL_IP=${PUBLIC_ADDRESS[worker-0]}
echo "${EXTERNAL_IP}"

echo "Make an HTTP request using the external IP address and the plik node port"
curl -I http://"${EXTERNAL_IP}":"${NODE_PORT}"

