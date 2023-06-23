eol=
BR ?= build-root

# bookworm version
PKTGEN_VERSION ?= 23.03.0

PKTGEN_SRC_TGZ = $(BR)/pktgen-dpdk_$(PKTGEN_VERSION).orig.tar.gz
PKTGEN_RELEASE_BASEURL = https://github.com/pktgen/Pktgen-DPDK/archive/refs/tags


.PHONY: install-dep
install-dep:
	apt update
	apt install -y \
		build-essential \
		curl \
		devscripts \
		dpdk-dev \
		fakeroot \
		quilt \
		$(eol)

$(BR):
	@mkdir -p $(BR)

$(PKTGEN_SRC_TGZ): | $(BR)
	curl --location \
		--output $(PKTGEN_SRC_TGZ) \
		$(PKTGEN_RELEASE_BASEURL)/pktgen-$(PKTGEN_VERSION).tar.gz

.PHONY: fetch-src
fetch-src: $(PKTGEN_SRC_TGZ)

$(BR)/package: $(PKTGEN_SRC_TGZ)
	@mkdir -p $@
	@tar --extract --directory=$@ --strip-components=1 --file=$(PKTGEN_SRC_TGZ)

$(BR)/package/debian: $(BR)/package package/debian
	@cp -ruf package/debian $@

# XXX generate a dummy changelog (to be improved)
# non-native package version MUST contain a revision
# postfix the version with a revision number articifialy to accommodate
$(BR)/package/debian/changelog: $(BR)/package/debian
	@echo "pktgen-dpdk ($(PKTGEN_VERSION)-1) unstable; urgency=medium" > $@
	@echo "" >> $@
	@echo "  * Version $(PKTGEN_VERSION)" >> $@
	@echo "" >> $@
	@echo " -- Gabriel Ganne <gabriel.ganne@gmail.com>  $(shell date -R)" >> $@

$(BR)/pktgen-$(PKTGEN_VERSION).deb: $(PKTGEN_SRC_TGZ) $(BR)/package/debian $(BR)/package/debian/changelog
	@cd $(BR)/package && \
		dpkg-buildpackage --build=source,any,all --unsigned-changes --unsigned-source

.PHONY: pkg-deb
pkg-deb: $(BR)/pktgen-$(PKTGEN_VERSION).deb | $(BR)/package

.PHONY: wipe
wipe:
	@rm -rvf $(BR)

.PHONY: lint
lint: $(BR)/pktgen-$(PKTGEN_VERSION).deb
	lintian --fail-on error --no-tag-display-limit. $^

.PHONY: help
help:
	@echo "# dev help target"
	@echo "install-dep          - install software dependencies"
	@echo "wipe                 - wipe clean all build artefacts"
	@echo "# pktgen release targets"
	@echo "fetch-src            - fetch pktgen source archive"
	@echo "pkg-deb              - create debian package"
	@echo "# Current Argument Values:"
	@echo "BR                   = $(BR)"
	@echo "PKTGEN_VERSION       = $(PKTGEN_VERSION)"

.DEFAULT_GOAL := help
