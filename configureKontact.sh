#!/bin/bash

set -e
set -u
set -x

USER_DOMAIN="$(echo "$EYEOS_MINI_CARD" | json domain)"
export EMAIL="$EYEOS_USER@$USER_DOMAIN"
export SMTP_NAME='Open365 SMTP'
export SMTP_HOST=$EYEOS_SMTP_HOST
export NAME=$EYEOS_PRETTY_NAME
export IMAP_SERVER=$EYEOS_IMAP_HOST
export IMAP_NAME="Open365 Mail"
export IMAP_USERNAME=$EMAIL
EYEOS_MINI_CARD_ESCAPED=`node -e 'console.log(JSON.stringify(process.env.EYEOS_MINI_CARD))'`
export IMAP_PASSWORD="{\"c\":$EYEOS_MINI_CARD_ESCAPED,\"s\":\"$EYEOS_MINI_SIGNATURE\"}"

sed -i "s/%MYSQL_HOST%/$MYSQL_HOST/" "$XDG_CONFIG_HOME"/akonadi/akonadiserverrc
sed -i "s/%MYSQL_USERNAME%/$MYSQL_USERNAME/" "$XDG_CONFIG_HOME"/akonadi/akonadiserverrc
sed -i "s/%MYSQL_PASSWORD%/$MYSQL_PASSWORD/" "$XDG_CONFIG_HOME"/akonadi/akonadiserverrc
sed -i "s/%MYSQL_DATABASE%/$MYSQL_DATABASE/" "$XDG_CONFIG_HOME"/akonadi/akonadiserverrc

sed -i "s/%EMAIL%/$EMAIL/" "$KDEHOME"/share/config/emailidentities
sed -i "s/%NAME%/$NAME/" "$KDEHOME"/share/config/emailidentities

sed -i "s/%EYEOS_USER%/$EMAIL/" "$KDEHOME"/share/config/mailtransports
sed -i "s/%SMTP_NAME%/$SMTP_NAME/" "$KDEHOME"/share/config/mailtransports
sed -i "s/%SMTP_HOST%/$SMTP_HOST/" "$KDEHOME"/share/config/mailtransports

akonadictl start
until qdbus org.freedesktop.Akonadi.Control ; do
	echo "Waiting for Akonadi to start ...."
	sleep 0.2
done

RESOURCE_ID=`qdbus org.freedesktop.Akonadi.Control /AgentManager org.freedesktop.Akonadi.AgentManager.createAgentInstance akonadi_imap_resource`

SERVICE="org.freedesktop.Akonadi.Resource.$RESOURCE_ID"
SERVICERC=`echo $RESOURCE_ID`rc
SERVICE_INT="$SERVICE /Settings"

until qdbus $SERVICE_INT ; do
	echo "Waiting for IMAP Resource to initialize .. "
	sleep 0.2
done

qdbus $SERVICE_INT setAuthentication 7
qdbus $SERVICE_INT setDisconnectedModeEnabled true
qdbus $SERVICE_INT setImapPort 993
qdbus $SERVICE_INT setImapServer $IMAP_SERVER
qdbus $SERVICE_INT setIntervalCheckTime 60
qdbus $SERVICE_INT setSafety "SSL"
qdbus $SERVICE_INT setUseDefaultIdentity true
qdbus $SERVICE_INT setUserName $IMAP_USERNAME

# Save the password in the wallet
KWALLET_INT='org.kde.kwalletd /modules/kwalletd'
APP_NAME="EyeosConfig"
WALLET_ID=`qdbus $KWALLET_INT open "kdewallet" 0 $APP_NAME`
qdbus $KWALLET_INT createFolder $WALLET_ID "imap" $SERVICE
qdbus $KWALLET_INT createFolder $WALLET_ID "mailtransports" "kontact"
qdbus $KWALLET_INT writePassword $WALLET_ID "imap" $SERVICERC $IMAP_PASSWORD $APP_NAME
qdbus $KWALLET_INT writePassword $WALLET_ID "mailtransports" "1634466642" $IMAP_PASSWORD $APP_NAME

qdbus $SERVICE / setName "$IMAP_NAME"
qdbus $SERVICE / reconfigure

# Write details to a file so that we can change the password on login
# The card + signature will eventually expire
echo "$RESOURCE_ID" > "$XDG_CONFIG_HOME"/open365_imap_resource_id
