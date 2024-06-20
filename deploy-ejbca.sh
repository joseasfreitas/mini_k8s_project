#!/bin/bash

source public-ip-addresses


# Apply the EJBCA deployment YAML
kubectl apply -f ejbca-deployment.yaml

# Wait for the EJBCA deployment to be ready
kubectl rollout status deployment/ejbca


# Expose the EJBCA service using a NodePort
#kubectl expose deployment ejbca-ce --port 443 --type NodePort
# Retrieve the node port assigned to the ejbca-ce service
#NODE_PORT=$(kubectl get svc ejbca-ce \
#  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

# Expose the EJBCA service using a NodePort
NODE_PORT_HTTP=$(kubectl get svc ejbca-ce-nodeport --output=jsonpath='{.spec.ports[0].nodePort}')
NODE_PORT_HTTPS=$(kubectl get svc ejbca-ce-nodeport-https --output=jsonpath='{.spec.ports[0].nodePort}')
echo "NODE_PORT_HTTP: ${NODE_PORT_HTTP}"
echo "NODE_PORT_HTTPS: ${NODE_PORT_HTTPS}"

echo "Allow remote access to the ejbca-ce node port"
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=kubernetes-the-hard-way" \
  --output text --query 'SecurityGroups[0].GroupId')


aws ec2 authorize-security-group-ingress \
  --group-id "${SECURITY_GROUP_ID}" \
  --protocol tcp \
  --port "${NODE_PORT_HTTP}" \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id "${SECURITY_GROUP_ID}" \
  --protocol tcp \
  --port "${NODE_PORT_HTTPS}" \
  --cidr 0.0.0.0/0

echo "Retrieve the external IP address of a worker instance"
EXTERNAL_IP=${PUBLIC_ADDRESS[worker-0]}
echo "${EXTERNAL_IP}"

#echo "Make an HTTP request using the external IP address and the ejbca-ce node port"
#curl -I http://"${EXTERNAL_IP}":"${NODE_PORT}"

echo "Make an HTTP request using the external IP address and the ejbca-ce node port"
curl -I http://"${EXTERNAL_IP}":"${NODE_PORT_HTTP}"
