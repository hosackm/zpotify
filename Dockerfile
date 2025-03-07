FROM ubuntu:latest

# Setup Zig
RUN apt update -y && apt install -y wget xz-utils gdb
RUN wget -q https://ziglang.org/download/0.13.0/zig-linux-aarch64-0.13.0.tar.xz && \
    tar -xvf zig-linux-aarch64-0.13.0.tar.xz && \
    rm zig-linux-aarch64-0.13.0.tar.xz && \
    ln -s /zig-linux-aarch64-0.13.0/zig /usr/local/bin

COPY . /app
