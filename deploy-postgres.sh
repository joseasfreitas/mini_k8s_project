#!/bin/bash

source public-ip-addresses

# Define variables
PostgresCertSecretName="postgres-tls-secret"

# Check if the PostgreSQL service already exists
if ! kubectl get service postgres; then
  # Apply the PostgreSQL deployment YAML
  kubectl apply -f postgres-deployment.yaml

  # Wait for the PostgreSQL deployment to be ready
  kubectl rollout status deployment/postgres
else
  echo "PostgreSQL service already exists"
fi

# Expose the PostgreSQL service using a NodePort
if ! kubectl get service postgres-nodeport; then
  kubectl expose deployment postgres --type=NodePort --name=postgres-nodeport --port=5432
fi

# Create the TLS secret for PostgreSQL if not exists
if ! kubectl get secret $PostgresCertSecretName; then
  kubectl create secret tls $PostgresCertSecretName \
    --cert=certs/test.crt \
    --key=certs/test.key
fi

# Apply the Ingress configuration for PostgreSQL
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: postgres-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - postgres.example.com
    secretName: $PostgresCertSecretName
  rules:
  - host: postgres.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: postgres
            port:
              number: 80
EOF

# Wait for the Ingress to be created
kubectl get ingress postgres-ingress

# Expose the PostgreSQL service using a NodePort
#kubectl expose deployment postgres --port 443 --type NodePort

# Retrieve the node port assigned to the postgres service
#NODE_PORT=$(kubectl get svc postgres \
#  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

#NODE_PORT=$(kubectl get svc postgres-nodeport --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

# Wait for the service to be created and get the assigned node port
NODE_PORT=$(kubectl get svc postgres-nodeport --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
echo "NODE_PORT: ${NODE_PORT}" # Add this line for debugging

echo "Allow remote access to the postgres node port"
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

echo "Make an HTTP request using the external IP address and the postgres node port"
curl -I http://"${EXTERNAL_IP}":"${NODE_PORT}"

