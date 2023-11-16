# Advanced usage

The processes and steps described in this page should not be applicable to the
vast majority of s3gw deployments. However, depending on circumstance, one might
need to perform some of these for testing or debugging.

The following sections rely on `podman` for examples. Using `docker` instead
should work in the same way, although option names may need to be adjusted on
occasion.

## Running the container

One might need to run the container standalone, in which case it's important to
understand how to properly configure it. Running the container with `--help`
will provide some insight.

`podman run -it quay.io/s3gw/s3gw:latest --help`

Which should result in something like the following, minus eventual changes not
reflected in this example:

    usage: /s3gw/bin/entrypoint.sh [options... -- args]

    options:
    --help                Shows this message.
    --id ID               Specifies a custom instance ID (default: s3gw).
    --cert FILE KEY       Specifies SSL certificate. Expects a .crt as first
                          argument, and a .key as second argument.
    --dns-name VALUE      For vhost style buckets, VALUE should be the DNS domain
                          to be used.
    --debug LEVEL         Runs with debug. Levels available: "high", "medium",
                          "low", "none" (default: none).
    --no-telemetry        Disable telemetry.
    --telemetry-url URL   Specifies telemetry URL.
    --with-status         Enables status frontend at port 9090.

    args:
    Any option supported by RADOS Gateway. For advanced use only.

    env variables:
    S3GW_ID           Specifies a custom instance ID.
    S3GW_DNS_NAME     Specifies a DNS domain to be used for vhost style buckets.
    S3GW_DEBUG        Specifies the debug level to be used.
    S3GW_CERT_FILE    Specifies the SSL certificate file.
    S3GW_CERT_KEY     Specifies the SSL certificate key file.

Keep in mind that to access the service, one needs to expose the required ports.
For s3gw these are port 7480 for non-SSL access, and port 7481 for SSL access.
This can be achieved with:

`podman run -it -p 7480:7480 quay.io/s3gw/s3gw:latest`

In the following sections, we will be describing some of the available options.

### Using vhost style buckets

S3 supports two styles of bucket access: path and vhost. The former considers
the buckets will be part of the address path, like in `my.domain.tld/my-bucket/`,
whereas the latter assumes the bucket will be part of the vhost,
`my-bucket.my.domain.tld`.

By default, s3gw runs with path style buckets. One can enable vhost style
buckets by providing the DNS domain name to be used for the service. For
example,

    podman run -it -p 7480:7480 \
        quay.io/s3gw/s3gw:latest \
        --dns-name my.domain.tld

### Specifying certificates

s3gw supports running with SSL, but will require a certificate to be provided.
The location of this certificate must be local to the container namespace, and
thus should be bind mounted into the container.

    podman run -it -p 7481:7481 \
        -v ./my-cert.crt:/data/my-cert.crt \
        -v ./my-cert.key:/data/my-cert.key \
        quay.io/s3gw/s3gw:latest \
        --cert /data/my-cert.crt /data/my-cert.key

The s3gw service should now be available on the host's port 7481 with SSL
enabled.

### Debugging output

s3gw supports four different log levels: `none`, `low`, `medium`, and `high`. By
default, s3gw runs with `none`.

The vast majority of deployments will only require `none` or `low`, for as long
as they are behaving nicely. In case of misbehavior, it is reasonable to look
towards the logs for indication of what the problem might be. In this case, the
typical deployment will rely on `medium`. Only in very exceptional situations
will a `high` be useful. Keep in mind that at a `high` debug level, the system
will be put under a lot of strain from the amount of outputted messages, and the
value of additional verbosity may not be significant.

Running with debug only requires specifying the `--debug LEVEL` argument to the
container, such as

    podman run -it -p 7480:7480 \
        quay.io/s3gw/s3gw:latest \
        --debug medium

### Environment variables

The available environment variables reflect the arguments accepted by the
container. These can be provided to the container using the `--env VAR=VALUE`
argument to `podman run`. For example,

    podman run -it -p 7480:7480 \
        --env S3GW_DEBUG=medium \
        quay.io/s3gw/s3gw:latest

### Additional arguments

The container accepts additional arguments, that will be passed directly to the
underlying RADOS Gateway binary. These should be used only if one knows what
they are doing. To obtain a small subset of the option supported, running with
`-- --help` will provide some information. Please note that not all the options
provided in this help message will be applicable.
