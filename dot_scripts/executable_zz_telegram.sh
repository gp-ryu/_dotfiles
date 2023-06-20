#!/bin/bash

apiToken="1799026492:AAGc6kHjB9ZoFXYOBoJ14vhLiSBQ8NSXw70"
userChatId="1822714999"
message=$(echo -e "$1\n\nfrom SCG")


curl -s \
   ¦   ¦ -X POST \
   ¦   ¦ https://api.telegram.org/bot$apiToken/sendMessage \
   ¦   ¦ -d text="$message" \
   ¦   ¦ -d chat_id=$userChatId

