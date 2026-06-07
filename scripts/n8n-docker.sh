docker run -it --rm \
 --name n8n \
 -p 5678:5678 \
 -e GENERIC_TIMEZONE="Asia/Kolkata" \
 -e TZ="Asia/Kolkata" \
 -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
 -e N8N_RUNNERS_ENABLED=true \
 -v n8n_volume:/home/node/.n8n \
 docker.n8n.io/n8nio/n8n