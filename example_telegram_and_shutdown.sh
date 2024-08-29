#!/bin/bash
    
MESSAGE="Bandwidth Monitor: You have reached the limit. The system will be shut down."
GROUP_ID=<insert_here_your_group_id>
BOT_TOKEN=<insert_here_your_bot_token>

echo "Sending message to Telegram..."
curl -s --data "text=$MESSAGE" --data "chat_id=$GROUP_ID" 'https://api.telegram.org/bot'$BOT_TOKEN'/sendMessage' > /dev/null

echo "Shutting down the system..."
sudo shutdown now
