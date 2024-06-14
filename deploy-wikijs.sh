#!/bin/bash

source public-ip-addresses

# Define variables
WikiJSCertSecretName="wikijs-tls-secret"

# Apply the Wiki.js deployment YAML
kubectl apply -f wikijs-deployment.yaml

# Wait for the Wiki.js deployment to be ready
kubectl rollout status deployment/wikijs

# Expose the Wiki.js service using a NodePort
if ! kubectl get service wikijs-nodeport; then
  kubectl expose deployment wikijs --type=NodePort --name=wikijs-nodeport --port=3000
fi

# Create the TLS secret for Wiki.js if not exists
if ! kubectl get secret $WikiJSCertSecretName; then
  kubectl create secret tls $WikiJSCertSecretName \
    --cert=certs/test.crt \
    --key=certs/test.key
fi

# Apply the Ingress configuration for Wiki.js
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wikijs-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - wiki.example.com
    secretName: $WikiJSCertSecretName
  rules:
  - host: wiki.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wikijs
            port:
              number: 80
EOF

# Wait for the Ingress to be created
kubectl get ingress wikijs-ingress

# Expose the Wiki.js service using a NodePort
#kubectl expose deployment wikijs --port 443 --type NodePort

# Retrieve the node port assigned to the wikijs service
#NODE_PORT=$(kubectl get svc wikijs \
#  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

# Wait for the service to be created and get the assigned node port
NODE_PORT=$(kubectl get svc wikijs-nodeport --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
echo "NODE_PORT: ${NODE_PORT}" # Add this line for debugging

echo "Allow remote access to the wikijs node port"
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

echo "Make an HTTP request using the external IP address and the wikijs node port"
curl -I http://"${EXTERNAL_IP}":"${NODE_PORT}"

