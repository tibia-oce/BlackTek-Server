FROM ubuntu:22.04 AS dependencies
ENV VCPKG_FORCE_SYSTEM_BINARIES=1
ENV VCPKG_ROOT=/bts/vcpkg

RUN apt update && apt install -y \
    unzip \
    make \
    g++ \
    uuid-dev \
    wget \
    curl \
    zip \
    tar \
    git \
    pkg-config \
    cmake \
    ninja-build \
    python3 && \
    mkdir /bts && \
    cd /bts/ && wget https://github.com/premake/premake-core/archive/refs/heads/master.zip && \
    cd /bts/ && unzip master.zip && rm master.zip && \
    cd /bts/premake-core-master && make -f Bootstrap.mak linux && \
    mv /bts/premake-core-master/bin/release/premake5 /bin/premake5 && \
    rm -rf /bts/premake-core-master/bin/release/premake5

RUN apt install -y curl zip unzip tar git && \
    cd /bts && git clone https://github.com/microsoft/vcpkg.git && \
    /bts/vcpkg/bootstrap-vcpkg.sh

COPY src /usr/src/bts/src/
COPY premake5.lua vcpkg.json /usr/src/bts/

WORKDIR /usr/src/bts
RUN apt install -y pkg-config
RUN cd /usr/src/bts && /bts/vcpkg/vcpkg install
RUN premake5 gmake2 && make -j 2 config=release_arm64

FROM ubuntu:22.04 AS final
COPY --from=dependencies /usr/src/bts/Black-Tek-Server /app/Black-Tek-Server
COPY data /app/data
COPY *.sql key.pem /app/
COPY config.lua.dist /app/config.lua

RUN groupadd -r btsuser && \
    useradd -r -g btsuser -d /app -s /sbin/nologin btsuser && \
    chmod +x /app/Black-Tek-Server && \
    chown -R btsuser:btsuser /app

USER btsuser
WORKDIR /app
ENTRYPOINT ["./Black-Tek-Server"]
