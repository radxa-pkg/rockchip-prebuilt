PROJECT ?= rockchip-prebuilt
SOURCE ?= src

.PHONY: all
all: build

#
# Development
#
.PHONY: update
update: $(SOURCE) VERSION clean
	tag_name="$(shell cat VERSION)" && \
	current_tag="$${tag_name%-*}" && \
	tag_name="$${tag_name/rkr[0-9]*/rkr}" && \
	pushd "$^" && \
		git fetch && \
		latest_tag="$(shell git tag -l "$$tag_name*" --sort=-refname | head -n 1)" && \
		if [[ "$$current_tag" == "$$latest_tag" ]]; \
		then \
			echo "Current tag is up-to-date ($$current_tag)."; \
		else \
			echo "Current tag is $$current_tag. Updating to tag $$latest_tag..." && \
			git switch --detach $$latest_tag && \
			echo "$$latest_tag-1" > ../VERSION; \
		fi && \
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
build: $(SOURCE)
	find "$^" -name "camera_engine_rkaiq_*_arm64.deb" -exec fixup/fix_rkaiq {} +
	find "$^" -name "rktoolkit_*_arm64.deb" -exec fixup/fix_rktoolkit {} +
	# Disable Chromium fixup, since we currently install libmali by default
	#find "$^" -name "chromium-x11_*_arm64.deb" -exec fixup/fix_chromium {} +

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
