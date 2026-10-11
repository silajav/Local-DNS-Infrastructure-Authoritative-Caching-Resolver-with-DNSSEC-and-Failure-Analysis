#!/bin/bash
# Re-sign the lab.test zone from scratch.
# New keys mean a new DS record, so this also updates the trust anchor
# that Unbound reads, and restarts server + resolver.
set -e
cd "$(dirname "$0")/.."

echo "[1/5] Making sure the server container is running..."
docker compose up -d server

echo "[2/5] Removing old keys and old signed zone..."
docker exec -w /etc/bind/zones server sh -c \
  'rm -f Klab.test.+*.key Klab.test.+*.private dsset-lab.test. db.lab.test.signed'

echo "[3/5] Generating new KSK + ZSK and signing the zone..."
docker exec -w /etc/bind/zones server sh -c '
  dnssec-keygen -a ECDSAP256SHA256 -n ZONE -f KSK lab.test >/dev/null &&
  dnssec-keygen -a ECDSAP256SHA256 -n ZONE lab.test >/dev/null &&
  dnssec-signzone -S -o lab.test -N unixtime -f db.lab.test.signed db.lab.test
'

echo "[4/5] Fixing file ownership..."
docker exec server chown -R "$(id -u):$(id -g)" /etc/bind/zones

echo "[5/5] Updating trust anchor and restarting server + resolver..."
cp bind/zones/dsset-lab.test. bind/zones/trust-anchor.ds
docker compose restart server
docker compose restart resolver

echo "Done. New trust anchor:"
cat bind/zones/trust-anchor.ds
