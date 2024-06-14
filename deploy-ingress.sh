#!/bin/bash

# Define domain names and corresponding secret names
declare -A domains
domains=(
  ["ots.jwdenta.cloudns.be"]="ots-tls-secret"
  ["plik.jwdenta.cloudns.be"]="plik-tls-secret"
  ["ejbca.jwdenta.cloudns.be"]="ejbca-tls-secret"
  ["wikijs.jwdenta.cloudns.be"]="wikijs-tls-secret"
)

# Create Ingress resource
cat <<EOF > ingress-resource.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-domain-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  rules:
EOF

# Loop through each domain and add the rules to the Ingress resource
for domain in "${!domains[@]}"; do
  cat <<EOF >> ingress-resource.yaml
  - host: $domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${domain%%.*}-service # Assumes the service name is derived from the domain prefix
            port:
              number: 80
EOF
done

# Add TLS settings to the Ingress resource
cat <<EOF >> ingress-resource.yaml
  tls:
EOF

for domain in "${!domains[@]}"; do
  secretName=${domains[$domain]}
  cat <<EOF >> ingress-resource.yaml
  - hosts:
    - $domain
    secretName: $secretName
EOF
done

# Apply the Ingress resource
kubectl apply -f ingress-resource.yaml

kubectl apply -f nginx-ingress-controller.yaml

kubectl get all -n ingress-nginx

echo "Ingress resource creation completed."

