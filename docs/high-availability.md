# High Availability with s3gw and Longhorn

The s3gw mainly relies on Kubernetes and Longhorn to achieve High Availability (HA).

A single s3gw instance is attached to its private Longhorn-provided persistent
volume (PV) with Kubernetes restarting/redeploying as necessary on failure.

In the context of the s3gw and Longhorn, this HA model is called: *Active/Standby*.

The PV's state is guaranteed by Longhorn ensuring that a PV, along with
its content, will always be available on all cluster nodes.
This means that the s3gw can mount its Longhorn PV regardless of the
current scheduling on the cluster.

Obviously, the s3gw can't achieve higher availability or reliability than
the underlying Longhorn volumes.
This means that any corruption should occur in the file system is outside what
s3gw can reasonably protect against; that's all undefined behavior and "restore
from backup" time.

The *Active/Standby* model claims the following characteristics:

- Simplicity
- Compatible with RWO persistent volume semantics
- Acceptable restart timings on switch-overs and fail-overs
  (excluding the non-graceful node failures, [see below](#non-graceful-node-failure))

With the current s3gw's implementation we expect to solve mainly the following
failure scenarios:

- s3gw pod failure: this scenario occurs when the s3gw stops due to an error in
  the backend pod.

- s3gw pod rescheduling: this case applies when Kubernetes decides to reschedule
  the pod to another node, eg: when the node goes low on resources. This would often
  be called a "switch-over" in an HA cluster - e.g., an administratively orchestrated
  transition of the service to a new node (say, for maintenance/upgrade/etc reasons).
  This has the advantage of being schedulable, so it can happen at times of low load
  if these exist.

When any of these scenarios should happen, Kubernetes restarts the s3gw pod and we
expect the service to be restored in seconds.

## Non-graceful node failure

Currently, Kubernetes ([1.28](https://kubernetes.io/releases/) at the time of
writing this), does not automatically restart a pod attached to a RWO volume
in the event that the node running it suffers a failure.
Reasons behind this behavior is that workloads, such as RWO volumes require
*at-most-one* semantics.
Failures affecting these kind of workloads risk data loss and/or corruption
if nodes (and the workloads running on them) are wrongly assumed to be dead.
For this reason it is crucial to know that the node has reached a safe state
before initiating recovery of the workload.

Longhorn offers the option to perform a [Pod Deletion Policy][pod-deletion-policy]
when a node should go down unexpectedly.
This means that Longhorn will force delete StatefulSet/Deployment terminating pods
on nodes that are down to release Longhorn volumes so that Kubernetes
can spin up replacement pods.

Anyway, when employing this mitigation, the user must be aware that assuming a node
dead could lead to data loss and/or corruption if that assumption was actually untrue.

The s3gw and the Longhorn team is currently investigating some
[hypotheses of solutions][longhorn-issue-1]
to address this problem at its roots.

[pod-deletion-policy]: https://longhorn.io/docs/1.5.1/references/settings/#pod-deletion-policy-when-node-is-down
[longhorn-issue-1]: https://github.com/longhorn/longhorn/issues/6803
