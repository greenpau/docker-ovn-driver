.PHONY: test lint clean image plugin
PLUGIN_NAME:="ovnworks/docker-ovn-driver"
PLUGIN_CONTAINTER="docker_ovn_driver"
PLUGIN_TMP_DIR:="./tmp/"
PLUGIN_TMP_ROOTFS_DIR:="./tmp/rootfs"

all: test

lint:
	@pylint docker-ovn-driver

test:
	@cat config.json | python -m json.tool

clean:
	@docker plugin disable ${PLUGIN_NAME} || true
	@docker plugin rm -f ${PLUGIN_NAME} || true
	@docker rm -f ${PLUGIN_CONTAINTER}_rootfs || true
	@rm -rf ${PLUGIN_TMP_DIR}
	@rm -rf /var/log/openvswitch/docker-ovn-driver.log || true
	@rm -rf /var/log/openvswitch/docker-ovn-socat.log || true

image: test clean
	@docker build -q -t ${PLUGIN_CONTAINTER}:rootfs -f Dockerfile .
	@mkdir -p ${PLUGIN_TMP_ROOTFS_DIR}
	@docker create --name ${PLUGIN_CONTAINTER}_rootfs ${PLUGIN_CONTAINTER}:rootfs
	@docker export ${PLUGIN_CONTAINTER}_rootfs | tar -x -C ${PLUGIN_TMP_ROOTFS_DIR}
	@cp config.json ${PLUGIN_TMP_DIR}
	@docker rm -vf ${PLUGIN_CONTAINTER}_rootfs
	@docker rmi ${PLUGIN_CONTAINTER}:rootfs

plugin: image
	@docker plugin create ${PLUGIN_NAME} ${PLUGIN_TMP_DIR}
	@docker plugin enable ${PLUGIN_NAME}
