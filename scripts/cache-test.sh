#!/bin/bash
# Usage: ./scripts/cache-test.sh <label> [runs=3] [name=www.lab.test]
# Output: results/cache-<label>.csv
cd "$(dirname "$0")/.."
LABEL=${1:?Usage: $0 <label> [runs] [name]}
RUNS=${2:-3}
NAME=${3:-www.lab.test}
OUT=results/cache-$LABEL.csv
mkdir -p results
echo "label,run,cache,dig_ms,total_us,status" > "$OUT"

query() {
docker exec -i client bash -s -- "$NAME" <<'EOF'
NAME=$1
s=$(date +%s%N)
out=$(dig @10.0.2.10 "$NAME" +dnssec +time=5 +tries=1)
e=$(date +%s%N)
ms=$(echo "$out" | awk '/Query time/{print $4}')
st=$(echo "$out" | grep -o 'status: [A-Z]*' | cut -d' ' -f2)
echo "${ms:-NA},$(( (e-s)/1000 )),${st:-TIMEOUT}"
EOF
}

for r in $(seq 1 "$RUNS"); do
  docker exec resolver unbound-control flush_zone lab.test >/dev/null
  docker exec resolver unbound-control flush_infra all >/dev/null
  cold=$(query)
  warm=$(query)
  echo "$LABEL,$r,cold,$cold" >> "$OUT"
  echo "$LABEL,$r,warm,$warm" >> "$OUT"
done
cat "$OUT"
