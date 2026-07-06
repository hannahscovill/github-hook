#!/bin/sh
set -e

IPS=$(curl -s https://api.github.com/meta | jq '[.hooks[] | {"ip": .}]')

curl -s -X PUT "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/rules/lists/$CF_LIST_ID/items" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$IPS" | jq '.success'
