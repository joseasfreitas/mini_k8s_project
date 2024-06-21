#!/bin/bash

# Apply the One-time Secret deployment YAML
kubectl apply -f onetime-secret-deployment.yaml

# Wait for the One-time Secret deployment to be ready
kubectl rollout status deployment/onetime-secret

