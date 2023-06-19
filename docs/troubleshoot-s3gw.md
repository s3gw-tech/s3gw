
# Troubleshooting the s3w

When using self-signed certificates, you may encounter CORS issues
accessing the UI. This can be worked around by first accessing the S3 endpoint
itself `https://hostname` with the browser and accepting that certificate,
before accessing the UI via `https://ui.hostname`

```bash
cat certificate.pem | base64 -w 0
```
