#!/bin/bash

# Deploy PostgreSQL database first
./deploy-postgres.sh

# Deploy EJBCA
./deploy-ejbca.sh

# Deploy Plik
./deploy-plik.sh

# Deploy One-time Secret
./deploy-onetime-secret.sh

# Deploy Wiki.js
./deploy-wikijs.sh

# Deploy NGINX Ingress controller last
./deploy-ingress.sh

