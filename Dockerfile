# GNU GCC & other Libraries

FROM tafthorne/make-devtoolset-7-toolchain-centos7
LABEL \
 Description="Basic gcc CentOS environment with a number of libraries configured" \
 MAINTAINER="Thomas Thorne <TafThorne@GoogleMail.com>"
USER 0
ADD http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm /tmp/
RUN \
  cd /tmp && rpm -Uvh epel-release*rpm && \
  yum install -y \
    cppcheck \
    lcov \
    spdlog-devel
USER 1001

