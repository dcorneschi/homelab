[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dcorneschi)

### Overview

This guide walks you through setting up an ingress service with MetalLB load balancer on a MicroK8s cluster. MetalLB provides a network load balancer implementation for Kubernetes clusters that don't run on cloud providers, making it perfect for bare-metal or virtualized environments like Proxmox.

### Prerequisites

- MicroK8s cluster running (version 1.34/stable)
- MetalLB addon enabled on MicroK8s
- Ingress addon enabled on MicroK8s
- Available IP address pool for MetalLB
- kubectl configured to access your cluster

### Architecture Overview

```
Internet/Network
       ↓
   MetalLB LoadBalancer (192.168.50.200-210)
       ↓
   Ingress Controller (NGINX)
       ↓
   Kubernetes Services
       ↓
   Application Pods
```

### Step 1: Enable Required MicroK8s Addons

First, ensure the necessary addons are enabled on your MicroK8s cluster:

```bash
# SSH to your control plane node
ssh ubuntu@192.168.50.100

# Enable ingress and MetalLB addons
microk8s enable ingress
microk8s enable metallb:192.168.50.200-192.168.50.210

# Verify addons are enabled
microk8s status
```

### Step 2: Configure MetalLB IP Address Pool

MetalLB needs an IP address pool to assign external IPs to LoadBalancer services. Since we enabled MetalLB with the IP range parameter in Step 1, the IP address pool is automatically configured and **no additional YAML configuration is required**.

You can verify the automatically created configuration:

```bash
# Check current MetalLB configuration
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system

# View the automatically created IP pool
kubectl get ipaddresspool -n metallb-system -o yaml

# Edit the IP pool
kubectl edit ipaddresspool -n metallb-system
```

### Step 3: Create LoadBalancer Service for Ingress

Create a LoadBalancer service that exposes the ingress controller externally:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: test-service
  annotations:
    metallb.universe.tf/address-pool: custom-addresspool
spec:
  selector:
    name: nginx
  type: LoadBalancer
  # loadBalancerIP is optional. MetalLB will automatically allocate an IP 
  # from its pool if not specified. You can also specify one manually.
  # loadBalancerIP: x.y.z.a
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

Apply the service configuration:

```bash
kubectl apply -f ingress-service.yaml
```

### Step 4: Verify MetalLB and Ingress Setup

Check that MetalLB has assigned an external IP to your ingress service:

```bash
# Check the ingress service
kubectl get svc -n ingress

# Verify MetalLB pods are running
kubectl get pods -n metallb-system

# Check ingress controller pods
kubectl get pods -n ingress
```

### Step 5: Deploy Portainer as Sample Application

```bash
# Add the Portainer Helm repository
helm repo add portainer https://portainer.github.io/k8s/
helm repo update
kubectl create namespace portainer
helm install portainer portainer/portainer --set service.type=ClusterIP --create-namespace -n portainer
kubectl get all -n portainer
```

### Step 6: Create Ingress Resource

Create an ingress resource to route traffic to your application:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: portainer-ingress
  namespace: portainer
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  rules:
  - host: portainer.domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: portainer
            port:
              number: 9000
```

Apply the ingress resource:

```bash
kubectl apply -f portainer-ingress-service.yaml
```

### Step 7: Add entries to /etc/hosts or DNS

```bash
# Add entries to your local machine's /etc/hosts file
echo "192.168.50.200 portainer.domain.com" | sudo tee -a /etc/hosts
```

### Step 8: Test the Configuration

```bash
# Get the external IP of the ingress service
INGRESS_IP=$(kubectl get svc ingress -n ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress IP: $INGRESS_IP"

# Test with curl
curl -H "Host: portainer.domain.com" http://$INGRESS_IP
```

## Troubleshooting

```bash
# Check MetalLB logs
kubectl logs -n metallb-system -l app=metallb
   
# Verify IP pool configuration
kubectl get ipaddresspool -n metallb-system -o yaml
   
# Check L2Advertisement
kubectl get l2advertisement -n metallb-system -o yaml

# Check ingress controller pods
kubectl get pods -n ingress
   
# Check ingress controller logs
kubectl logs -n ingress -l name=nginx-ingress-microk8s
   
# Verify ingress class
kubectl get ingressclass

# Check service endpoints
kubectl get endpoints portainer -n portainer

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check all ingress resources
kubectl get ingress -A

# Describe ingress for detailed information
kubectl describe ingress portainer -n portainer

# Monitor ingress controller logs in real-time
kubectl logs -n ingress -l name=nginx-ingress-microk8s -f

# Check MetalLB speaker logs
kubectl logs -n metallb-system -l component=speaker -f

# Test port forwarding as alternative
kubectl port-forward -n portainer svc/portainer 9443:9443
```

### Links 

* [https://canonical.com/microk8s/docs/addon-metallb](https://canonical.com/microk8s/docs/addon-metallb)
* [https://www.portainer.io](https://www.portainer.io)
