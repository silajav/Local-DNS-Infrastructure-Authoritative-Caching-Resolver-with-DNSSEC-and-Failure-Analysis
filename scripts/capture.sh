#!/bin/bash
# Usage:
#   ./scripts/capture.sh start <container> <name> [tcpdump filter]
#   ./scripts/capture.sh stop  <container> <name>
# Example:
#   ./scripts/capture.sh start resolver cold-lookup port 53
#   (run your dig)
#   ./scripts/capture.sh stop resolver cold-lookup
cd "$(dirname "$0")/.."
ACTION=$1; CONT=$2; NAME=$3
[ -z "$NAME" ] && { echo "Usage: $0 start|stop <container> <name> [filter]"; exit 1; }
shift 3
mkdir -p results
case "$ACTION" in
  start)
    docker exec "$CONT" rm -f /tmp/$NAME.pcap
    docker exec -d "$CONT" sh -c "echo \$\$ > /tmp/$NAME.pid; exec tcpdump -Z root -i any -U -w /tmp/$NAME.pcap $*"
    sleep 2
    echo "Capture '$NAME' started on $CONT. Send your queries now."
    ;;
  stop)
    docker exec "$CONT" sh -c "kill -INT \$(cat /tmp/$NAME.pid)"
    sleep 2
    docker cp "$CONT:/tmp/$NAME.pcap" "results/$NAME.pcap"
    echo "Saved results/$NAME.pcap"
    ;;
  *) echo "First argument must be start or stop"; exit 1 ;;
esac
