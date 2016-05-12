#!/bin/bash

set -e
set -u
set -x

EYEOS_MINI_CARD_ESCAPED=`node -e 'console.log(JSON.stringify(process.env.EYEOS_MINI_CARD))'`
export IMAP_PASSWORD="{\"c\":$EYEOS_MINI_CARD_ESCAPED,\"s\":\"$EYEOS_MINI_SIGNATURE\"}"

RESOURCE_ID=`cat "$XDG_CONFIG_HOME"/open365_imap_resource_id`
SERVICERC=`echo $RESOURCE_ID`rc

APP_NAME="EyeosConfig"
KWALLET_INT='org.kde.kwalletd /modules/kwalletd'
WALLET_ID=`qdbus $KWALLET_INT open "kdewallet" 0 $APP_NAME`

qdbus $KWALLET_INT writePassword $WALLET_ID "imap" $SERVICERC $IMAP_PASSWORD $APP_NAME
qdbus $KWALLET_INT writePassword $WALLET_ID "mailtransports" "1634466642" $IMAP_PASSWORD $APP_NAME

# Update SMTP and IMAP email
# This is because the username used to be without the domain but that has now changed
USER_DOMAIN="$(echo "$EYEOS_MINI_CARD" | json domain)"
export EMAIL="$EYEOS_USER@$USER_DOMAIN"

if [[ -f "$KDEHOME"/share/config/mailtransports ]]; then
    sed -i "s#user=.*#user=$EMAIL#" "$KDEHOME"/share/config/mailtransports
fi

if [[ -f "$KDEHOME"/share/config/${RESOURCE_ID}rc ]]; then
    sed -i "s#UserName=.*#UserName=$EMAIL#" "$KDEHOME"/share/config/${RESOURCE_ID}rc
fi
