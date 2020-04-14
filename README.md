# docker-ovn-driver

Docker Plugin v2 Network Driver for Open Virtual Network (OVN).

[![OVN Network Driver Operations](https://raw.githubusercontent.com/forward53/docker-ovn-driver/master/docs/images/forward53.docker-ovn-driver.diagram.png "OVN Network Driver Operations")](https://raw.githubusercontent.com/forward53/docker-ovn-driver/master/docs/images/forward53.docker-ovn-driver.diagram.png)

## Getting Started

### Install the driver from Docker Hub

First, install the driver:

```bash
docker plugin install forward53/docker-ovn-driver --disable --grant-all-permissions
latest: Pulling from forward53/docker-ovn-driver
cf67279099ab: Download complete
Digest: sha256:0fafc210877961449d790b63e0ba61ffa2cda7c999acb102790903d642199455
Status: Downloaded newer image for forward53/docker-ovn-driver:latest
Installed plugin forward53/docker-ovn-driver
```

Validate that the driver is installed but disables:

```bash
docker plugin ls
ID                  NAME                                DESCRIPTION                                     ENABLED
759fb140951d        forward53/docker-ovn-driver:latest   Docker network driver for Open Virtual Net...   false
```

Next, if necessary, enable debugging:

```bash
docker plugin set forward53/docker-ovn-driver DEBUG=1
```

Finally, enable the driver:

```bash
docker plugin enable forward53/docker-ovn-driver
```

Validate that the driver is installed and enabled:

```bash
docker plugin ls
ID                  NAME                                DESCRIPTION                                     ENABLED
759fb140951d        forward53/docker-ovn-driver:latest   Docker network driver for Open Virtual Net...   true
```

### Install the driver from source

The following command builds, installs, and enabled the driver locally, i.e. without a registry:

```bash
sudo make plugin
```

## Create a network

Create a network with the networking maintained by `forward53/docker-ovn-driver` network driver:

```bash
docker network create -d forward53/docker-ovn-driver:latest --subnet=10.10.10.0/23 --gateway=10.10.10.1 --ip-range 10.10.10.32/27 --opt vrf=default public
```

Next, a user may place a container on the network:

```
docker run -d -t --net=public --name=box1 centos
```

## Uninstall the driver

The following commands disable and remove the driver:

```bash
docker plugin disable forward53/docker-ovn-driver
docker plugin rm forward53/docker-ovn-driver
```

Alternatively, when having access to the source, run the following command:

```bash
sudo make clean
```

## Troubleshooting

The first step in troubleshooting is reviewing `docker` logs:

```bash
journalctl -u docker -r --no-pager -n 20
```

Next, review the driver's log:

```bash
tail -20 /var/log/openvswitch/docker-ovn-driver.log
```

The driver requires that the following command succeeds prior to enabling the driver:

```bash
ovs-vsctl --timeout=5 -vconsole:off get Open_vSwitch . external_ids:ovn-nb
```

The following `curl` queries the state of the network driver:

```bash
curl http://0.0.0.0:9105/NetworkDriver.Database
```

The following command allows read/write access to Docker interface by `greenpau` user:

```bash
sudo setfacl -m user:greenpau:rw /var/run/docker.sock
```

## Development

Note: Use `curl -X POST http://127.0.0.1:9105/<PATH> -d'<PAYLOAD>'` for testing.

When a user creates a network (i.e. `docker network create`), the driver receives
the following POST request to `/NetworkDriver.CreateNetwork`:

```json
{
    "NetworkID": "b5082ded43d3b362c2b913dae6ee17a8afb51ef0e2a2e19db122d4b5fea67142",
    "Options": {
        "com.docker.network.enable_ipv6": false,
        "com.docker.network.generic": {
            "vrf": "default"
        }
    },
    "IPv4Data": [{
        "AddressSpace": "LocalDefault",
        "Gateway": "10.30.30.1/23",
        "Pool": "10.30.30.0/23"
    }],
    "IPv6Data": []
}
```

When a user starts a container (i.e. `docker start CONTAINER_ID`), the driver receives
the following POST requests.

First, `/NetworkDriver.CreateEndpoint` with:

```json
{
    "NetworkID": "b5082ded43d3b362c2b913dae6ee17a8afb51ef0e2a2e19db122d4b5fea67142",
    "EndpointID": "2f2497db76a577c0f0ff0f8056b657a003bd7636d7fd984b875d5ad9a5d3fedf",
    "Interface": {
        "Address": "10.30.30.32/23",
        "AddressIPv6": "",
        "MacAddress": ""
    },
    "Options": {
        "com.docker.network.endpoint.exposedports": [],
        "com.docker.network.portmap": []
    }
}
```

Second, `/NetworkDriver.Join` with:

```json
{
    "NetworkID": "b5082ded43d3b362c2b913dae6ee17a8afb51ef0e2a2e19db122d4b5fea67142",
    "EndpointID": "2f2497db76a577c0f0ff0f8056b657a003bd7636d7fd984b875d5ad9a5d3fedf",
    "SandboxKey": "/var/run/docker/netns/fc2ac21230fc",
    "Options": {
        "com.docker.network.endpoint.exposedports": [],
        "com.docker.network.portmap": []
    }
}
```

Third, `/NetworkDriver.ProgramExternalConnectivity` with:

```json
{
    "NetworkID": "b5082ded43d3b362c2b913dae6ee17a8afb51ef0e2a2e19db122d4b5fea67142",
    "EndpointID": "2f2497db76a577c0f0ff0f8056b657a003bd7636d7fd984b875d5ad9a5d3fedf",
    "Options": {
        "com.docker.network.endpoint.exposedports": [],
        "com.docker.network.portmap": []
    }
}
```

Fourth and final, `/NetworkDriver.EndpointOperInfo` with:

```json
{
    "NetworkID": "b5082ded43d3b362c2b913dae6ee17a8afb51ef0e2a2e19db122d4b5fea67142",
    "EndpointID": "2f2497db76a577c0f0ff0f8056b657a003bd7636d7fd984b875d5ad9a5d3fedf"
}
```

When a user stops a container (i.e. `docker stop CONTAINER_ID`), the driver receives
the following POST requests:

1. `/NetworkDriver.RevokeExternalConnectivity`
2. `/NetworkDriver.Leave`
3. `/NetworkDriver.DeleteEndpoint`

The payload of the requests is `NetworkID` and `EndpointID`.

```json
{
    "NetworkID": "b5082ded43d3b362c2b913dae6ee17a8afb51ef0e2a2e19db122d4b5fea67142",
    "EndpointID": "2f2497db76a577c0f0ff0f8056b657a003bd7636d7fd984b875d5ad9a5d3fedf"
}
```

Importantly, when a user removes a container (i.e. `docker rm CONTAINER_ID`), the
driver does not receive any requests.

When a user deletes a network (i.e. `docker network rm NETWORK_ID`), the driver
receives POST request to `/NetworkDriver.DeleteNetwork` with the following payload:

```json
{
    "NetworkID": "b5082ded43d3b362c2b913dae6ee17a8afb51ef0e2a2e19db122d4b5fea67142"
}
```

Reference:
* [Docker Plugin Config Version 1 of Plugin V2](https://docs.docker.com/engine/extend/config/#config-field-descriptions)

Also, note that the plugin includes the following `openvswitch` packages:

* `openvswitch-<VERSION>.el7.x86_64.rpm`
* `openvswitch-ovn-common-<VERSION>.el7.x86_64.rpm`
* `python-openvswitch-<VERSION>.el7.noarch.rpm`
