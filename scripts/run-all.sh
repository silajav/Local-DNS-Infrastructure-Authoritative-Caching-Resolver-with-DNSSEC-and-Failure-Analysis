#!/bin/bash
# Usage: ./scripts/run-all.sh --yes     (takes about 15 minutes)
# DELETES old CSV/PCAP results first.
set -e
cd "$(dirname "$0")/.."
[ "$1" = "--yes" ] || { echo "This deletes old results in results/. Re-run with --yes to confirm."; exit 1; }

./scripts/impair.sh clear
rm -f results/cache-*.csv results/qps.csv results/failure-*.csv results/*.pcap

echo "== Resolution time + cache hit ratio, 4 conditions =="
./scripts/cache-test.sh baseline 3
./scripts/hitratio-test.sh baseline 3

./scripts/impair.sh delay 100ms
./scripts/cache-test.sh delay100 3
./scripts/hitratio-test.sh delay100 3
./scripts/impair.sh clear

./scripts/impair.sh loss 5%
./scripts/cache-test.sh loss5 10
./scripts/hitratio-test.sh loss5 3
./scripts/impair.sh clear

./scripts/impair.sh rate 64kbit
./scripts/cache-test.sh bw64k 3
./scripts/impair.sh clear

echo "== QPS, 3 conditions =="
./scripts/load-test.sh normal 3 10
./scripts/impair.sh delay 100ms client
./scripts/load-test.sh delay100 3 10
./scripts/impair.sh clear
./scripts/impair.sh loss 5% client
./scripts/load-test.sh loss5 3 10
./scripts/impair.sh clear

echo "== Failure and recovery: outages of 5, 15 and 30 s =="
for d in 5 15 30; do
  for r in 1 2 3; do ./scripts/failure-test.sh "o${d}-${r}" "$d"; done
done

echo "== Packet captures =="
docker exec resolver unbound-control flush_zone lab.test >/dev/null
./scripts/capture.sh start resolver cold-lookup port 53
docker exec client dig @10.0.2.10 www.lab.test >/dev/null
sleep 1
./scripts/capture.sh stop resolver cold-lookup

./scripts/capture.sh start resolver warm-lookup port 53
docker exec client dig @10.0.2.10 www.lab.test >/dev/null
sleep 1
./scripts/capture.sh stop resolver warm-lookup

docker exec resolver unbound-control flush_zone lab.test >/dev/null
./scripts/capture.sh start resolver dnssec port 53
docker exec client dig @10.0.2.10 www.lab.test +dnssec >/dev/null
sleep 1
./scripts/capture.sh stop resolver dnssec

docker exec resolver unbound-control flush_zone lab.test >/dev/null
./scripts/capture.sh start resolver dns-tcp port 53
docker exec client dig @10.0.2.10 www.lab.test +tcp >/dev/null
sleep 1
./scripts/capture.sh stop resolver dns-tcp

./scripts/capture.sh start client icmp-routing icmp
docker exec client ping -c 3 10.0.3.10 >/dev/null
docker exec client traceroute -n 10.0.3.10 >/dev/null
./scripts/capture.sh stop client icmp-routing

./scripts/capture.sh start resolver outage port 53
./scripts/failure-test.sh capture 15
./scripts/capture.sh stop resolver outage

./scripts/impair.sh clear
echo "All experiments finished. Run: python3 scripts/analyze.py"
