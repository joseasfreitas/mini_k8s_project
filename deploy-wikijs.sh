#!/bin/bash

source public-ip-addresses

# Apply the Wiki.js deployment YAML
kubectl apply -f wikijs-deployment.yaml

# Wait for the Wiki.js deployment to be ready
kubectl rollout status deployment/wikijs


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

