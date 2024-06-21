#!/bin/bash

# Apply the Wiki.js deployment YAML
kubectl apply -f wikijs-deployment.yaml

# Wait for the Wiki.js deployment to be ready
kubectl rollout status deployment/wikijs

