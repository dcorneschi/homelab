#!/bin/bash

# Script to delete a Kubernetes cluster from ~/.kube/config

set -e

KUBECONFIG_FILE="${KUBECONFIG:-$HOME/.kube/config}"

if [ ! -f "$KUBECONFIG_FILE" ]; then
    echo "Error: kubeconfig file not found at $KUBECONFIG_FILE"
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $0 <cluster-name>"
    echo ""
    echo "Available clusters:"
    kubectl config get-clusters | tail -n +2
    exit 1
fi

CLUSTER_NAME="$1"

# Check if cluster exists
if ! kubectl config get-clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Error: Cluster '$CLUSTER_NAME' not found in kubeconfig"
    echo ""
    echo "Available clusters:"
    kubectl config get-clusters | tail -n +2
    exit 1
fi

# Backup the config file
cp "$KUBECONFIG_FILE" "${KUBECONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo "Backed up kubeconfig to ${KUBECONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Delete the cluster
kubectl config delete-cluster "$CLUSTER_NAME"

# Delete associated context(s) if any
CONTEXTS=$(kubectl config get-contexts -o name | grep "$CLUSTER_NAME" || true)
if [ -n "$CONTEXTS" ]; then
    echo "Deleting associated contexts:"
    echo "$CONTEXTS" | while read -r context; do
        kubectl config delete-context "$context"
        echo "  - $context"
    done
fi

# Delete associated user(s) if any
USERS=$(kubectl config view -o jsonpath="{.users[*].name}" | tr ' ' '\n' | grep "$CLUSTER_NAME" || true)
if [ -n "$USERS" ]; then
    echo "Deleting associated users:"
    echo "$USERS" | while read -r user; do
        kubectl config delete-user "$user"
        echo "  - $user"
    done
fi

echo "Successfully deleted cluster '$CLUSTER_NAME' from kubeconfig"
