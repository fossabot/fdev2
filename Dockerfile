# GNU GCC & other Libraries ontop of CentOS

#Compile any tools we cannot install from packages
FROM tafthorne/make-devtoolset-7-toolchain-centos7 as builder
USER 0
ADD https://github.com/cpputest/cpputest/releases/download/v3.8/cpputest-3.8.tar.gz /tmp/
RUN \
  yum install -y \
    automake \
    autoconf \
    clang \
    git \
    libc++-dev \
    libgflags-dev \
    libgtest-dev \
    libtool
RUN \
  # CppUTest
  cd /tmp && tar -xf cpputest-3.8.tar.gz && cd cpputest-3.8/cpputest_build && \
  autoreconf .. -i && ../configure && make && make check && make install && \
  cd /tmp && rm -r cpputest-3.8
RUN \
  # Protocol Buffer & gRPC
  # install protobuf first, then grpc
  git clone -b $(curl -L https://grpc.io/release) \
      https://github.com/grpc/grpc /var/local/git/grpc && \
    cd /var/local/git/grpc && \
    git submodule update --init && \
    echo "--- installing protobuf ---" && \
    cd third_party/protobuf && \
    ./autogen.sh && ./configure --enable-shared && \
    make -j$(nproc) && make install && make clean && ldconfig


# Put the main image together
FROM tafthorne/make-devtoolset-7-toolchain-centos7
LABEL \
 Description="Basic gcc CentOS environment with a number of libraries configured" \
 MAINTAINER="Thomas Thorne <TafThorne@GoogleMail.com>"
USER 0
# Copy over pre-made tools
# CppUTest
COPY --from=builder /usr/local/include/CppUTest /usr/local/include/CppUTest
COPY --from=builder /usr/local/include/CppUTestExt /usr/local/include/CppUTestExt
COPY --from=builder /usr/local/lib/libCppUTest*.a /usr/local/lib/
COPY --from=builder /usr/local/lib/pkgconfig/cpputest.pc /usr/local/lib/pkgconfig/
# Protocol Buffer
COPY --from=builder /usr/local/lib/libproto* /usr/local/lib/
COPY --from=builder /usr/local/bin/protoc /usr/local/bin/
COPY --from=builder /usr/local/include/google/protobuf /usr/local/include/google/protobuf
# Install remaining tools using yum
ADD http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm /tmp/
RUN \
  cd /tmp && rpm -Uvh epel-release*rpm && \
  yum install -y \
    cppcheck \
    hdf5-devel \
    lcov \
    libwebsockets-devel \
    spdlog-devel \
    websocketpp \
    libuuid-devel
USER 1001

