FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    procps coreutils util-linux \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY src/ /work/src/
RUN chmod +x /work/src/*.sh

ENTRYPOINT ["/bin/bash"]

