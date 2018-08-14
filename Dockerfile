# GNU GCC & other Libraries

#Compile any tools we cannot install from packages
FROM tafthorne/make-devtoolset-7-toolchain-centos7 as builder
USER 0
ADD https://github.com/cpputest/cpputest/releases/download/v3.8/cpputest-3.8.tar.gz /tmp/
RUN \
  yum install -y \
    automake \
    autoconf \
    libtool
RUN \
  # CppUTest
  cd /tmp && tar -xf cpputest-3.8.tar.gz && cd cpputest-3.8/cpputest_build && \
  autoreconf .. -i && ../configure && make && make check && make install && \
  cd /tmp && rm -r cpputest-3.8

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

