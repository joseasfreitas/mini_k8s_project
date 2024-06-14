#!/bin/bash

source public-ip-addresses

# Define variables
EJBCACertSecretName="ejbca-tls-secret"

# Apply the EJBCA deployment YAML
kubectl apply -f ejbca-deployment.yaml

# Wait for the EJBCA deployment to be ready
kubectl rollout status deployment/ejbca-ce

# Expose the EJBCA service using a NodePort
if ! kubectl get service ejbca-ce-nodeport; then
  kubectl expose deployment ejbca-ce --type=NodePort --name=ejbca-ce-nodeport --port=8080 --port=8443
fi

# Create the TLS secret for EJBCA if not exists
if ! kubectl get secret $EJBCACertSecretName; then
  kubectl create secret tls $EJBCACertSecretName \
    --cert=certs/test.crt \
    --key=certs/test.key
fi

# Apply the Ingress configuration for EJBCA
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ejbca-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - cert.ejbca.com
    secretName: $EJBCACertSecretName
  rules:
  - host: cert.ejbca.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ejbca-ce
            port:
              number: 8080
  - host: cert.ejbca.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ejbca-ce
            port:
              number: 8443
EOF

# Wait for the Ingress to be created
kubectl get ingress ejbca-ingress

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
