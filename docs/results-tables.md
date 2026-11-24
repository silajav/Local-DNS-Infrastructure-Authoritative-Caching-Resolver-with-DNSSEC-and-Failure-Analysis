# Results summary

Mean and sample standard deviation (n-1) per condition. Only NOERROR answers are averaged; failures are counted separately.

## Resolution time (cache-test.sh)

Times are the wall-clock time of one `dig` inside the client container. They include a few ms of dig start-up that is the same in every condition, so compare conditions with each other rather than reading absolute values.

| Condition | Cache | Runs OK | Failed | Mean (ms) | Std dev (ms) |
|---|---|---|---|---|---|
| Baseline | cold | 3 | 0 | 13.2 | 5.4 |
| Baseline | warm | 3 | 0 | 9.5 | 1.0 |
| Delay 100 ms | cold | 3 | 0 | 424.8 | 0.6 |
| Delay 100 ms | warm | 3 | 0 | 12.5 | 8.1 |
| Loss 5% | cold | 10 | 0 | 177.6 | 254.5 |
| Loss 5% | warm | 10 | 0 | 13.4 | 4.6 |
| BW 64 kbit/s | cold | 3 | 0 | 151.4 | 8.3 |
| BW 64 kbit/s | warm | 3 | 0 | 10.2 | 1.4 |

## Cache hit ratio (hitratio-test.sh / cache-stats.sh)

| Condition | Runs | Mean hits | Mean misses | Mean hit ratio (%) | Std dev (%) |
|---|---|---|---|---|---|
| baseline | 3 | 18.0 | 3.0 | 85.7 | 0.0 |
| delay100 | 3 | 18.0 | 3.0 | 85.7 | 0.0 |
| loss5 | 3 | 18.0 | 3.0 | 85.7 | 0.0 |

## Throughput (load-test.sh, dnsperf)

| Condition | Runs | Mean QPS | Std dev QPS | Mean lost (%) |
|---|---|---|---|---|
| Normal | 3 | 40838 | 7359 | 0.00 |
| Delay 100 ms | 3 | 459 | 58 | 0.00 |
| Loss 5% | 3 | 467 | 19 | 9.68 |

## Authoritative server failure and recovery (failure-test.sh)

| Outage length (s) | Runs | Mean recovery (s) | Std dev (s) | Min (s) | Max (s) |
|---|---|---|---|---|---|
| 5 | 3 | 2.90 | 1.79 | 1.81 | 4.97 |
| 15 | 3 | 1.40 | 0.13 | 1.26 | 1.51 |
| 30 | 3 | 3.56 | 2.94 | 0.66 | 6.54 |

Recovery = seconds from restarting BIND9 until the first NOERROR answer. The run recorded while tcpdump was running is reported separately.

