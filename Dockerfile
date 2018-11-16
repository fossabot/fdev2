# GNU GCC & other Libraries ontop of CentOS

# Setup basic image for tool complilation to take place in
FROM tafthorne/make-devtoolset-7-toolchain-centos7 as base
USER 0
RUN \
  yum install -y epel-release && \
  yum install --setopt=skip_missing_names_on_install=False -y \
    git \
    gflags \
    which

# Compile any tools we cannot install from packages
FROM base as builder
ADD https://github.com/cpputest/cpputest/releases/download/v3.8/cpputest-3.8.tar.gz /tmp/
RUN \
  yum install -y epel-release && \
  yum --setopt=skip_missing_names_on_install=False install -y \
    automake \
    autoconf \
    clang \
    gflags-devel \
    gtest-devel \
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
    make -j$(nproc) && make install && make clean && ldconfig && \
    echo "--- installing grpc ---" && \
    cd /var/local/git/grpc && \
    make -j$(nproc) && make install && make clean && ldconfig && \
    make -j$(nproc) grpc_cli

# Put the main image together
FROM base
LABEL \
 Description="Basic gcc CentOS environment with a number of libraries configured" \
 MAINTAINER="Thomas Thorne <TafThorne@GoogleMail.com>"
ARG prefix=/usr
ARG binPath=$prefix/bin
ARG includePath=$prefix/include
ARG libPath=$prefix/lib
ARG pkgconfigPath=/usr/share/pkgconfig
USER 0
# Copy over pre-made tools
# CppUTest
COPY --from=builder /usr/local/include/CppUTest $includePath/CppUTest
COPY --from=builder /usr/local/include/CppUTestExt includePath/CppUTestExt
COPY --from=builder /usr/local/lib/libCppUTest*.a $libPath/
COPY --from=builder /usr/local/lib/pkgconfig/cpputest.pc $pkgconfigPath/
RUN sed -i 's/\/usr\/local/\/usr/g' $pkgconfigPath/cpputest.pc
# Protocol Buffer
COPY --from=builder /usr/local/bin/protoc $binPath/
COPY --from=builder /usr/local/include/google/protobuf $includePath/google/protobuf
COPY --from=builder /usr/local/lib/libproto* $libPath/
COPY --from=builder /usr/local/lib/pkgconfig/protobuf*.pc $pkgconfigPath/
RUN sed -i 's/\/usr\/local/\/usr/g' $pkgconfigPath/protobuf*.pc
# gRPC
COPY --from=builder /usr/local/bin/grpc_* $binPath/
COPY --from=builder /usr/local/include/grpc $includePath/grpc
COPY --from=builder /usr/local/include/grpc++ $includePath/grpc++
COPY --from=builder /usr/local/include/grpcpp $includePath/grpcpp
COPY --from=builder /usr/local/lib/libaddress_sorting.so.6.0.0 $libPath/
COPY --from=builder /usr/local/lib/libgpr* $libPath/
COPY --from=builder /usr/local/lib/libgrpc* $libPath/
COPY --from=builder /usr/local/lib/pkgconfig/gpr.pc $pkgconfigPath/
COPY --from=builder /usr/local/lib/pkgconfig/grpc*.pc $pkgconfigPath/
RUN sed -i 's/\/usr\/local/\/usr/g' $pkgconfigPath/grp*.pc && ldconfig
# grpc_cli
COPY --from=builder /var/local/git/grpc/bins/opt/grpc_cli $binPath/
# Install remaining tools using yum
RUN \
  yum --setopt=skip_missing_names_on_install=False install -y \
    cppcheck \
    hdf5-devel \
    lcov \
    uuid-devel \
    spdlog-devel \
    valgrind \
    libwebsockets
USER 1001

