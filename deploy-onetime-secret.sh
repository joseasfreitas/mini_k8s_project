#!/bin/bash

source public-ip-addresses

#OnetimeSecretCertSecretName="onetime-secret-tls-secret"

# Apply the One-time Secret deployment YAML
kubectl apply -f onetime-secret-deployment.yaml

# Wait for the One-time Secret deployment to be ready
kubectl rollout status deployment/onetime-secret

# Expose the One-time Secret service using a NodePort
#if ! kubectl get service onetime-secret-nodeport; then
#  kubectl expose deployment onetime-secret --type=NodePort --name=onetime-secret-nodeport --port=7143
#fi

# Expose the One-time Secret service using a NodePort
#kubectl expose deployment onetime-secret --port 443 --type NodePort

# Retrieve the node port assigned to the onetime-secret service
#NODE_PORT=$(kubectl get svc onetime-secret \
#  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

# Wait for the service to be created and get the assigned node port
NODE_PORT=$(kubectl get svc onetime-secret-nodeport --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
echo "NODE_PORT: ${NODE_PORT}" # Add this line for debugging

echo "Allow remote access to the onetime-secret node port"
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

echo "Make an HTTP request using the external IP address and the onetime-secret node port"
curl -I http://"${EXTERNAL_IP}":"${NODE_PORT}"
