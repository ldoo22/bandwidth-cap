#!/bin/bash

echo 'Sending email notification...'
json_data='{
  "personalizations": [
    {
      "to": [
        {
          "email": "'"$SENDGRID_EMAIL_RECEIVER"'"
        }
      ]
    }
  ],
  "from": {
    "email": "'"$SENDGRID_EMAIL_SENDER"'"
  },
  "subject": "Bandwidth limit exceeded!",
  "content": [
    {
      "type": "text/plain",
      "value": "You have exceeded your bandwidth limit for this month, system will be shut down."
    }
  ]
}'
curl --request POST \
  --url https://api.sendgrid.com/v3/mail/send \
  --header "Authorization: Bearer $SENDGRID_API_KEY" \
  --header 'Content-Type: application/json' \
  --data "$json_data"

echo 'Stopping all Docker containers'
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)

echo 'Blocking all incoming and outgoing traffic...'
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default deny outgoing
sudo ufw allow OpenSSH
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw --force enable

echo "Shutting down the system..."
sudo shutdown now
