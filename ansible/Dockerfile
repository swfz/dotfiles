FROM centos:7

RUN yum install -y python2-setuptools policycoreutils selinux-policy-targeted sudo
RUN easy_install pip
RUN yum install -y gcc python2-devel
RUN pip install ansible ansible-lint yamllint

RUN useradd vagrant
RUN echo 'vagrant:vagrant' | chpasswd
RUN echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER vagrant
WORKDIR /usr/local/src/ansible
