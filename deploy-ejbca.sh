#!/bin/bash

# Apply the EJBCA deployment YAML
kubectl apply -f ejbca-deployment.yaml

# Wait for the EJBCA deployment to be ready
kubectl rollout status deployment/ejbca

