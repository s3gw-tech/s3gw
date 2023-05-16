FROM python:3.10-alpine
WORKDIR /s3tr

# Install s3-tests master branch
#RUN apt-get update && apt-get -y install --no-install-recommends wget unzip \
RUN apk add -u wget unzip \
    && wget --quiet https://github.com/ceph/s3-tests/archive/refs/heads/master.zip \
    && ( echo "95530ce236fcea0a8b6776f1dae786dd4f1d22fe35da23b48353c70580c928d7 master.zip" | sha256sum -c ) \
    && unzip master.zip \
    && rm master.zip

# Used by s3tr to find s3-tests
ENV S3TESTS=/s3tr/s3-tests-master
ENV PYTEST_INI=/s3tr/s3-tests-master/pytest.ini
ENV DATASETTE_METADATA=/s3tr/metadata.yml
ENV PATH="${PATH}:/usr/local/bin"

COPY requirements.txt /s3tr/
RUN pip install --no-cache-dir -r "/s3tr/s3-tests-master/requirements.txt" \
    && pip install --no-cache-dir -r "/s3tr/requirements.txt" \
    && find /usr/local/lib -name '__pycache__' | xargs rm -r \
    && rm -rf /root/.cache/pip

COPY ["analyze.py", "runner.py", "s3tr.py", "to_sqlite.py", "metadata.yml", "/s3tr/"]

EXPOSE 8080
ENTRYPOINT [ "python3", "./s3tr.py" ]
