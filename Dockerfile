# Build stage
FROM alpine:latest as build

# Define version args
ARG SRT_VERSION=v1.5.3
ARG SLS_VERSION=master

# Install build dependencies
RUN apk update
RUN apk upgrade
RUN apk add --no-cache \
  linux-headers \
  alpine-sdk \
  cmake \
  tcl \
  openssl-dev \
  zlib-dev

# Clone projects
WORKDIR /source
RUN git clone --branch ${SRT_VERSION} https://github.com/Haivision/srt.git srt
RUN git clone --branch ${SLS_VERSION} https://github.com/irlserver/irl-srt-server.git sls

# Compile SRT
WORKDIR /source/srt
RUN ./configure
RUN make install

# Compile SLS
WORKDIR /source/sls
RUN git submodule update --init
RUN cmake . -DCMAKE_BUILD_TYPE=Release
RUN make -j8

# Entry image
FROM alpine:latest

# Setup runtime
ENV LD_LIBRARY_PATH /lib:/usr/lib:/usr/local/lib64
RUN apk update && \
    apk upgrade && \
    apk add --no-cache openssl libstdc++ && \
    adduser -D srt && \
    mkdir /etc/sls /logs && \
    chown srt /logs

# Copy SRT libraries
COPY --from=build /usr/local/bin/srt-* /usr/local/bin/
COPY --from=build /usr/local/lib/libsrt* /usr/local/lib/

# Copy SLS binary
COPY --from=build /source/sls/bin/* /usr/local/bin/
COPY sls.conf /etc/sls/

# Use non-root user
USER srt
WORKDIR /home/srt

# Define entrypoint
VOLUME /logs
EXPOSE 8080 8181 1935/udp 1936/udp
ENTRYPOINT [ "srt_server", "-c", "/etc/sls/sls.conf"]
