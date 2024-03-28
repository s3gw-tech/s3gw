# s3gw High Availability model

## Context and Problem Statement

We analyzed some High Availability - HA - concepts applied to the s3gw when used with Longhorn.
The final aim of the research is to identify an HA model we can reasonably rely on.

The full and initial HA research document can be found here:
[High Availability research](../research/ha/RATIONALE).
You can find there all the rationales, motivations and the details about the tests performed.

## Considered Options

We identified 3 HA models:

- **Active/Active** (multiple s3gw instances concurrently serving the same data)
- **Active/Warm Standby** (multiple s3gw instances, one serving data, others able to take over if active instance fails)
- **Active/Standby** (single s3gw instance, with Kubernetes restarting/redeploying as necessary on failure)

## Decision Outcome

The 3 aforementioned models have different performances and different implementation efforts.
For our use case, the *Active/Standby* model built on top of Longhorn actually makes
the most sense and brings the "best" HA characteristics relative to implementing a
more fully active/distributed solution.

List of *desirable* characteristics owned by the *Active/Standby* model

- Simplicity
- Low implementation effort in respect to the other models
- Expected to work mainly with Kubernetes primitives
- Compatible with RWO persistent volume semantics
- Acceptable restart timings on switch-overs and fail-overs (excluding the non-graceful node failure)

Be aware that the [non-graceful node failure](../research/ha/RATIONALE#non-graceful-node-failure)
problem cannot be entirely solved with the *Active/Standby* model alone.
Regarding this, we have opened a [dedicated issue](https://github.com/longhorn/longhorn/issues/6803)
within the Longhorn project.

For a more comprehensive explanation about this choice, please refer to the original
[High Availability research](https://github.com/aquarist-labs/s3gw/pull/685) pull request.
