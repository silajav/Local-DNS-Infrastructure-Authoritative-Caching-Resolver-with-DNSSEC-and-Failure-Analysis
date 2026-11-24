#!/bin/bash
# Usage: ./scripts/hitratio-test.sh <label> [runs=3]
# Per run: flush cache, 21 queries (7 rounds x 3 names), record hits/misses.
cd "$(dirname "$0")/.."
LABEL=${1:?Usage: $0 <label> [runs]}
RUNS=${2:-3}
for run in $(seq 1 "$RUNS"); do
  docker exec resolver unbound-control flush_zone lab.test >/dev/null
  ./scripts/cache-stats.sh reset
  for i in $(seq 1 7); do
    for n in www api ns1; do
      docker exec client dig @10.0.2.10 $n.lab.test +dnssec +short +time=5 +tries=1 >/dev/null
    done
  done
  ./scripts/cache-stats.sh "$LABEL-run$run"
done
