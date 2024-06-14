#!/bin/bash

# Define domain names and corresponding secret names
declare -A domains
domains=(
  ["ots.jwdenta.cloudns.be"]="ots-tls-secret"
  ["plik.jwdenta.cloudns.be"]="plik-tls-secret"
  ["ejbca.jwdenta.cloudns.be"]="ejbca-tls-secret"
  ["wikijs.jwdenta.cloudns.be"]="wikijs-tls-secret"
)

# Loop through each domain and delete the TLS secret
for domain in "${!domains[@]}"; do
  secretName=${domains[$domain]}
  
  echo "Deleting TLS secret for domain: $domain with secret name: $secretName"

  kubectl delete secret $secretName
done

echo "TLS secrets deletion completed."

