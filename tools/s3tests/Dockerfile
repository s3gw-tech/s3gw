FROM python:3.10-alpine
WORKDIR /s3tr

ARG S3TESTS_REF=73b340a0e2042d48753f16e0c9bc050040af27cc
ARG S3TESTS_SHA256SUM=bdc0f0c8c3fa9ce8e850de0f422c5b781ab24518da51e37c39fb1c54ebd22e1f

# Install S3-tests
RUN apk add -u wget unzip \
 && wget --quiet https://github.com/ceph/s3-tests/archive/${S3TESTS_REF}.zip \
 && ( echo "${S3TESTS_SHA256SUM} ${S3TESTS_REF}.zip" | sha256sum -c ) \
 && unzip ${S3TESTS_REF}.zip \
 && rm ${S3TESTS_REF}.zip

# Used by s3tr to find s3-tests
ENV S3TESTS=/s3tr/s3-tests-${S3TESTS_REF}
ENV PYTEST_INI=/s3tr/s3-tests-${S3TESTS_REF}/pytest.ini
ENV DATASETTE_METADATA=/s3tr/metadata.yml
ENV PATH="${PATH}:/usr/local/bin"

COPY requirements.txt /s3tr/
RUN pip install --no-cache-dir -r "/s3tr/s3-tests-${S3TESTS_REF}/requirements.txt" \
 && pip install --no-cache-dir -r "/s3tr/requirements.txt" \
 && find /usr/local/lib -name '__pycache__' | xargs rm -r \
 && rm -rf /root/.cache/pip

COPY ["analyze.py", "runner.py", "s3tr.py", "to_sqlite.py", "metadata.yml", "/s3tr/"]

EXPOSE 8080
ENTRYPOINT [ "python3", "./s3tr.py" ]
