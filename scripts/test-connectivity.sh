#!/bin/bash
OUT=results/connectivity.txt
: > $OUT
for c in client router1 router2 resolver server; do
  echo "=== $c: ip route ===" >> $OUT
  docker exec $c ip route >> $OUT
done
echo "=== client -> server ping ===" >> $OUT
docker exec client ping -c 3 10.0.3.10 >> $OUT
echo "=== client -> server traceroute ===" >> $OUT
docker exec client traceroute -n 10.0.3.10 >> $OUT
echo "Saved to $OUT"
