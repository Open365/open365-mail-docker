#!/bin/bash

set -e
set -u
set -x

KDECONF="$KDEHOME"/share/config

crudini --set $KDECONF/breezerc Style AnimationsEnabled false
crudini --set $KDECONF/kdeglobals "KDE-Global GUI Settings" GraphicEffectsLevel 0

crudini --set $KDECONF/kmail2rc Reader htmlMail true
crudini --set $KDECONF/kmail2rc MainFolderView ToolTipDisplayPolicy 2
crudini --set $KDECONF/kmail2rc MessageListView MessageToolTipEnabled false
crudini --set $KDECONF/kmail2rc TemplateParser replySameFormat true
