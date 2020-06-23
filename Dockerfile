FROM debian:buster as build

# Define build environment
ENV LD_LIBRARY_PATH /usr/local/lib

# Install build dependencies
RUN apt-get update && apt-get install -y \
  tclsh \
  pkg-config \
  cmake \
  libssl-dev \
  zlib1g-dev \
  build-essential \
  git

# Define version args
ARG SRT_VERSION=v1.4.1
ARG SLS_VERSION=V1.4.8

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
FROM debian:buster
WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
  tclsh \
  libssl-dev \
  zlib1g-dev && \
  rm -rf /var/lib/apt/lists/*

# Copy SRT library
ENV LD_LIBRARY_PATH /usr/local/lib
COPY --from=build /usr/local/lib/* /usr/local/lib/

# Copy binaries
COPY --from=build /source/sls/bin/sls .
COPY --from=build /source/sls/bin/slc .
COPY --from=build /source/sls/sls.conf .

EXPOSE 8080
ENTRYPOINT ["/app/sls"]
