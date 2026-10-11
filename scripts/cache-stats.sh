#!/bin/bash
# Usage:
#   ./scripts/cache-stats.sh reset          (zero the counters)
#   ./scripts/cache-stats.sh <label>        (append hits/misses/ratio to results/cache-stats.csv)
cd "$(dirname "$0")/.."
if [ "$1" = "reset" ]; then
  docker exec resolver unbound-control stats >/dev/null
  echo "Counters reset."
  exit 0
fi
LABEL=${1:?Usage: $0 reset | <label>}
OUT=results/cache-stats.csv
mkdir -p results
[ -f "$OUT" ] || echo "label,hits,misses,hit_ratio_percent" > "$OUT"
S=$(docker exec resolver unbound-control stats_noreset)
HITS=$(echo "$S" | awk -F= '$1=="total.num.cachehits"{print $2}')
MISS=$(echo "$S" | awk -F= '$1=="total.num.cachemiss"{print $2}')
RATIO=$(awk -v h="$HITS" -v m="$MISS" 'BEGIN{ if (h+m>0) printf "%.1f", 100*h/(h+m); else print "0.0" }')
echo "$LABEL,$HITS,$MISS,$RATIO" >> "$OUT"
echo "hits=$HITS misses=$MISS hit_ratio=${RATIO}%"
