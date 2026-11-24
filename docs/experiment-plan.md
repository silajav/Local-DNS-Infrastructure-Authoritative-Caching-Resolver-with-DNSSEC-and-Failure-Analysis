# Experiment Plan

Every condition below is run at least 3 times (packet-loss resolution time uses 10 runs, because 5% loss rarely hits a short cold lookup). Between experiments the lab is returned to a clean state with `./scripts/impair.sh clear`. Mean and standard deviation are computed by `scripts/analyze.py`.

## Experiment table (each metric under at least 3 conditions)

| Metric | Condition | Command | Runs | Script | Output |
|---|---|---|---|---|---|
| Resolution time (cold / warm) | Baseline | none | 3 | `cache-test.sh baseline` | `results/cache-baseline.csv` |
| Resolution time | 100 ms delay (upstream) | `impair.sh delay 100ms` | 3 | `cache-test.sh delay100` | `results/cache-delay100.csv` |
| Resolution time | 5% packet loss (upstream) | `impair.sh loss 5%` | 10 | `cache-test.sh loss5` | `results/cache-loss5.csv` |
| Resolution time | 64 kbit/s bandwidth (upstream) | `impair.sh rate 64kbit` | 3 | `cache-test.sh bw64k` | `results/cache-bw64k.csv` |
| Cache hit ratio | Baseline | none | 3 | `hitratio-test.sh baseline` | `results/cache-stats.csv` |
| Cache hit ratio | 100 ms delay | `impair.sh delay 100ms` | 3 | `hitratio-test.sh delay100` | `results/cache-stats.csv` |
| Cache hit ratio | 5% packet loss | `impair.sh loss 5%` | 3 | `hitratio-test.sh loss5` | `results/cache-stats.csv` |
| Throughput (QPS) | Normal | none | 3 | `load-test.sh normal` | `results/qps.csv` |
| Throughput (QPS) | 100 ms delay (client path) | `impair.sh delay 100ms client` | 3 | `load-test.sh delay100` | `results/qps.csv` |
| Throughput (QPS) | 5% packet loss (client path) | `impair.sh loss 5% client` | 3 | `load-test.sh loss5` | `results/qps.csv` |
| Recovery time | BIND9 outage of 5 s | stop/start `server` | 3 | `failure-test.sh o5-N 5` | `results/failure-recovery.csv` |
| Recovery time | BIND9 outage of 15 s | stop/start `server` | 3 | `failure-test.sh o15-N 15` | `results/failure-recovery.csv` |
| Recovery time | BIND9 outage of 30 s | stop/start `server` | 3 | `failure-test.sh o30-N 30` | `results/failure-recovery.csv` |

## Packet captures (`results/`, taken on the resolver unless noted)

| File | Protocol exchange | How |
|---|---|---|
| `cold-lookup.pcap` | DNS cold lookup (client to resolver, resolver to BIND9) | `capture.sh`, filter `port 53` |
| `warm-lookup.pcap` | DNS warm lookup (answered from cache) | same, second query |
| `dnssec.pcap` | DNSSEC: DNSKEY fetch, RRSIG records, AD flag | `dig +dnssec` |
| `dns-tcp.pcap` | DNS over TCP (handshake, query, reply, close) | `dig +tcp` |
| `icmp-routing.pcap` | ICMP echo and traceroute (taken on the client) | `ping`, `traceroute` |
| `outage.pcap` | BIND9 outage: repeated queries with no reply | during `failure-test.sh` |

## Notes
- Delay, loss and bandwidth on the **upstream** path (router2) affect only cold lookups. Warm answers come from the cache.
- QPS impairments use the **client** path (router1), because a warm cache hides upstream problems from a load test.
- `impair.sh` impairs both directions: 100 ms delay adds about 200 ms to a round trip, and 5% loss each way gives about 9.75% round-trip loss.
- The cache hit ratio is expected to stay constant under impairments, since the cache is filled by successful answers regardless of how slow they were.
- Timings are wall-clock times of one `dig` inside the client container and include a few ms of `dig` start-up. Compare conditions with each other rather than reading absolute values.
