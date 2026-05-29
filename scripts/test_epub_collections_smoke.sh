#!/usr/bin/env bash

# Example smoke test script
# Iterates over active EPUB collections
# Sends a summary request
# Verifies that sources are returned

set -u

API="http://127.0.0.1:8010/ask"

echo "### EPUB COLLECTION SMOKE TEST"

jq -r '.collections[] | select(.active == true and (.name|startswith("epub-"))) | .name' collections_registry.json | while read -r C
do
  echo
  echo "### TEST $C"
  RESP=$(curl -s -X POST "$API" \
    -H "Content-Type: application/json" \
    -d "{\"question\":\"Bu kitap ne anlatıyor? Kısa özet çıkar.\",\"collection_name\":\"$C\",\"trace\":false}")

  ANSWER=$(echo "$RESP" | jq -r '.answer // empty')
  SOURCES=$(echo "$RESP" | jq -r '(.sources | length) // 0')

  if [ -z "$ANSWER" ] || [ "$SOURCES" = "0" ]; then
    echo "FAIL sources=$SOURCES"
    echo "$RESP" | head -c 500
    echo
  else
    echo "OK sources=$SOURCES"
    echo "$ANSWER" | head -c 350
    echo
  fi
done
