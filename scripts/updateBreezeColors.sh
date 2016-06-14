#!/bin/bash

set -e
set -u
set -x

function rp() {
    FROM=$1
    TO=$2
    echo "Replacing $1 for $2";
    find . -type f -exec sed -i -e s/$FROM/$TO/g {} \;
}

cd /home/user
rp '239,240,241' '245,246,249'
rp eff0f1 f5f6f9 

