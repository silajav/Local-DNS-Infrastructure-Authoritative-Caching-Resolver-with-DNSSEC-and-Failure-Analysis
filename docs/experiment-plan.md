# Experiment Plan

Each experiment is run **3 times**. Between experiments the lab is returned to a clean state with `./scripts/impair.sh clear`.

| ID | Experiment | Condition (command) | Metric | Script | Output file |
|---|---|---|---|---|---|
| E1 | Baseline cold vs warm cache | none | Resolution time, cache hit ratio | `cache-test.sh baseline` + `cache-stats.sh baseline` | `results/cache-baseline.csv` |
| E2 | Delay on resolver-to-server path | `impair.sh delay 100ms` | Resolution time | `cache-test.sh delay100` | `results/cache-delay100.csv` |
| E3 | Packet loss | `impair.sh loss 5%` | Resolution time | `cache-test.sh loss5` | `results/cache-loss5.csv` |
| E4 | Bandwidth limit | `impair.sh rate 64kbit` | Resolution time | `cache-test.sh bw64k` | `results/cache-bw64k.csv` |
| E5 | QPS, normal | none | Queries per second | `load-test.sh normal` | `results/qps.csv` |
| E6 | QPS, delay | `impair.sh delay 100ms client` | Queries per second | `load-test.sh delay100` | `results/qps.csv` |
| E7 | QPS, packet loss | `impair.sh loss 5% client` | Queries per second | `load-test.sh loss5` | `results/qps.csv` |
| E8 | Authoritative server outage and recovery | stop/start BIND9 | Recovery time | `failure-test.sh <run>` | `results/failure-recovery.csv` |

## Packet captures (results/)
| File | Scenario | How |
|---|---|---|
| `cold-lookup.pcap` | Cold lookup | `capture.sh` on resolver, filter `port 53` |
| `warm-lookup.pcap` | Warm lookup | same, second query |
| `dnssec.pcap` | DNSSEC query with `+dnssec` | same |
| `outage.pcap` | BIND9 outage | capture during `failure-test.sh` |

## Notes
- E2-E4 impair the **upstream** path (router2), so they slow only cold lookups. Warm answers come from the cache and stay fast.
- E6-E7 impair the **client** path (router1), because a warm cache hides upstream problems from a load test.
- `impair.sh` impairs both directions: a 100 ms delay adds about 200 ms to a round trip.
- Mean and standard deviation are computed by `analyze.py` (Group D).
- E3 (packet loss) uses 10 runs instead of 3, because 5% loss rarely hits a short cold lookup.
