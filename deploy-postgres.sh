#!/bin/bash

# Apply the PostgreSQL deployment YAML
kubectl apply -f postgres-deployment.yaml

# Wait for the PostgreSQL deployment to be ready
kubectl rollout status deployment/postgres
