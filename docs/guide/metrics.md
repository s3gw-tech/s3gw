[//]: <> (cSpell:ignoreRegExp /rgw[-_]\w+/)

# Metrics

S3GW metrics leverage the Ceph [Perf
Counters](https://docs.ceph.com/en/latest/dev/perf_counters/) system
already built into RGW.

On top of Perf Counters we export additional 1D Prometheus-style
histograms (Ceph's histograms are 2D) using a built in Prometheus
endpoint part of the status frontend.

The prometheus endpoint implementation is separate from [Ceph
Exporter](https://github.com/digitalocean/ceph_exporter) or the Ceph
Mgr [Prometheus
Module](https://docs.ceph.com/en/latest/mgr/prometheus/).

## Status Frontend

s3gw supports an additional RGW frontend *status* offering a read-only
view into the application's state. The frontend is optional and can be
activated aside the beast frontend doing the S3 HTTP.

Most status frontend pages are text-based and meant for human
consumption. An exception is the Prometheus endpoint exporting perf
counters as [Prometheus Exposition
Format](https://prometheus.io/docs/instrumenting/exposition_formats/)

To enable the status frontend including the Prometheus endpoint, add
the `status` frontend to
[`rgw_frontends`](https://docs.ceph.com/en/quincy/radosgw/config-ref/#confval-rgw_frontends)
. On the command line this may look like:

```sh
--rgw-frontends 'beast port=7480, status bind=127.0.0.1 port=9090'
```

## Dashboard

A S3GW dashboard is available on Grafana Hub with ID 19544.

- [Grafana Dashboard](https://grafana.com/grafana/dashboards/19544-s3gw/)

## Prometheus Scraping Setup

The Prometheus endpoint is available on the status frontend address at `/prometheus`

Example configuration:

```yaml
scrape_configs:
  - job_name: 's3gw-status'
    metrics_path: '/prometheus'
    static_configs:
      - targets:
        - 127.0.0.1:9090
```
