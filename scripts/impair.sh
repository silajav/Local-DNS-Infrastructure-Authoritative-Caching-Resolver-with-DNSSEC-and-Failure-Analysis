#!/bin/bash
# Usage: ./scripts/impair.sh <delay|loss|rate|clear|show> [value] [upstream|client]
# Examples:
#   ./scripts/impair.sh delay 100ms
#   ./scripts/impair.sh loss 5%
#   ./scripts/impair.sh rate 64kbit
#   ./scripts/impair.sh delay 100ms client
#   ./scripts/impair.sh clear
MODE=$1; VAL=$2; WHERE=${3:-upstream}
ALL="router1:eth0 router1:eth1 router2:eth0 router2:eth1"
case "$WHERE" in
  upstream) TARGETS="router2:eth0 router2:eth1" ;;
  client)   TARGETS="router1:eth0 router1:eth1" ;;
  *) echo "Third argument must be upstream or client"; exit 1 ;;
esac
case "$MODE" in
  clear|show) TARGETS=$ALL ;;
  delay|loss|rate) [ -z "$VAL" ] && { echo "Give a value, e.g. $MODE 100ms"; exit 1; } ;;
  *) echo "Usage: $0 <delay|loss|rate|clear|show> [value] [upstream|client]"; exit 1 ;;
esac
for t in $TARGETS; do
  c=${t%%:*}; i=${t##*:}
  case "$MODE" in
    delay) docker exec $c tc qdisc replace dev $i root netem delay $VAL ;;
    loss)  docker exec $c tc qdisc replace dev $i root netem loss $VAL ;;
    rate)  docker exec $c tc qdisc replace dev $i root netem rate $VAL ;;
    clear) docker exec $c tc qdisc del dev $i root 2>/dev/null || true ;;
    show)  echo "$t: $(docker exec $c tc qdisc show dev $i | head -1)" ;;
  esac
done
[ "$MODE" = clear ] && echo "All impairments cleared."
[ "$MODE" != clear ] && [ "$MODE" != show ] && echo "Applied $MODE $VAL on $WHERE path."
exit 0
