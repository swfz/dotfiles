FROM centos:7

RUN yum install -y python2-setuptools policycoreutils selinux-policy-targeted
RUN easy_install pip
RUN yum install -y gcc python2-devel
RUN pip install ansible ansible-lint yamllint

WORKDIR /usr/local/src/ansible
