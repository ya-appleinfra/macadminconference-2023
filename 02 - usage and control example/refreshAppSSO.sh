#!/bin/bash

domain="AD.EXAMPLE.COM"
currentUser="$(whoami)"

/usr/bin/app-sso -a "$domain" -u "$currentUser" -Rq
