#!/usr/bin/env python3
"""Compute mean/std dev from results/*.csv, write results/summary.md and graphs."""
import csv, os, statistics as stats
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "results")

def load(name):
    p = os.path.join(R, name)
    if not os.path.exists(p):
        return []
    with open(p, newline="") as f:
        return list(csv.DictReader(f))

def ms(v):
    v = list(v)
    if not v:
        return (float("nan"), float("nan"))
    return (stats.mean(v), stats.stdev(v) if len(v) > 1 else 0.0)

def num(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None

def bars(labels, means, sds, title, ylabel, fname, log=False):
    lower = [min(s, m * 0.9) if m == m else 0 for m, s in zip(means, sds)]
    fig, ax = plt.subplots(figsize=(7, 4))
    ax.bar(labels, means, yerr=[lower, sds], capsize=4)
    ax.set_title(title); ax.set_ylabel(ylabel)
    if log:
        ax.set_yscale("log")
    for i, m in enumerate(means):
        ax.text(i, m, f"{m:.1f}", ha="center", va="bottom", fontsize=8)
    fig.tight_layout(); fig.savefig(os.path.join(R, fname), dpi=150); plt.close(fig)

out = []
def line(s=""):
    out.append(s)

CONDS = [("baseline", "Baseline"), ("delay100", "Delay 100 ms"),
         ("loss5", "Loss 5%"), ("bw64k", "BW 64 kbit/s")]

line("# Results summary"); line()
line("Mean and standard deviation (sample, n-1) per condition. Only NOERROR answers are averaged; failures are counted separately.")
line()

# ---- Resolution time ----
line("## Resolution time (cache-test.sh)"); line()
line("Times are the wall-clock time of one `dig` inside the client container. They include a few ms of dig start-up that is the same in every condition, so compare conditions with each other rather than reading absolute values.")
line()
line("| Condition | Cache | Runs OK | Failed | Mean (ms) | Std dev (ms) |")
line("|---|---|---|---|---|---|")
cold, warm = {}, {}
for key, name in CONDS:
    rows = load(f"cache-{key}.csv")
    for kind, store in (("cold", cold), ("warm", warm)):
        sel = [r for r in rows if r["cache"] == kind]
        ok = [int(r["total_us"]) / 1000 for r in sel if r["status"] == "NOERROR"]
        m, s = ms(ok)
        store[key] = (m, s)
        line(f"| {name} | {kind} | {len(ok)} | {len(sel) - len(ok)} | {m:.1f} | {s:.1f} |")
line()

# ---- Cache hit ratio ----
line("## Cache hit ratio (cache-stats.sh)"); line()
rows = load("cache-stats.csv")
ratios = [num(r["hit_ratio_percent"]) for r in rows if num(r["hit_ratio_percent"]) is not None]
hits = [num(r["hits"]) for r in rows if num(r["hits"]) is not None]
miss = [num(r["misses"]) for r in rows if num(r["misses"]) is not None]
line("| Runs | Mean hits | Mean misses | Mean hit ratio (%) | Std dev (%) |")
line("|---|---|---|---|---|")
line(f"| {len(ratios)} | {ms(hits)[0]:.1f} | {ms(miss)[0]:.1f} | {ms(ratios)[0]:.1f} | {ms(ratios)[1]:.1f} |")
line()

# ---- QPS ----
line("## Throughput (load-test.sh, dnsperf)"); line()
q = {}
for r in load("qps.csv"):
    q.setdefault(r["label"], []).append(r)
line("| Condition | Runs | Mean QPS | Std dev QPS | Mean lost (%) |")
line("|---|---|---|---|---|")
qnames, qmeans, qsds = [], [], []
for label, name in [("normal", "Normal"), ("delay100", "Delay 100 ms"), ("loss5", "Loss 5%")]:
    rs = q.get(label, [])
    v = [num(r["qps"]) for r in rs if num(r["qps"]) is not None]
    lost = [num(r["lost_percent"]) for r in rs if num(r["lost_percent"]) is not None]
    m, s = ms(v)
    qnames.append(name); qmeans.append(m); qsds.append(s)
    line(f"| {name} | {len(v)} | {m:.0f} | {s:.0f} | {ms(lost)[0]:.2f} |")
line()

# ---- Recovery ----
line("## Authoritative server failure and recovery (failure-test.sh)"); line()
rec = [(int(r["run"]), num(r["recovery_seconds"])) for r in load("failure-recovery.csv")
       if num(r["recovery_seconds"]) is not None]
line("| Run | Outage (s) | Recovery (s) |")
line("|---|---|---|")
for run, v in rec:
    line(f"| {run} | 15 | {v:.2f} |")
clean = [v for run, v in rec if run <= 3]
m3, s3 = ms(clean)
ma, sa = ms([v for _, v in rec])
line()
line(f"- Runs 1-3: mean **{m3:.2f} s**, std dev {s3:.2f} s")
line(f"- All runs: mean {ma:.2f} s, std dev {sa:.2f} s (run 4 was recorded with tcpdump running)")
line()

with open(os.path.join(R, "summary.md"), "w") as f:
    f.write("\n".join(out) + "\n")

# ---- Graphs ----
bars(["Cold", "Warm"], [cold["baseline"][0], warm["baseline"][0]],
     [cold["baseline"][1], warm["baseline"][1]],
     "Baseline: cold vs warm cache", "dig wall-clock time (ms)", "graph-cold-vs-warm.png")

fig, ax = plt.subplots(figsize=(8, 4))
x = list(range(len(CONDS)))
ax.bar([i - 0.2 for i in x], [cold[k][0] for k, _ in CONDS], 0.4, label="Cold")
ax.bar([i + 0.2 for i in x], [warm[k][0] for k, _ in CONDS], 0.4, label="Warm")
ax.set_xticks(x); ax.set_xticklabels([n for _, n in CONDS])
ax.set_yscale("log"); ax.set_ylabel("Mean time (ms, log scale)")
ax.set_title("Effect of network impairments on resolution time"); ax.legend()
fig.tight_layout(); fig.savefig(os.path.join(R, "graph-impairments.png"), dpi=150); plt.close(fig)

bars(qnames, qmeans, qsds, "Throughput under normal and impaired conditions",
     "Queries per second (log scale)", "graph-qps.png", log=True)

if rec:
    fig, ax = plt.subplots(figsize=(6, 4))
    ax.bar([f"Run {r}" for r, _ in rec], [v for _, v in rec])
    ax.axhline(m3, linestyle="--", color="gray", label=f"Mean of runs 1-3 = {m3:.2f} s")
    ax.set_ylabel("Recovery time (s)"); ax.set_title("BIND9 restart to first successful answer")
    ax.legend(); fig.tight_layout()
    fig.savefig(os.path.join(R, "graph-recovery.png"), dpi=150); plt.close(fig)

print("Wrote results/summary.md and 4 graphs.")
