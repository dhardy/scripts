Microbenchmarks with inconsistent results are not very useful. What can we do about that?

## CPU isolation

This article helped me reduce benchmark jitter: https://manuel.bernhardt.io/posts/2023-11-16-core-pinning/

It recommended not using cores 0 or 1 so I tried using 7 (the last non-virtual core on my CPU) but got bad jitter (measured using [hiccups](https://github.com/rigtorp/hiccups). Trying again with core 4 got much better results. My kernel arguments:
```
nohz_full=4,12 isolcpus=domain,managed_irq,4,12 irqaffinity=0-3,5-11,13-15
```

## CPU frequency

Next, I'm pinning the CPU frequency:
```
$ cd /sys/devices/system/cpu/cpu4/cpufreq
$ cat scaling_min_freq | sudo tee scaling_max_freq
1754308
```
The following shows rock solid CPU frequency:
```
$ while true; do cat scaling_cur_freq; sleep 1; done
```

## Pinning to core 4

Now, pinning the benchmark to core 4 get better results:
```
taskset -c 4 cargo bench --bench generators
```
Re-running this benchmark twice in a row I still see variations. The first is actually quite promising: -0.0161% time deviation. Many have less than 1% deviation; unfortunately many others still show a few % variation. Four results show more than 5% variation.