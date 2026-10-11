#!/bin/bash
# Usage: ./scripts/setup.sh [--resign]
# Brings the whole lab up from a clean state and checks it works.
# --resign also regenerates the DNSSEC keys and signed zone.
set -e
cd "$(dirname "$0")/.."

echo "[1/5] Stopping any old lab..."
docker compose down --remove-orphans

echo "[2/5] Building and starting containers..."
docker compose up -d --build

if [ "$1" = "--resign" ]; then
  echo "Re-signing the zone..."
  ./scripts/sign-zone.sh
fi

echo "[3/5] Fixing zone file ownership..."
docker exec server chown -R "$(id -u):$(id -g)" /etc/bind/zones

echo "[4/5] Waiting for DNS to answer..."
OK=0
for i in $(seq 1 30); do
  if docker exec client dig @10.0.2.10 www.lab.test +time=2 +tries=1 +short 2>/dev/null | grep -q "10.0.3.20"; then
    OK=1; break
  fi
  sleep 1
done
if [ "$OK" != 1 ]; then
  echo "FAILED: DNS did not answer in 30 seconds."
  docker compose ps
  exit 1
fi

echo "[5/5] Checking DNSSEC validation and routing..."
if docker exec client dig @10.0.2.10 www.lab.test +dnssec | grep -q "flags:.* ad"; then
  echo "DNSSEC validation OK (ad flag present)."
else
  echo "WARNING: ad flag missing - check the trust anchor."
fi
mkdir -p results
./scripts/test-connectivity.sh
echo "Lab is ready."
