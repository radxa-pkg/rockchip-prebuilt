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
$(SOURCE):
	version="$$(dpkg-parsechangelog -S Version)" && \
	debian_version="$${version%%-*}" && \
	reversion="$${version##*-}" && \
	rockchip_version="$${version#$${debian_version}-}" && \
	rockchip_version="$${rockchip_version%-$${reversion}}" && \
	ln -s "$$rockchip_version" "$@"

pkg.conf:
	version="$$(dpkg-parsechangelog -S Version)" && \
	debian_version="$${version%%-*}" && \
	reversion="$${version##*-}" && \
	rockchip_version="$${version#$${debian_version}-}" && \
	rockchip_version="$${rockchip_version%-$${reversion}}" && \
	cp "pkg.conf.$$rockchip_version" "$@"

.PHONY: build
build: build-doc build-deb build-man $(SOURCE) pkg.conf

SRC-MAN		:=	man
SRCS-MAN	:=	$(wildcard $(SRC-MAN)/*.md)
MANS		:=	$(SRCS-MAN:.md=)
.PHONY: build-man
build-man: $(MANS)

$(SRC-MAN)/%: $(SRC-MAN)/%.md
	pandoc "$<" -o "$@" --from markdown --to man -s


SRC-DOC		:=	.
DOCS		:=	$(SRC-DOC)/SOURCE
build-doc: $(DOCS)

$(SRC-DOC):
	mkdir -p $(SRC-DOC)

.PHONY: $(SRC-DOC)/SOURCE
$(SRC-DOC)/SOURCE: $(SRC-DOC)
	echo -e "git clone $(shell git remote get-url origin)\ngit checkout $(shell git rev-parse HEAD)" > "$@"

SRC-DEB		:=	$(SOURCE)
.PHONY: build-deb
build-deb: $(SRC-DEB)
	find -L "$^" -name "camera_engine_rkaiq_*_arm64.deb" -exec fixup/fix_rkaiq {} +
	find -L "$^" -name "rktoolkit_*_arm64.deb" -exec fixup/fix_rktoolkit {} +
	find -L "$^" -name "chromium-x11_*_arm64.deb" -exec fixup/fix_chromium {} +

#
# Clean
#
.PHONY: distclean
distclean: clean

.PHONY: clean
clean: clean-deb
	rm -f "$(SOURCE)" pkg.conf

.PHONY: clean-deb
clean-deb:
	git submodule deinit -f .
	git submodule update --init

#
# Release
#
.PHONY: dch
dch: debian/changelog
	EDITOR=true gbp dch --debian-branch=main --multimaint-merge --commit --release --dch-opt=--upstream

.PHONY: deb
deb: debian
	debuild --no-lintian --lintian-hook "lintian --fail-on error,warning --suppress-tags bad-distribution-in-changes-file -- %p_%v_*.changes" --no-sign -b

.PHONY: release
release:
	gh workflow run .github/workflows/new_version.yml
