FROM centos:7

RUN yum install -y python3 python3-pip python3-devel policycoreutils selinux-policy-targeted sudo gcc
RUN pip3 install ansible ansible-lint yamllint

RUN useradd vagrant
RUN echo 'vagrant:vagrant' | chpasswd
RUN echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER vagrant
WORKDIR /usr/local/src/ansible
