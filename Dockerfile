# Build stage
FROM alpine:latest as build

# Define version args
ARG SRT_VERSION=v1.4.1
ARG SLS_VERSION=V1.4.8

# Install build dependencies
RUN apk update
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
RUN git clone --branch ${SLS_VERSION} https://github.com/Edward-Wu/srt-live-server.git sls

# Compile SRT
WORKDIR /source/srt
RUN ./configure
RUN make install

# Compile SLS
WORKDIR /source/sls
RUN make

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
COPY --from=build /usr/local/lib64/libsrt* /usr/local/lib64/

# Copy SLS binary
COPY --from=build /source/sls/bin/* /usr/local/bin/
COPY sls.conf /etc/sls/

# Use non-root user
USER srt
WORKDIR /home/srt

# Define entrypoint
VOLUME /logs
EXPOSE 1935/udp
ENTRYPOINT ["sls", "-c", "/etc/sls/sls.conf"]
