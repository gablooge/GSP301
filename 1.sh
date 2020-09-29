gcloud auth revoke --all

while [[ -z "$(gcloud config get-value core/account)" ]]; 
do echo "waiting login" && sleep 2; 
done

while [[ -z "$(gcloud config get-value project)" ]]; 
do echo "waiting project" && sleep 2; 
done

export PROJECT_ID=$(gcloud info --format='value(config.project)')
gsutil mb gs://${PROJECT_ID}
gsutil cp resources-install-web.sh gs://${PROJECT_ID}

gcloud compute instances create instance-1 --zone=us-central1-a --tags=http-server --metadata=startup-script-url=gs://$PROJECT_ID/resources-install-web.sh --scopes=https://www.googleapis.com/auth/devstorage.read_only

gcloud compute firewall-rules create default-allow-http --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server

echo "wait until get external IP"

export EXTERNAL_IP=$(gcloud compute instances list --filter="NAME=instance-1" | awk 'BEGIN { cnt=0; } { cnt+=1; if (cnt > 1) print $5; }')
curl http://$EXTERNAL_IP