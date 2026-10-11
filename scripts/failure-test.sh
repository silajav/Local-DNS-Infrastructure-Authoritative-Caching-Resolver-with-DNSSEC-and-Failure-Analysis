#!/bin/bash
# Usage: ./scripts/failure-test.sh <run-number>
# Output: results/failure-run<N>.csv (timeline) and results/failure-recovery.csv (summary)
cd "$(dirname "$0")/.."
RUN=${1:?Usage: $0 <run-number>}
OUTAGE=15
MAXWAIT=180
LOG=results/failure-run$RUN.csv
SUM=results/failure-recovery.csv
mkdir -p results
[ -f "$SUM" ] || echo "run,outage_seconds,recovery_seconds" > "$SUM"
echo "time_s,phase,status" > "$LOG"

now() { date +%s.%N; }
q() {
  st=$(docker exec client dig @10.0.2.10 www.lab.test +time=2 +tries=1 2>/dev/null | grep -o 'status: [A-Z]*' | cut -d' ' -f2)
  echo "${st:-TIMEOUT}"
}

docker start server >/dev/null
sleep 3
echo "Stopping BIND9 and flushing the resolver cache..."
docker stop server >/dev/null
docker exec resolver unbound-control flush_zone lab.test >/dev/null
docker exec resolver unbound-control flush_infra all >/dev/null

T0=$(now)
while true; do
  el=$(awk -v a="$(now)" -v b="$T0" 'BEGIN{printf "%.2f", a-b}')
  awk -v e="$el" -v o="$OUTAGE" 'BEGIN{exit !(e>=o)}' && break
  st=$(q)
  echo "$el,outage,$st" | tee -a "$LOG"
  sleep 1
done

echo "Restarting BIND9..."
docker start server >/dev/null
T1=$(now)
REC=NA
while true; do
  st=$(q)
  el=$(awk -v a="$(now)" -v b="$T0" 'BEGIN{printf "%.2f", a-b}')
  rec=$(awk -v a="$(now)" -v b="$T1" 'BEGIN{printf "%.2f", a-b}')
  echo "$el,recovery,$st" | tee -a "$LOG"
  if [ "$st" = "NOERROR" ]; then REC=$rec; break; fi
  awk -v r="$rec" -v m="$MAXWAIT" 'BEGIN{exit !(r>=m)}' && break
  sleep 0.5
done
echo "$RUN,$OUTAGE,$REC" >> "$SUM"
echo "Recovery time: ${REC}s (saved to $SUM)"
