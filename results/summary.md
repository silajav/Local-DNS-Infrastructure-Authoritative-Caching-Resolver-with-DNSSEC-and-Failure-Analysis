# Results summary

Mean and standard deviation (sample, n-1) per condition. Only NOERROR answers are averaged; failures are counted separately.

## Resolution time (cache-test.sh)

Times are the wall-clock time of one `dig` inside the client container. They include a few ms of dig start-up that is the same in every condition, so compare conditions with each other rather than reading absolute values.

| Condition | Cache | Runs OK | Failed | Mean (ms) | Std dev (ms) |
|---|---|---|---|---|---|
| Baseline | cold | 3 | 0 | 14.5 | 2.7 |
| Baseline | warm | 3 | 0 | 10.5 | 2.1 |
| Delay 100 ms | cold | 3 | 0 | 419.9 | 7.2 |
| Delay 100 ms | warm | 3 | 0 | 10.2 | 1.4 |
| Loss 5% | cold | 10 | 0 | 45.7 | 89.7 |
| Loss 5% | warm | 10 | 0 | 11.4 | 3.6 |
| BW 64 kbit/s | cold | 3 | 0 | 150.0 | 1.9 |
| BW 64 kbit/s | warm | 3 | 0 | 17.3 | 3.4 |

## Cache hit ratio (cache-stats.sh)

| Runs | Mean hits | Mean misses | Mean hit ratio (%) | Std dev (%) |
|---|---|---|---|---|
| 3 | 18.0 | 3.0 | 85.7 | 0.0 |

## Throughput (load-test.sh, dnsperf)

| Condition | Runs | Mean QPS | Std dev QPS | Mean lost (%) |
|---|---|---|---|---|
| Normal | 3 | 51416 | 11588 | 0.01 |
| Delay 100 ms | 3 | 449 | 81 | 0.90 |
| Loss 5% | 3 | 442 | 46 | 9.54 |

## Authoritative server failure and recovery (failure-test.sh)

| Run | Outage (s) | Recovery (s) |
|---|---|---|
| 1 | 15 | 1.48 |
| 2 | 15 | 1.55 |
| 3 | 15 | 1.55 |
| 4 | 15 | 5.41 |

- Runs 1-3: mean **1.53 s**, std dev 0.04 s
- All runs: mean 2.50 s, std dev 1.94 s (run 4 was recorded with tcpdump running)

