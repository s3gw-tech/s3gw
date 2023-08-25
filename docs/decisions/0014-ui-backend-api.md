# s3gw-ui backend API

## Using POST instead of GET for some operations

While we should strive to ensure that we are compliant with the RESTful API
paradigm, in some instances this is not viable.

One such instance is when we have a lot of information that needs to be provided
to the API during a GET call. In such a situation it would make sense to rely on
the GET request's body to pass the additional context we need, but unfortunately
browsers tend to drop the body for GET requests before sending the request to
the server ([1] [2] [3]).

We are left with one of the following options:

1. Pass all the information we need as query parameters during the GET call
2. Pass additional parameters in the HTTP request's headers
3. Use another operation, instead of GET, to pass the additional information to
   the server in the request's body.

The first approach has the downside that we are limited to a predefined hard
limit of characters in the URL, which is browser dependent. For instance, Chrome
is limited to 2083 characters, while Firefox is limited to 65536 characters. We
must thus assume the lower bound, being effectively limited to 2083 characters.

Given some operations require object names to be provided, and given S3 object
names may have up to 1024 characters, we become slightly limited in the number
of remaining characters available for additional parameters. Additionally, the
S3 protocol allows object names to contain certain characters that are
considered reserved for URLs, meaning we would have to URL-encode them, putting
additional pressure on the limit we have already established. In the worst case
scenario, an object name composed solely of reserved characters would take three
times as many characters after being URL-encoded than its original form. That by
itself is more than the available characters we have for a URL if the object has
the maximum number of allowed characters of 1024.

The second approach, we believe, is less obvious. Could we pass these values as
HTTP headers? We think so. But we find that ugly and not at all obvious. It
would mean passing potentially huge payloads in the header, and that's the bit
we find ugly; it's not obvious because headers are not exactly the first place
one would think to look into for large payloads.

We are thus left with the third option. By using a different operation for which
the request's body is not stripped away, we can provide as much context as we
want or need to the server, with little to no modification of the original
payload.

Therefore, we have chosen to use POST operations for selected operations that
are semantically the equivalent to a GET operation. This breaks the RESTfulness
of our API for some operations, but we believe this to be a reasonable tradeoff.

[1]: https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/send
[2]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/GET
[3]: https://xhr.spec.whatwg.org/#the-send()-method
