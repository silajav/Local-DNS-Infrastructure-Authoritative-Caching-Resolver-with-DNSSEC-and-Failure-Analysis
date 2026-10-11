FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    iproute2 iputils-ping traceroute dnsutils tcpdump dnsperf \
    && rm -rf /var/lib/apt/lists/*
