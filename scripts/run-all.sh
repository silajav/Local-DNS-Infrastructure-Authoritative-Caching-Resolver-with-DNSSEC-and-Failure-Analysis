#!/bin/bash
# Usage: ./scripts/run-all.sh --yes
# Runs every experiment and capture. DELETES old CSV and PCAP results first.
set -e
cd "$(dirname "$0")/.."
[ "$1" = "--yes" ] || { echo "This deletes old results in results/. Re-run with --yes to confirm."; exit 1; }

./scripts/impair.sh clear
rm -f results/cache-*.csv results/qps.csv results/failure-*.csv results/*.pcap

echo "== E1 baseline =="
./scripts/cache-test.sh baseline 3
for run in 1 2 3; do
  docker exec resolver unbound-control flush_zone lab.test >/dev/null
  ./scripts/cache-stats.sh reset
  for i in $(seq 1 7); do
    for n in www api ns1; do
      docker exec client dig @10.0.2.10 $n.lab.test +dnssec +short >/dev/null
    done
  done
  ./scripts/cache-stats.sh baseline-run$run
done

echo "== E2 delay =="
./scripts/impair.sh delay 100ms
./scripts/cache-test.sh delay100 3
./scripts/impair.sh clear

echo "== E3 loss =="
./scripts/impair.sh loss 5%
./scripts/cache-test.sh loss5 10
./scripts/impair.sh clear

echo "== E4 bandwidth =="
./scripts/impair.sh rate 64kbit
./scripts/cache-test.sh bw64k 3
./scripts/impair.sh clear

echo "== E5-E7 QPS =="
./scripts/load-test.sh normal 3 10
./scripts/impair.sh delay 100ms client
./scripts/load-test.sh delay100 3 10
./scripts/impair.sh clear
./scripts/impair.sh loss 5% client
./scripts/load-test.sh loss5 3 10
./scripts/impair.sh clear

echo "== E8 failure and recovery =="
for run in 1 2 3; do ./scripts/failure-test.sh $run; done

echo "== Packet captures =="
docker exec resolver unbound-control flush_zone lab.test >/dev/null
./scripts/capture.sh start resolver cold-lookup port 53
docker exec client dig @10.0.2.10 www.lab.test >/dev/null
./scripts/capture.sh stop resolver cold-lookup
./scripts/capture.sh start resolver warm-lookup port 53
docker exec client dig @10.0.2.10 www.lab.test >/dev/null
./scripts/capture.sh stop resolver warm-lookup
docker exec resolver unbound-control flush_zone lab.test >/dev/null
./scripts/capture.sh start resolver dnssec port 53
docker exec client dig @10.0.2.10 www.lab.test +dnssec >/dev/null
./scripts/capture.sh stop resolver dnssec
./scripts/capture.sh start resolver outage port 53
./scripts/failure-test.sh 4
./scripts/capture.sh stop resolver outage

./scripts/impair.sh clear
echo "All experiments finished. Run: python3 scripts/analyze.py"
