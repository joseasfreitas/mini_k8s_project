#!/bin/bash

source public-ip-addresses

# Apply the NGINX Ingress controller YAML
kubectl apply -f nginx-ingress-controller.yaml

# Wait for the Ingress controller deployment to be ready
kubectl rollout status deployment/nginx-ingress-controller -n ingress-nginx

# Configure Ingress Resources
kubectl apply -f ingress.yaml

# Expose the NGINX Ingress service using a NodePort
NODE_PORT=$(kubectl get svc nginx-ingress -n ingress-nginx \
  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

echo "Allow remote access to the node port"
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

echo "Make an HTTP request using the external IP address and the nginx node port"
curl -I http://"${EXTERNAL_IP}":"${NODE_PORT}"

