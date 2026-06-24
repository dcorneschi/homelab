[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dcorneschi)

This guide shows how to install NFS storage using the `nfs-subdir-external-provisioner` Helm chart on MicroK8s for dynamic persistent volume provisioning.

### Prerequisites

- MicroK8s cluster running
- NFS server accessible from all nodes
- Administrative access to all nodes
- Network connectivity between nodes and NFS server
- NFS server with properly configured exports

### 1. Install NFS Client on All Nodes

```bash
# Install NFS client utilities
sudo apt-get update
sudo apt-get install nfs-common

# Test NFS connectivity (replace NFS_SERVER_IP)
sudo mkdir -p /mnt/nfs-test
sudo mount -t nfs NFS_SERVER_IP:/volume1/Microk8s /mnt/nfs-test
sudo umount /mnt/nfs-test
sudo rmdir /mnt/nfs-test
```

### 2. Enable Helm3 on MicroK8s

```bash
# Enable Helm3 addon
microk8s enable helm3

# Verify Helm installation
microk8s helm3 version
```

### 3. Install NFS Subdir External Provisioner

#### Add Helm Repository

```bash
# Add the official nfs-subdir-external-provisioner repository
microk8s helm3 repo add nfs-subdir-external-provisioner \
  https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

# Update repository
microk8s helm3 repo update

# Search for available charts
microk8s helm3 search repo nfs-subdir-external-provisioner
```

#### Basic Installation

```bash
microk8s helm3 install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner -n kube-system \
--set nfs.server=192.168.50.9 \
--set nfs.path=/volume1/Microk8s \
--set storageClass.name=nfs-client \
--set storageClass.defaultClass=false \
--set storageClass.reclaimPolicy=Retain

# Wait for deployment to be ready
microk8s kubectl wait --for=condition=available --timeout=300s deployment/nfs-subdir-external-provisioner -n kube-system
```

### 4. Verify Installation

#### Check Deployment Status

```bash
# Check pods
microk8s kubectl get pods -n kube-system | grep nfs-subdir-external-provisioner

# Check deployment
microk8s kubectl get deployment -n kube-system | grep nfs-subdir-external-provisioner

# Check StorageClass
microk8s kubectl get storageclass

# Describe the provisioner deployment
microk8s kubectl describe deployment nfs-subdir-external-provisioner -n kube-system
```

#### Check Logs

```bash
# View provisioner logs
microk8s kubectl logs -n kube-system deployment/nfs-subdir-external-provisioner

# Follow logs in real-time
microk8s kubectl logs -n kube-system deployment/nfs-subdir-external-provisioner -f
```

### 5. Test NFS Storage

#### Create Test PVC and Pod

Create `test-nfs.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-nfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-client
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: test-nfs-pod
spec:
  containers:
  - name: test-container
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
    volumeMounts:
    - name: nfs-storage
      mountPath: /data
  volumes:
  - name: nfs-storage
    persistentVolumeClaim:
      claimName: test-nfs-pvc
```

#### Deploy and Test

```bash
# Apply test resources
microk8s kubectl apply -f test-nfs.yaml

# Check pod status
microk8s kubectl get pod test-nfs-pod

# Test writing to NFS
microk8s kubectl exec test-nfs-pod -- sh -c 'echo "Hello from NFS!" > /data/test.txt'

# Verify file on NFS server
ls -la /volume1/Microk8s/

# Read file from pod
microk8s kubectl exec test-nfs-pod -- cat /data/test.txt

# Clean up test resources
microk8s kubectl delete -f test-nfs.yaml
```

### 6. Set as Default StorageClass (Optional)

```bash
# Change microk8s-hostpath to false
kubectl patch storageclass microk8s-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

# Make nfs-client the default StorageClass
microk8s kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Verify default StorageClass
microk8s kubectl get storageclass
```

### 7. Troubleshooting

#### PVC Stuck in Pending

```bash
# Check provisioner logs
microk8s kubectl logs -n kube-system deployment/nfs-subdir-external-provisioner

# Check events
microk8s kubectl describe pvc YOUR_PVC_NAME

# Verify StorageClass exists
microk8s kubectl get storageclass nfs-client
```

#### Access Denied Errors

```bash
# Test NFS connectivity from nodes
showmount -e 192.168.50.9

# Check NFS export configuration
sudo exportfs -v
```

#### Permission Denied Issues

```bash
# Ensure NFS export uses no_root_squash
sudo exportfs -v | grep no_root_squash

# Check directory permissions on NFS server
ls -la /volume1/Microk8s/

# Fix permissions if needed
sudo chown nobody:nogroup /volume1/Microk8s
sudo chmod 0777 /volume1/Microk8s
```

#### Mount Failures

```bash
# Check NFS client installation on all nodes
dpkg -l | grep nfs-common

# Test NFS connectivity
ping 192.168.50.9
nmap -p 111,2049 192.168.50.9

# Check RPC services
rpcinfo -p 192.168.50.9
```

#### Pod ImagePullBackOff

```bash
# Check internet connectivity from nodes
microk8s kubectl describe pod -n kube-system POD_NAME

# Check if image repository is accessible
microk8s kubectl get events -n kube-system
```

#### Diagnostic Commands

```bash
# Check all NFS-related resources
microk8s kubectl get all -n kube-system | grep nfs

# Check StorageClass configuration
microk8s kubectl describe storageclass nfs-client

# List all PVs created by the provisioner
microk8s kubectl get pv | grep nfs-client
```

### 8. Management Commands

```bash
# List all Helm releases
microk8s helm3 list -A

# Get current values
microk8s helm3 get values nfs-subdir-external-provisioner -n kube-system

# Upgrade the provisioner
microk8s helm3 upgrade nfs-subdir-external-provisioner \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace kube-system \
  --reuse-values

# Upgrade with new values
microk8s helm3 upgrade nfs-subdir-external-provisioner \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace kube-system \
  --values nfs-values.yaml

# Uninstall the provisioner
microk8s helm3 uninstall nfs-subdir-external-provisioner --namespace kube-system

# Check PV reclaim policy
microk8s kubectl get pv -o custom-columns=NAME:.metadata.name,RECLAIM:.spec.persistentVolumeReclaimPolicy,STATUS:.status.phase

# Force delete stuck PVC (use with caution)
microk8s kubectl patch pvc PVC_NAME -p '{"metadata":{"finalizers":null}}'
```

### Links

* [https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)
