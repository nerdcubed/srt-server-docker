FROM debian:buster as build

# Define version args
ARG SRT_VERSION=v1.4.1
ARG SLS_VERSION=v1.4.5

# Install build dependencies
WORKDIR /app
RUN apt-get update && apt-get install -y \
  tclsh \
  pkg-config \
  cmake \
  libssl-dev \
  zlib1g-dev \
  build-essential \
  git

# Compile SRT
RUN git clone --branch ${SRT_VERSION} https://github.com/Haivision/srt.git srt && \
  cd srt && \
  ./configure && \
  make install && \
  cd ..

# Compile SLS
ENV LD_LIBRARY_PATH /usr/local/lib
RUN git clone --branch ${SLS_VERSION} https://github.com/Edward-Wu/srt-live-server.git sls && \
  cd sls && \
  make && \
  cd ..

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
COPY --from=build /usr/local/lib/libsrt.so.1 /usr/local/lib/libsrt.so.1

# Copy binaries
COPY --from=build /app/sls/bin/sls .
COPY --from=build /app/sls/bin/slc .
COPY --from=build /app/sls/sls.conf .

ENTRYPOINT ["/app/sls"]
