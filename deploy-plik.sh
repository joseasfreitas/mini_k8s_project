#!/bin/bash

# Apply the Plik deployment YAML
kubectl apply -f plik-deployment.yaml

# Wait for the Plik deployment to be ready
kubectl rollout status deployment/plik

