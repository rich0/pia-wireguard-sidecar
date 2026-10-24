#!/bin/sh
# jq -r '.token' prints the string null for a missing token, and busybox
# date rejects GNU date --date='1 day'. Treat null as failure and log the
# PIA error fields. Do not print credentials or a successful token.
set -e

target=/usr/local/bin/get_token.sh

if grep -q 'pia-token-guard' "$target"; then
  exit 0
fi

awk '
/^timeout_timestamp\(\)/ {
  print "@@TIMEOUT@@"
  skip = 1
  next
}
skip && /^}/ {
  skip = 0
  next
}
skip { next }
/^echo -n "Checking login credentials\.\.\."/ {
  print "@@LOGIN@@"
  skiprest = 1
  next
}
skiprest { next }
{ print }
' "$target" > "${target}.spliced"

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    @@TIMEOUT@@)
      cat <<'EOF'
# pia-token-guard: busybox date rejects GNU --date '1 day'.
timeout_timestamp() {
  if exp=$(date -d "@$(($(date +%s) + 86400))" "+%Y-%m-%d %H:%M:%S" 2>/dev/null); then
    printf '%s\n' "$exp"
  else
    printf '%s\n' "expires in 24 hours"
  fi
}
EOF
      ;;
    @@LOGIN@@)
      cat <<'EOF'
echo -n "Checking login credentials..."

# pia-token-guard: jq -r prints the string null when .token is missing.
token_body=$(mktemp) || exit 1
curl_rc=0
http_status=$(curl -s --location --request POST \
  'https://www.privateinternetaccess.com/api/client/v2/token' \
  --form "username=$PIA_USER" \
  --form "password=$PIA_PASS" \
  -o "$token_body" \
  -w '%{http_code}') || curl_rc=$?

token=$(jq -r '.token' "$token_body" 2>/dev/null || true)
if [ -z "$token" ] || [ "$token" = "null" ]; then
  echo
  echo
  echo -e "${red}Could not authenticate with the login credentials provided!${nc}"
  if [ "$curl_rc" -ne 0 ]; then
    echo "curl exit: $curl_rc"
  fi
  echo "HTTP status: ${http_status:-unknown}"
  if jq -e . >/dev/null 2>&1 <"$token_body"; then
    echo "status: $(jq -r '.status // empty' "$token_body")"
    echo "code: $(jq -r '.code // empty' "$token_body")"
    echo "message: $(jq -r '.message // empty' "$token_body")"
  else
    sed -e 's/"token" *: *"[^"]*"/"token":"[redacted]"/g' \
        -e 's/token=[^ &]*/token=[redacted]/g' "$token_body"
  fi
  rm -f "$token_body"
  exit 1
fi
rm -f "$token_body"

echo -e "${green}OK!${nc}"
echo
tokenExpiration=$(timeout_timestamp)
tokenLocation=/opt/piavpn-manual/token
echo "$token" > "$tokenLocation" || exit 1
echo "$tokenExpiration" >> "$tokenLocation"
echo
echo "This token will expire in 24 hours, on $tokenExpiration."
echo
EOF
      ;;
    *)
      printf '%s\n' "$line"
      ;;
  esac
done < "${target}.spliced" > "${target}.tmp"

rm -f "${target}.spliced"
mv "${target}.tmp" "$target"
chmod +x "$target"
grep -q 'pia-token-guard' "$target"
grep -q 'http_status' "$target"
if grep -q -- "--date='1 day'" "$target"; then
  echo "GNU date --date leftover in $target" >&2
  exit 1
fi
