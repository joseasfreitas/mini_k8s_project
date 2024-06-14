#!/bin/bash

# Define domain names and corresponding secret names
declare -A domains
domains=(
  ["ots.jwdenta.cloudns.be"]="ots-tls-secret"
  ["plik.jwdenta.cloudns.be"]="plik-tls-secret"
  ["ejbca.jwdenta.cloudns.be"]="ejbca-tls-secret"
  ["wikijs.jwdenta.cloudns.be"]="wikijs-tls-secret"
)

# Directory where certificate and key files are stored
CERT_DIR="certs/"

# Loop through each domain and create the TLS secret
for domain in "${!domains[@]}"; do
  secretName=${domains[$domain]}
  
  echo "Creating TLS secret for domain: $domain with secret name: $secretName"

  kubectl create secret tls $secretName \
    --cert="${CERT_DIR}/${domain}.crt" \
    --key="${CERT_DIR}/${domain}.key"
done

echo "TLS secrets creation completed."

