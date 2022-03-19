FROM centos:7

RUN yum install -y epel-release
RUN yum install -y python-pip python3 python3-pip python3-devel policycoreutils selinux-policy-targeted sudo gcc
RUN pip3 install --upgrade pip
RUN LC_ALL=en_US.UTF-8 pip3 install ansible ansible-lint==5.4.0  yamllint
RUN pip2 install pexpect

RUN useradd vagrant
RUN echo 'vagrant:vagrant' | chpasswd
RUN echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER vagrant
WORKDIR /usr/local/src/ansible
