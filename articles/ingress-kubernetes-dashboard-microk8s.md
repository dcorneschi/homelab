[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dcorneschi)

Simple setup guide for accessing the Kubernetes Dashboard through nginx ingress controller.

## Prerequisites

1. MicroK8s cluster with the following addons enabled:

   - `dashboard`
   - `ingress`

2. Verify the dashboard is running:
   ```bash
   kubectl get pods -n kubernetes-dashboard | grep dashboard
   kubectl get svc -n kubernetes-dashboard | grep dashboard
   ```

## Quick Start

### Deploy ingress for kubernetes-dashboard

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: public
  rules:
  - host: k8s-dashboard.domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kubernetes-dashboard-kong-proxy
            port:
              number: 443
```

```bash
# Deploy basic ingress
kubectl apply -f dashboard-ingress.yaml
```

## Token Management

Use the provided script to get a fresh token:

```bash
#!/bin/bash

# Get Kubernetes Dashboard token for specified user
# Usage: ./get-token.sh [username]
# Example: ./get-token.sh john-doe
# Default: ./get-token.sh (uses dashboard-admin)

USER=${1:-dashboard-admin}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [username]"
    echo ""
    echo "Get a Kubernetes Dashboard access token for the specified user."
    echo ""
    echo "Arguments:"
    echo "  username    Service account name (default: dashboard-admin)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Creates token for dashboard-admin"
    echo "  $0 john-doe          # Creates token for john-doe"
    echo "  $0 readonly-user     # Creates token for readonly-user"
    echo ""
    exit 0
fi

echo "Getting Kubernetes Dashboard token for user: $USER"
echo "=================================="

# Check if service account exists, create if not
if ! kubectl get serviceaccount $USER -n kubernetes-dashboard >/dev/null 2>&1; then
    echo "Creating $USER service account..."
    kubectl create serviceaccount $USER -n kubernetes-dashboard
    kubectl create clusterrolebinding $USER \
        --clusterrole=cluster-admin \
        --serviceaccount=kubernetes-dashboard:$USER
fi

# Get the token
TOKEN=$(kubectl create token $USER -n kubernetes-dashboard)

echo "Your dashboard token for $USER:"
echo "=================================="
echo "$TOKEN"
echo "=================================="
echo ""
echo "Dashboard URL: https://k8s-dashboard.domain.com"
echo ""
echo "Copy the token above and paste it into the dashboard login page."

# Optional: Copy to clipboard (macOS)
if command -v pbcopy >/dev/null 2>&1; then
    echo "$TOKEN" | pbcopy
    echo "✅ Token copied to clipboard!"
fi
```

```bash
# Default user (dashboard-admin)
./get-token.sh

# Custom user
./get-token.sh john-doe
```

This script will:

- Create service account if needed (with specified username)
- Generate a fresh token
- Copy token to clipboard (macOS)
- Display dashboard URL

## Configuration Options

### Custom Domain

Change the hostname in your ingress file:

```yaml
rules:
- host: k8s-dashboard.domain.com  # Change this
```

## DNS Configuration

### Local Development

Add to `/etc/hosts`:

```
192.168.50.200 k8s-dashboard.domain.com
```

### Network DNS

Configure your router/DNS server with A records pointing to your LoadBalancer IP:

```bash
# Get your LoadBalancer IP
kubectl get svc -n ingress ingress
```

## Troubleshooting

### Check Ingress Status

```bash
kubectl get ingress -n kubernetes-dashboard
kubectl describe ingress kubernetes-dashboard -n kubernetes-dashboard
```

### Check Service Endpoints

```bash
kubectl get endpoints kubernetes-dashboard-kong-proxy -n kubernetes-dashboard
```

### View Nginx Logs
```bash
kubectl logs -n ingress -l name=nginx-ingress-microk8s --tail=50
```

### Test Backend Connectivity

```bash
kubectl port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 -n kubernetes-dashboard
curl -k https://localhost:8443 -I
```

### Debug Commands

```bash
# Check all dashboard components
kubectl get all -n kubernetes-dashboard

# Check ingress controller
kubectl get pods -n ingress

# Test DNS resolution
nslookup k8s-dashboard.domain.com

# Test connectivity
curl -I k8s-dashboard.domain.com
```
