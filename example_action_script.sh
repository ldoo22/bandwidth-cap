#!/bin/bash

# Send an email notification using SendGrid
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
      "value": "You have exceeded your bandwidth limit for this month"
    }
  ]
}'
curl --request POST \
  --url https://api.sendgrid.com/v3/mail/send \
  --header "Authorization: Bearer $SENDGRID_API_KEY" \
  --header 'Content-Type: application/json' \
  --data "$json_data"

# # Stop all network traffic except SSH
# sudo ufw enable
# sudo ufw default deny incoming
# sudo ufw default deny outgoing
# sudo ufw allow 22

# # shutdown the system
# sudo shutdown now
