# High Availability with s3gw

- [High Availability with s3gw](#high-availability-with-s3gw)
  - [Active/Active](#activeactive)
  - [Active/Warm Standby](#activewarm-standby)
  - [Active/Standby](#activestandby)
  - [Investigation's Rationale](#investigations-rationale)
  - [Failure cases](#failure-cases)
    - [radosgw's POD failure and radosgw's POD rescheduling](#radosgws-pod-failure-and-radosgws-pod-rescheduling)
    - [Cluster's node failure](#clusters-node-failure)
    - [radosgw's failure due to a bug not related to a certain input pattern](#radosgws-failure-due-to-a-bug-not-related-to-a-certain-input-pattern)
    - [radosgw's failure due to a bug related to a certain input pattern](#radosgws-failure-due-to-a-bug-related-to-a-certain-input-pattern)
    - [PV Data corruption at application level due to radosgw's anomalous exit](#pv-data-corruption-at-application-level-due-to-radosgws-anomalous-exit)
    - [PV Data corruption at application level](#pv-data-corruption-at-application-level)
  - [Measuring s3gw failures on Kubernetes](#measuring-s3gw-failures-on-kubernetes)
  - [The s3gw Probe](#the-s3gw-probe)
  - [Notes on testing s3gw within K8s](#notes-on-testing-s3gw-within-k8s)
    - [EXIT-1, 10 measures](#exit-1-10-measures)
    - [EXIT-0, 10 measures](#exit-0-10-measures)
  - [Tested Scenarios - radosgw-restart](#tested-scenarios---radosgw-restart)
    - [regular\_localhost\_zeroload\_emptydb](#regular_localhost_zeroload_emptydb)
    - [segfault\_localhost\_zeroload\_emptydb](#segfault_localhost_zeroload_emptydb)
    - [regular\_localhost\_load\_fio\_64\_write](#regular_localhost_load_fio_64_write)
    - [regular\_localhost\_zeroload\_400\_800Kdb](#regular_localhost_zeroload_400_800kdb)
      - [400K objects - measures done with the WAL file zeroed](#400k-objects---measures-done-with-the-wal-file-zeroed)
      - [800K objects - measures done with the WAL file still to be processed (size 32G)](#800k-objects---measures-done-with-the-wal-file-still-to-be-processed-size-32g)
    - [regular-localhost-incremental-fill-5k](#regular-localhost-incremental-fill-5k)
    - [scale\_deployment\_0\_1-k3s3nodes\_zeroload\_emptydb](#scale_deployment_0_1-k3s3nodes_zeroload_emptydb)
  - [Tested Scenarios - S3-workload during s3gw Pod outage](#tested-scenarios---s3-workload-during-s3gw-pod-outage)
    - [PutObj-100ms-ClusterIp](#putobj-100ms-clusterip)
    - [PutObj-100ms-Ingress](#putobj-100ms-ingress)

We want to investigate what *High Availability* - HA - means for a project like
the s3gw.

If we identify the meaning of HA as the ability to have N independent pipelines
so that the failure of some of those does not affect the user's operations,
this is something that could be not easy to achieve with the s3gw.

HA, anyway, is not necessarily tied to multiple independent pipelines.
While High Availability (as a component of dependable computing) can be achieved
through redundancy, it can also be achieved by significantly increased reliability
and quality of the stack. e.g., improving the start time improves HA by lowering
the *Recovery Time Objective* (RTO) metric after detecting and recovering from a
fault.
Furthermore, we must say: achieving HA in a way that never affects the
user's operations is also not realistic, since not all faults can be masked,
or the complexity required to attempt it would actually be detrimental to
overall system reliability/availability (aka not cost-effective).
Paradoxically, failing fast instead of hanging on an attempted fault recovery
can also increase observed availability.

Our key goal, for the s3gw, is to maximize user-visible, reliable service
availability, and to be tolerant with regard to certain faults (such as pod crashes,
single node outages ... - the faults we consider or explicitly exclude are discussed
later in the document).

With pipeline, we mean all the chain from the ingress to the persistent volume `PV`:

```mermaid
flowchart LR
    ingress(ingress) ==> radosgw(radosgw) ==> PV((PV))
```

HA can be difficult with a project like the s3gw because of one process: the `radosgw`,
owning an *exclusive* access to a resource: the Kubernetes `PV` where the S3
buckets and objects are persisted.
Actually, this is also an advantage, due to its lower complexity.
Active/active syncing of all operations is non-trivial,
and an active/standby pattern is much simpler to implement with lower overhead
in the absence of faults.

In theory, 3 HA models are possible with the s3gw:

1. **Active/Active**
2. **Active/Warm Standby**
3. **Active/Standby**

## Active/Active

The *Active-Active* model must implement *true independent pipelines*
where all the pieces are replicated.

The immediate consequence of this statement is that every pipeline being part of
the same logical s3gw service must bind to a different `PV`; one per `radosgw` process.
All the `PV`s for the same logical s3gw, must therefore, sync their data.

The need to synchronize and coordinate all operations across all nodes
(to guarantee Atomicity/Independence/Durability, which even S3's eventual consistency
model needs in some cases) is not free - even then there's a need to ensure the
data has been replicated in reality, and since a fault can only be detected via
a timeout of some form, there's still a blip in availability
(just, hopefully, not a returned error message).

Since the synchronization mechanism is often complex, there's an on-going price
to be paid for achieving this, plus it is harder to get right
(lowering availability through lowered quality).

```mermaid
flowchart LR
    client(client) ==> ingress
    ingress(ingress) ==> radosgw(radosgw) ==> PV((PV))
    ingress ==> radosgw2(radosgw) ==> PV2((PV))

    linkStyle 0 stroke: red
    linkStyle 1 stroke: red
    linkStyle 2 stroke: red
```

The ingress might still mask it and automatically retry.
That's another thing to consider: most S3 protocol libraries are built
on the assumption of an unreliable network, and so a single non-repeatable
failure might not show to the user, but just be (silently or not) retried and
on it goes without anyone knowing beyond a blip in high latency, unless it happens
too often.
This is a property of the S3 protocol that makes it a bit easier for us
to achieve, we hope.

```mermaid
flowchart LR
    client(client) ==> ingress
    ingress(ingress) ==> radosgw(radosgw) ==> PV((PV))
    ingress ==> radosgw2(radosgw) ==> PV2((PV))

    linkStyle 0 stroke: green
    linkStyle 1 stroke: red
    linkStyle 2 stroke: red
    linkStyle 3 stroke: green
    linkStyle 4 stroke: green
```

## Active/Warm Standby

This model assumes N pipelines to be "allocated" on the cluster at the same time,
but only one, the *active* pipeline, owns the *exclusive ownership*
over the shared `PV`.

Should the active pipeline suffer a failure, the next elected active pipeline,
chosen to replace the old one, should pay a *time window* necessary to "transfer"
the ownership over the shared `PV`.

The Active plus Warm Standby operation here has no meaningful advantages over the
Active/Standby option; loading the s3gw pod is the cheapest part of the whole
process, compared to fault detection (usually a timeout), mounting
(journal recovery) of the file system, the process running the SQLite,
recovery on start, etc.

We'd pay for this with complexity (and resource consumption while in standby)
hat likely would only give us very marginal benefits at best.

```mermaid
flowchart LR
    client(client) ==> ingress
    ingress(ingress) ==> radosgw(radosgw) ==> PV((PV))
    ingress ==> radosgw2(radosgw)

    linkStyle 0 stroke: red
    linkStyle 1 stroke: red
    linkStyle 2 stroke: red
```

```mermaid
flowchart LR
    client(client) ==> ingress
    ingress(ingress) ==> radosgw(radosgw)
    ingress ==> radosgw2(radosgw) == ownership transfer ==> PV((PV))

    linkStyle 0 stroke: red
    linkStyle 1 stroke: white
    linkStyle 2 stroke: red
```

```mermaid
flowchart LR
    client(client) ==> ingress
    ingress(ingress) ==> radosgw(radosgw)
    ingress ==> radosgw2(radosgw) ==> PV((PV))

    linkStyle 0 stroke: green
    linkStyle 1 stroke: white
    linkStyle 2 stroke: green
    linkStyle 3 stroke: green
```

## Active/Standby

In this scenario, in the event of failure, the system should pay the time
needed to fully load a new pipeline.

Supposing that the new pipeline has scheduled to load on a node where the
s3gw image is not cached, the system should pay the time needed to download
the image from the registry before starting it.

In general on Kubernetes, it can not be assumed that an image is pre-pulled,
since nodes may come and go dynamically.

Pre-pulled images is something we do want to ensure for eligible nodes.
Otherwise, our restart is unpredictably long.

It's always possible that a fault occurs exactly at the time where we are
pre-loading the image, but that's just bad luck.

## Investigation's Rationale

The 3 models described above have different performances and different implementation
efforts. While the *Active/Active* model is expected to require a significant
development effort due to its inherent complex nature, for our use case,
the Active/Standby model built on top of Longhorn actually makes
the most sense and brings the "best" HA characteristics relative to implementing
a more fully active/distributed solution.

In particular, the *Active/Standby* model, is expected to work with nothing
but the primitives normally available on any Kubernetes cluster.

Given that the backend s3gw architecture is composed by:

- one ingress and one `ClusterIP` service
- one *stateless* `radosgw` process associated with a *stateful* `PV`

it is supposed that, when the `radosgw` process fails, a simple reschedule
of its POD could be enough to fulfill this HA model.
All of this has obviously timeouts and delays, we suspect we'll have to adjust them
for our requirements.

A clarification is needed here: the `PV` *state* is guaranteed by a third party
service, that is: **Longhorn**.

Longhorn ensures that a `PV` (along with its content) is always available on
any cluster's node, so that, a POD can mount it regardless of its allocation on the
cluster.

Obviously, we can't achieve higher availability or reliability than the underlying
Longhorn volumes.

## Failure cases

The `PV` state is kept coherent by Longhorn, so errors at this level are assumed
NOT possible; application level corruptions to the `PV`'s state ARE possible.
s3gw won't corrupt the PV's state or the file system on it,
but it might corrupt its own application data.
Any corruption in the file system is outside what s3gw can reasonably protect
against; at best, it can crash in a way that doesn't corrupt the data further,
but that's all undefined behavior and "restore from backup" time.

What are the failure cases that can happen for s3gw?
Making these cases explicit could be useful for a theoretical reasoning on what
scenarios we can actually think to solve with an HA model.
If a case is clearly outside what an HA model can handle, we must expect that
the Kubernetes back off mechanism to be the only mitigation when a restart loop
should occur.

Let's examine the following scenarios:

1. `radosgw`'s POD failure and `radosgw`'s POD rescheduling
2. Cluster's node failure
3. `radosgw`'s failure due to a bug not related to a certain input pattern
4. `radosgw`'s failure due to a bug related to a certain input pattern
5. `PV` PV Data corruption at application level due to radosgw's anomalous exit

We are supposing all these bugs or conditions to be fatal for the s3gw's process
so that they trigger an anomalous exit.

### radosgw's POD failure and radosgw's POD rescheduling

This case is when the `radosgw` process stops due to a failure of its POD.

This case applies also when Kubernetes decides to reschedule the POD
to another node, eg: when the node goes low on resources.
This would often be called a "switch-over" in an HA cluster -
e.g., an administratively orchestrated transition of the service to a new node
(say, for maintenance/upgrade/etc reasons).
This has the advantage of being schedulable, so it can happen at times
of low load if these exist.
In combination with proper interaction with the ingress - pausing requests
there instead of failing them - we should be able to mask these cleanly.

Bonus: this is also what we need to seamlessly restart on upgrade/update of the
pod itself transparently.

This can be thought as an infrastructure issue independent to the s3gw.
In this case, the *Active/Standby* model fully restores the service by
rescheduling a new POD somewhere in the cluster.

### Cluster's node failure

This case is when the `radosgw` process stops due to a cluster's node failure.
The *Active/Standby* model fully restores the service by
rescheduling a new POD somewhere in the cluster.
this also means we weren't shut down cleanly.
So the on start recovery needs to be optimized for the stack, and as soon as we
can, we need to hook into the ingress and tell it to pause until we're done,
and then resume.

### radosgw's failure due to a bug not related to a certain input pattern

This case is when the `radosgw` process crashes due to a bug not directly
related to any input type.

Examples:

- Memory leaks
- Memory corruptions (stack or heap corruptions)
- Periodic operations or routines not related to an input (GC, measures,
  telemetry, etc)

For a bug like this, the *Active/Standby* model could guarantee
the user's operations *until the next occurrence* of the same malfunctioning.

A definitive solution would be available only when a patch for the issue
has released.

### radosgw's failure due to a bug related to a certain input pattern

This case is when the `radosgw` process crashes due to a bug directly
related to a certain input type.

Examples:

- Putting Buckets with some name's pattern
- Putting Objects that have a certain size
- Performing an admin operation over a suspended user

For a bug like this, the *Active/Standby* model could guarantee
the user's operations under the condition that the crash-triggering
input is recognized by the user and thus its submission blocked.

### PV Data corruption at application level due to radosgw's anomalous exit

This case is when the state on the `PV` corrupts due to a `radosgw`'s
anomalous exit.

In this unfortunate scenario, the *Active/Standby* can hardly help.
A restart could evenly fix the problem or trigger an endless restarting loop.
Logical data corruption is a Robustness/Reliability problem; the best we can
aim for is to detect it (and abort with prejudice and finally so, so as to not
make the corruption worse).
The fix for this could contemplate an human intervention.
A definitive solution would be available only when a patch for the issue
is available.

### PV Data corruption at application level

This case is when the state on the PV corrupts due to a `radosgw`
anomalous exit, eg: after a node failure.

This scenario could even be NOT possible because of the safety features
implemented on the radosgw SFS backend.

The fix for this could contemplate an human intervention.

## Measuring s3gw failures on Kubernetes

After reviewing the cases, we can say that what can be actually solved with
an HA model with s3gw is when the failure is not dependent to applicative bugs.
We can handle temporary issues involving the infrastructure that is hosting
the `radosgw` process.

We are interested in measuring:

- The (kill - re) start loop timing outside of k8s/LH.
So we have a baseline and we can measure of what Kubernetes adds, and how slow
the s3gw is when exiting:

  - Cleanly
  - Crashing with no ops in flight
  - Crashing with a load on-going

- Then, fault detection times for k8s - how long until it notices that the
process has crashed (that should be quick due to the generated signal),
but what about the process hanging? (e.g., crashes are separate from timeouts)

- Node failures, again, we need to understand which factors affect k8s detecting
that and reacting to them, and what latencies are introduced by k8s/LH.

Actively asking k8s to restart is different (see case one, switch- vs fail-over).
That should be smooth, but is not actually a failure scenario.
Probably worth handling in a separate section.

Hence, The idea to collect measures regarding a series of restarts
artificially triggered on the `radosgw`'s POD.
Obtaining such measures would allow to compute some arbitrary statistics
for the time required by Kubernetes to restart the `radosgw`'s POD.

## The s3gw Probe

The `s3gw Probe` is a program developed with the purpose of collecting restart
events coming from the `radosgw` process.
The tool is acting as a client/server service inside the Kubernetes cluster.

- It acts as client vs the `radosgw` process requesting it to die.
- It acts as server of `radosgw` process collecting its `death` and `start` events.
- It acts as server of the user's client accepting configurations of restart
  scenarios to be triggered against the `radosgw` process.
- It acts as server of the user's client returning statistics over the collected
  data.

In nutshell:

- The `s3gw Probe` can be instructed to trigger `radosgw` restarts
  with a RESTful call.
- The `s3gw Probe` can be queried for statistics over the collected data.

The usage sequence for the s3gw Probe is the following:

- The user instructs the tool

```mermaid
flowchart LR
    user[curl] == setup & trigger restarts  ==> probe(s3gw probe)

    linkStyle 0 stroke: green
```

- The tool performs the `die request` cycle collecting the `death` and `start`
  events from the `radosgw` process.

```mermaid
flowchart LR
    probe(s3gw probe) == die request #1  ==> radosgw(radosgw)
    == death notice #1  ==> probe

    linkStyle 0 stroke: red
    linkStyle 1 stroke: blue
```

```mermaid
flowchart LR
    radosgw(radosgw) == start notice #1  ==> probe(s3gw probe)
    probe(s3gw probe) == collect restart event #1  ==> probe(s3gw probe)

    linkStyle 0 stroke: green
    linkStyle 1 stroke: blue
```

- The user queries the tool for the statistics

```mermaid
flowchart LR
    user[curl] == query statistics  ==> probe(s3gw probe)
    == statistics ==> user

    linkStyle 0 stroke: green
    linkStyle 1 stroke: blue
```

The `radosgw` code has been patched to accept a REST call from the probe
where the user can specify the way the `radosgw` will exit.
Currently, 4 modes are possible:

- `EXIT_0`
- `EXIT_1`
- `CORE_BY_SEG_FAULT`
- `REGULAR`

## Notes on testing s3gw within K8s

As previously said, we want to compute some statistics regarding the Kubernetes
performances when restarting the `radosgw`'s Pod.

### EXIT-1, 10 measures

```yaml
  - mark: exit1
    series:
      - restart_id: 1
        duration: 0
      - restart_id: 2
        duration: 15
      - restart_id: 3
        duration: 24
      - restart_id: 4
        duration: 42
      - restart_id: 5
        duration: 91
      - restart_id: 6
        duration: 174
      - restart_id: 7
        duration: 307
      - restart_id: 8
        duration: 302
      - restart_id: 9
        duration: 302
      - restart_id: 10
        duration: 304
    time_unit: s
```

### EXIT-0, 10 measures

```yaml
  - mark: exit0
    series:
      - restart_id: 1
        duration: 1
      - restart_id: 2
        duration: 13
      - restart_id: 3
        duration: 25
      - restart_id: 4
        duration: 49
      - restart_id: 5
        duration: 91
      - restart_id: 6
        duration: 161
      - restart_id: 7
        duration: 302
      - restart_id: 8
        duration: 304
      - restart_id: 9
        duration: 305
      - restart_id: 10
        duration: 308
time_unit: s
```

Regardless of the exit code, with Deployments, Kubernetes deals with a restart loop
using the same strategy.
A Pod handled by a Deployment goes into the `CrashLoopBackoff` state.
The Pod is not managed on its own. It is managed through a ReplicaSet, which in
turn is managed through a Deployment. A Deployment is a Kubernetes workload
primitive whose Pods are assumed to run indefinitely.

About this behavior, there is actually an opened request to make the
[CrashLoopBackoff timing tuneable](https://github.com/kubernetes/kubernetes/issues/57291),
at least for the cases when the process exits with zero.

Anyway, this behavior limits the number of measures we can collect and thus is
preventing us to compute decent statistics on restart timings using Deployments.

## Tested Scenarios - radosgw-restart

When we test a scenario we are interested in collecting `radosgw`'s restart
events; for each restart we measure the following metrics:

- `to_main`: this is evaluated as the duration elapsed between a `radosgw`'s
  death event and the measure at the very begin of the `main` body
  in the newly restarted process.

- `to_frontend_up`: this is evaluated as the duration elapsed between a `radosgw`'s
  death event and the measure just after the newly restarted process is
  able to accept a `TCP/IP` connection from a client.

From these 2 metrics, we produce also a derived metric: `frontend_up_main_delta`,
that is just the arithmetic difference between `to_frontend_up` and `to_main`.

For each scenario tested we collect a set of measures.
For each scenario tested we produce a set of artifacts:

- `*_stats.json`
  - It is the `json` file containing all the measures done for a scenario.
    It also contains some key statistics.

- `*_raw.svg`
  - It is the plot containing the all the charts for the measures:
    - `to_main`
    - `to_frontend_up`
    - `frontend_up_main_delta`

  On the X axis there are the restart event's `ID`s.
  They follow the temporal order of the restart events.

- `*_percentiles_to_main.svg`
  - It is the plot containing the percentile graph for the `to_main`
    metric.

- `*_percentiles_to_fup.svg`
  - It is the plot containing the percentile graph for the `to_frontend_up`
    metric.

- `*_percentiles_fup_main_delta.svg`
  - It is the plot containing the percentile graph for the `frontend_up_main_delta`
    metric.

The file name, normally, contains some information such as:

- deathtype: the way the `radosgw` process is asked to die:

  - `exit0` - the process is asked to immediately exit with `exit(0)`
  - `exit1` - the process is asked to immediately exit with `exit(1)`
  - `segfault` - the process is asked to trigger a `segmentation fault`
  - `regular` - the process is asked to exit with the ordered shutdown procedure

- environment: the environment where the scenario is tested:

  - `localhost/host-path-volume`
  - `k8s/k3d/k3s ... /host-path-volume`
  - `k8s/k3d/k3s ... /LH-volume`

- description: is a key description of the scenario
- TS: this is just a timestamp of when the artifacts were produced

### regular_localhost_zeroload_emptydb

- restart-type: `regular`
- env: `localhost/host-path-volume`
- load: `zero-empty-db`
- #measures: `100`

<!-- markdownlint-disable MD013 -->
|<img src="measurements/regular_localhost_zeroload_emptydb/regular-localhost-zeroload-emptydb_raw_1694425886.svg">|<img src="measurements/regular_localhost_zeroload_emptydb/regular-localhost-zeroload-emptydb_percentiles_to_main_1694425886.svg">|
|---|---|
|<img src="measurements/regular_localhost_zeroload_emptydb/regular-localhost-zeroload-emptydb_percentiles_to_fup_1694425886.svg">| <img src="measurements/regular_localhost_zeroload_emptydb/regular-localhost-zeroload-emptydb_percentiles_fup_main_delta_1694425886.svg">|
<!-- markdownlint-enable MD013 -->

### segfault_localhost_zeroload_emptydb

- restart-type: `segfault`
- env: `localhost/host-path-volume`
- load: `zero-empty-db`
- #measures: `100`

<!-- markdownlint-disable MD013 -->
|<img src="measurements/segfault_localhost_zeroload_emptydb/segfault-localhost-zeroload-emptydb_raw_1694428197.svg">|<img src="measurements/segfault_localhost_zeroload_emptydb/segfault-localhost-zeroload-emptydb_percentiles_to_main_1694428197.svg">|
|---|---|
|<img src="measurements/segfault_localhost_zeroload_emptydb/segfault-localhost-zeroload-emptydb_percentiles_to_fup_1694428197.svg">| <img src="measurements/segfault_localhost_zeroload_emptydb/segfault-localhost-zeroload-emptydb_percentiles_fup_main_delta_1694428197.svg">|
<!-- markdownlint-enable MD013 -->

### regular_localhost_load_fio_64_write

- restart-type: `regular`
- env: `localhost/host-path-volume`
- load: `fio`
- #measures: `100`

`fio` configuration:

```ini
[global]
ioengine=http
http_verbose=0
https=off
http_mode=s3
http_s3_key=test
http_s3_keyid=test
http_host=localhost:7480

[s3-write]
filename=/workload-1/obj1
numjobs=8
rw=write
size=64m
bs=1m
```

<!-- markdownlint-disable MD013 -->
|<img src="measurements/regular_localhost_load_fio_64_write/regular-localhost-writeload_raw_1694440297.svg">|<img src="measurements/regular_localhost_load_fio_64_write/regular-localhost-writeload_percentiles_to_main_1694440297.svg">|
|---|---|
|<img src="measurements/regular_localhost_load_fio_64_write/regular-localhost-writeload_percentiles_to_fup_1694440297.svg">| <img src="measurements/regular_localhost_load_fio_64_write/regular-localhost-writeload_percentiles_fup_main_delta_1694440297.svg">|
<!-- markdownlint-enable MD013 -->

### regular_localhost_zeroload_400_800Kdb

#### 400K objects - measures done with the WAL file zeroed

- restart-type: `regular`
- env: `localhost/host-path-volume`
- load: `zero-400K-db`
- #measures: `100`

<!-- markdownlint-disable MD013 -->
|<img src="measurements/regular_localhost_zeroload_400_800Kdb/regular-localhost-zeroload-400Kdb_raw_1694522179.svg">|<img src="measurements/regular_localhost_zeroload_400_800Kdb/regular-localhost-zeroload-400Kdb_percentiles_to_main_1694522179.svg">|
|---|---|
|<img src="measurements/regular_localhost_zeroload_400_800Kdb/regular-localhost-zeroload-400Kdb_percentiles_to_fup_1694522179.svg">| <img src="measurements/regular_localhost_zeroload_400_800Kdb/regular-localhost-zeroload-400Kdb_percentiles_fup_main_delta_1694522179.svg">|
<!-- markdownlint-enable MD013 -->

#### 800K objects - measures done with the WAL file still to be processed (size 32G)

- restart-type: `regular`
- env: `localhost/host-path-volume`
- load: `zero-800K-db`
- #measures: `100`

<!-- markdownlint-disable MD013 -->
|<img src="measurements/regular_localhost_zeroload_400_800Kdb/regular-localhost-zeroload-800Kdb_raw_1694524508.svg">|<img src="measurements/regular_localhost_zeroload_400_800Kdb/regular-localhost-zeroload-800Kdb_percentiles_to_main_1694524508.svg">|
|---|---|
|<img src="measurements/regular_localhost_zeroload_400_800Kdb/regular-localhost-zeroload-800Kdb_percentiles_to_fup_1694524508.svg">| <img src="measurements/regular_localhost_zeroload_400_800Kdb/regular-localhost-zeroload-800Kdb_percentiles_fup_main_delta_1694524508.svg">|
<!-- markdownlint-enable MD013 -->

### regular-localhost-incremental-fill-5k

- restart-type: `regular`
- env: `localhost/host-path-volume`
- load: `5K-incremental-800K-db`
- #measures: `100`

Between every restart there is an interposed `PUT-Object` sequence, each of 5K objects;
the sqlite db initially contained 800K objects.

<!-- markdownlint-disable MD013 -->
|<img src="measurements/regular-localhost-incremental-fill-5k/regular-localhost-incremental-fill-5k_raw_1694534032.svg">|<img src="measurements/regular-localhost-incremental-fill-5k/regular-localhost-incremental-fill-5k_percentiles_to_main_1694534032.svg">|
|---|---|
|<img src="measurements/regular-localhost-incremental-fill-5k/regular-localhost-incremental-fill-5k_percentiles_to_fup_1694534032.svg">| <img src="measurements/regular-localhost-incremental-fill-5k/regular-localhost-incremental-fill-5k_percentiles_fup_main_delta_1694534032.svg">|
<!-- markdownlint-enable MD013 -->

### scale_deployment_0_1-k3s3nodes_zeroload_emptydb

- restart-type: `scale_deployment_0_1`
- env: `virtual-machine/k3s-3-nodes/LH-volume`
- load: `zero-empty-db`
- #measures: `300`

The test has been conducted in 3 blocks, each of 100 restarts.
Each restart in a block is constrained to occur on a specific node.
The schema is the following:

1. taint all nodes but `node-1`
2. trigger 100 pod restarts
3. taint all nodes but `node-2`
4. trigger 100 pod restarts
5. taint all nodes but `node-3`
6. trigger 100 pod restarts

<!-- markdownlint-disable MD013 -->
|<img src="measurements/scale_deployment_0_1-k3s3nodes-zeroload-emptydb/scale_deployment_0_1-k3s3nodes-zeroload-emptydb_raw_1695046129.svg">|<img src="measurements/scale_deployment_0_1-k3s3nodes-zeroload-emptydb/scale_deployment_0_1-k3s3nodes-zeroload-emptydb_percentiles_to_main_1695046129.svg">|
|---|---|
|<img src="measurements/scale_deployment_0_1-k3s3nodes-zeroload-emptydb/scale_deployment_0_1-k3s3nodes-zeroload-emptydb_percentiles_to_fup_1695046129.svg">| <img src="measurements/scale_deployment_0_1-k3s3nodes-zeroload-emptydb/scale_deployment_0_1-k3s3nodes-zeroload-emptydb_percentiles_fup_main_delta_1695046129.svg">|
<!-- markdownlint-enable MD013 -->

## Tested Scenarios - S3-workload during s3gw Pod outage

These scenarios are focused in collecting data from an S3 client performing
a workload during an s3gw outage.
For each S3 operation we collect both its Round Trip Time - `RTT` - and its
`result` (success/failure).
Then, we correlate an s3gw's outage with collected results and RTTs.

For each scenario tested we produce a specific artifact:

- `*_S3WL_RTT_raw.svg`
  - It is the plot containing the `RTT S3Workload` chart:

    - **X-Axis**: Relative time (starting from 0) when an S3 operation occurred.
    - **Y-Axis**: The `RTT`'s duration in milliseconds.
    - Each vertical bar is colorized in: `Green` when the corresponding S3 operation
      was successful, in `Red` when the operation failed.
    - On the **X-Axis**, in `Yellow`, are drawn all the s3gw's outages occurred
      in the test; the segment represents the begin and the end of an outage.
    - On the **X-Axis**, in `Cyan`, are drawn the durations before
      the first successful S3 operation after an outage.

### PutObj-100ms-ClusterIp

- restart-type: `regular`
- env: `k3d/host-path-volume`
- client-S3-workload: `PutObject/100ms`
- S3-endpoint: `s3gw-ClusterIP-service`
- #restarts: `10`
- #S3-operations: `394`

<!-- markdownlint-disable MD013 -->
|<img src="measurements/s3wl-putobj-100ms-clusterip/1695396383_s3wl-putobj-100ms-ClusterIp_S3WL_RTT_raw.svg">|<img src="measurements/s3wl-putobj-100ms-clusterip/1695396383_s3wl-putobj-100ms-ClusterIp_raw.svg">|
|---|---|
<!-- markdownlint-enable MD013 -->

### PutObj-100ms-Ingress

- restart-type: `regular`
- env: `k3d/host-path-volume`
- client-S3-workload: `PutObject/100ms`
- S3-endpoint: `s3gw-Ingress`
- #restarts: `10`
- #S3-operations: `504`

<!-- markdownlint-disable MD013 -->
|<img src="measurements/s3wl-putobj-100ms-ingress/1695396145_s3wl-putobj-100ms-Ingress_S3WL_RTT_raw.svg">|<img src="measurements/s3wl-putobj-100ms-ingress/1695396145_s3wl-putobj-100ms-Ingress_raw.svg">|
|---|---|
<!-- markdownlint-enable MD013 -->
