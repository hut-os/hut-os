# HUTOS Scheduler — run-queue wait latency monitor

## What it is

A lightweight Linux scheduler **observability** extension for HUT OS
(`CONFIG_HUTOS_SCHED_LAT`). It does **not** replace CFS/EEVDF or change
scheduling policy.

It measures how long runnable tasks wait on the runqueue before they
first execute on a CPU, using timestamps already maintained by
`CONFIG_SCHED_INFO`.

## Why this design

| Goal | Choice |
|------|--------|
| Useful + measurable | Per-CPU avg/min/max wait latency |
| Low risk | No policy changes; static key off by default |
| Hot-path cost | One `static_branch_unlikely()` when disabled |
| HUTOS-usable | `/proc/hutos_sched` (no debugfs required) |
| Extensible | Per-CPU counters + sysctl gate |

## How it works

1. On task arrival (`sched_info_arrive`), if the monitor is enabled,
   record `delta = rq_clock - last_queued` into per-CPU counters.
2. Enable/disable with a **static key** (`kernel.hutos_sched_lat`).
3. Read results from `/proc/hutos_sched`; write `reset` to clear.

## Enable

```bash
# Runtime
sysctl kernel.hutos_sched_lat=1
# or
hutsched on

# Boot cmdline
hutos_sched_lat=1
```

## Userspace helpers

```bash
hutsched show    # cat /proc/hutos_sched
hutsched on      # enable
hutsched off     # disable
hutsched reset   # clear counters
```

## Kernel patch

See [hut-os/linux-config](https://github.com/hut-os/linux-config) `patches/`
or `kernel-patches/` in this repository.

## Benchmark (QEMU, 1500× `busybox true`)

Measured with `rdinit=/bin/hutsched-bench`:

| Mode | Wall time (uptime delta) | Samples |
|------|--------------------------|---------|
| Monitor OFF | 8.23 s | 0 |
| Monitor ON  | 7.97 s | 12745 (avg wait ≈ 170 µs) |

Overhead is within QEMU timing noise (ON was not slower). Hot-path cost
when disabled is a single unlikely branch.
