#!/bin/bash
# Create GCE VM for INECOBANK Superset
# Run from your local machine (with gcloud CLI installed)

set -e

# Configuration - edit these
PROJECT_ID="${GCP_PROJECT:-ineco-analytics}"
ZONE="${GCP_ZONE:-us-central1-a}"
VM_NAME="${VM_NAME:-superset-vm}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-standard-2}"  # Good for start; upgrade to e2-standard-4 if needed

echo "=== Creating GCE VM for INECOBANK Superset ==="
echo "Project: $PROJECT_ID"
echo "Zone: $ZONE"
echo "VM: $VM_NAME"
echo ""

# Set project
gcloud config set project "$PROJECT_ID"

# Enable APIs
echo "Enabling APIs..."
gcloud services enable compute.googleapis.com --quiet

# Create firewall rule
echo "Creating firewall rule..."
gcloud compute firewall-rules create superset-allow-http \
  --allow tcp:8088 \
  --source-ranges 0.0.0.0/0 \
  --target-tags superset \
  2>/dev/null || echo "Firewall rule may already exist"

# Create VM
echo "Creating VM..."
gcloud compute instances create "$VM_NAME" \
  --zone="$ZONE" \
  --machine-type="$MACHINE_TYPE" \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=50GB \
  --tags=superset

echo ""
echo "=== VM created successfully ==="
echo ""
echo "Next steps:"
echo "1. SSH to VM:  gcloud compute ssh $VM_NAME --zone=$ZONE"
echo "2. On VM, run:"
echo "   sudo apt-get update && sudo apt-get install -y git"
echo "   sudo curl -fsSL https://get.docker.com | sh"
echo "   sudo usermod -aG docker \$USER"
echo "   (logout and login again for docker group)"
echo "   git clone https://github.com/harutdram/Ineco-Analytics.git"
echo "   cd Ineco-Analytics"
echo "   bash deploy/setup-vm.sh"
echo ""
echo "3. Get VM IP:"
gcloud compute instances describe "$VM_NAME" --zone="$ZONE" \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null || true
echo ""
echo "4. Add BigQuery credentials to credentials/ folder"
echo "5. Access Superset at http://<VM_IP>:8088"
echo ""
