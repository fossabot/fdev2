# GNU GCC & other Libraries

FROM tafthorne/make-devtoolset-7-toolchain-centos7
LABEL \
 Description="Basic gcc CentOS environment with a number of libraries configured" \
 MAINTAINER="Thomas Thorne <TafThorne@GoogleMail.com>"
USER 0
RUN yum install -y \
  spdlog-devel
USER 1001

