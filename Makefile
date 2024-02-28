PROJECT ?= rockchip-prebuilt
RELEASE_PREFIX ?= linux-6.1-stan-rkr

.PHONY: all
all: build

#
# Development
#
.PHONY: update
update: debian
	pushd debian && \
	git fetch && \
	latest_tag="$(shell git tag -l "$(RELEASE_PREFIX)*" --sort=-refname | head -n 1)" && \
	git switch --detach $latest_tag && \
	popd

#
# Test
#
.PHONY: test
test:
	

#
# Build
#
.PHONY: build
build: debian
	find "$^" -name "camera_engine_rkaiq_*_arm64.deb" -exec fixup/fix_rkaiq {} +
	find "$^" -name "rktoolkit_*_arm64.deb" -exec fixup/fix_rktoolkit {} +

#
# Clean
#
.PHONY: distclean
distclean: clean

.PHONY: clean
clean: clean-deb

.PHONY: clean-deb
clean-deb:
	git submodule deinit -f .
	git submodule update --init

#
# Release
#
.PHONY: dch
dch:

.PHONY: deb
deb: build

.PHONY: release
release:
