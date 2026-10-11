#!/bin/bash
# Usage: ./scripts/load-test.sh <label> [runs=3] [seconds=10]
# Warms the resolver cache first, then runs dnsperf.
# Output: appends to results/qps.csv
cd "$(dirname "$0")/.."
LABEL=${1:?Usage: $0 <label> [runs] [seconds]}
RUNS=${2:-3}
SECS=${3:-10}
OUT=results/qps.csv
mkdir -p results
[ -f "$OUT" ] || echo "label,run,qps,sent,completed,lost_percent" > "$OUT"
docker cp scripts/queries.txt client:/tmp/queries.txt
for r in $(seq 1 "$RUNS"); do
  for n in www.lab.test api.lab.test ns1.lab.test; do
    docker exec client dig @10.0.2.10 $n +time=5 +tries=1 +short >/dev/null
  done
  R=$(docker exec client dnsperf -s 10.0.2.10 -d /tmp/queries.txt -l "$SECS" -c 5 -t 2 2>&1)
  QPS=$(echo "$R" | awk '/Queries per second:/{print $4}')
  SENT=$(echo "$R" | awk '/Queries sent:/{print $3}')
  COMP=$(echo "$R" | awk '/Queries completed:/{print $3}')
  LOST=$(echo "$R" | awk '/Queries lost:/{gsub(/[()%]/,"",$4); print $4}')
  echo "$LABEL,$r,${QPS:-NA},${SENT:-NA},${COMP:-NA},${LOST:-NA}"
  echo "$LABEL,$r,${QPS:-NA},${SENT:-NA},${COMP:-NA},${LOST:-NA}" >> "$OUT"
done
