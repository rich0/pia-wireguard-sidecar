#!/bin/sh
# Bypass wg-quick's resolvconf DNS path, which breaks in containers on
# Alpine 3.23+ (openresolv 3.17 signature/init-system checks).
set -e

target=/usr/local/bin/connect_to_wireguard_with_token.sh

if grep -q 'container mode' "$target"; then
  exit 0
fi

awk '
/Trying to set up DNS to \$dnsServer\. In case you do not have resolvconf,/ {
  print "  echo \"Trying to set up DNS to $dnsServer via PostUp (container mode).\""
  skip = 3
  next
}
skip > 0 {
  skip--
  if (skip == 1) {
    print "  echo"
    print "  dnsSettingForVPN=\"PostUp = cp /etc/resolv.conf /etc/resolv.conf.pia-bak 2>/dev/null || true; printf '\''nameserver %s\\n'\'' $dnsServer > /etc/resolv.conf"
    print "PostDown = test -f /etc/resolv.conf.pia-bak && mv -f /etc/resolv.conf.pia-bak /etc/resolv.conf || true\""
  }
  next
}
/dnsSettingForVPN="DNS = \$dnsServer"/ {
  next
}
{ print }
' "$target" > "${target}.tmp"

mv "${target}.tmp" "$target"
chmod +x "$target"