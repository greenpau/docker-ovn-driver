FROM centos:latest

RUN yum -y install openssl python-six iproute python-flask \
    python-ipaddress socat bind-utils tcpdump nmap-ncat \
    traceroute net-tools iperf3 tshark conntrack-tools unbound
RUN curl -s https://bootstrap.pypa.io/get-pip.py | python && pip install docker
COPY rpms/*.rpm /usr/src/openvswitch/
RUN rpm -ivh /usr/src/openvswitch/*.rpm
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY docker-ovn-driver /usr/bin/docker-ovn-driver
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/docker-entrypoint.sh", "-h"]
