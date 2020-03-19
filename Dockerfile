FROM alpine:latest

WORKDIR /app

# Install requirements
RUN apk --no-cache add ca-certificates \
    git \
    tcl \
    pkgconfig \
    cmake \
    libressl-dev \
    zlib-dev \
    alpine-sdk

# Build SRT
RUN git clone -b v1.4.1 https://github.com/Haivision/srt && \
    cd srt/ && \
    ls && \
    ./configure && \
    make && \
    make install && \ 
    cd ..

# Build srt-live-server
RUN git clone -b v1.4.4 https://github.com/Edward-Wu/srt-live-server.git && \
    cd srt-live-server/ && \
    make && \
    cd ..

# Cleanup
RUN cp srt-live-server/bin/sls . && \
    rm -r srt/ srt-live-server/

CMD ./sls -c ../sls.conf
