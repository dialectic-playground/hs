# Makefile for dialectic-playground/hs: Haskell implementations of the SDLC curriculum.
#
#   make                 same as `make check`
#   make check           everything CI checks: repository, toolchain, every implemented project
#   make toolchain       print and verify the toolchain versions
#   make projects        `make all lint test test-hidden` in every implemented project
#   make roundtrip       install/uninstall round trip for every implemented project (host)
#   make dp-info | dp-shell | dp-image
#
# Every goal runs in the toolchain container built from ./Containerfile: podman, then docker,
# then the local system. Override with DP_RUNTIME=podman|docker|local or DP_IMAGE=<image>.
# roundtrip and help act on the host, so they always run locally.

# Project directories whose implementation is complete enough to build and test, in
# curriculum order (for example: 00-hello-world 01-echo). CI covers exactly these.
IMPLEMENTED := 00-hello-world

DP_HOST_GOALS += help roundtrip
include tools/container.mk
ifeq ($(DP_DELEGATE),)

SHELL := /bin/sh
.DEFAULT_GOAL := check
CURRICULUM_ROOT := sdlc-curriculum
# Lint and format tools, pinned to the same versions in the Containerfile and ci.yml.
HLINT_VERSION := 3.10
ORMOLU_VERSION := 0.9.0.0
STANDARD_FILES := LICENSE README.md Containerfile Makefile .editorconfig .gitattributes \
	.gitignore .gitmodules .devcontainer/devcontainer.json .github/CODEOWNERS \
	.github/dependabot.yml .github/workflows/ci.yml tools/dp-run tools/container.mk \
	$(CURRICULUM_ROOT)/curriculum.toml
.PHONY: check check-repository toolchain projects roundtrip help

check: check-repository toolchain projects

# Standard files present, the curriculum submodule checked out, a workspace for every
# curriculum project, and no unfinished template markers.
check-repository:
	@status=0; \
	for file in $(STANDARD_FILES); do \
		[ -f "$$file" ] || { echo "missing: $$file (submodule: git submodule update --init)"; status=1; }; \
	done; \
	for slug in $$(sed -n 's/^slug = "\(.*\)"/\1/p' $(CURRICULUM_ROOT)/curriculum.toml 2>/dev/null); do \
		[ -f "$$slug/Makefile" ] || { echo "missing project workspace: $$slug/Makefile"; status=1; }; \
	done; \
	marker="TEMPLATE"; marker="$$marker:"; \
	if grep -rn --exclude-dir=.git --exclude-dir=.github --exclude-dir=tools \
	        --exclude-dir=$(CURRICULUM_ROOT) --exclude-dir=dist-newstyle "$$marker" .; then \
		echo "replace every $$marker marker listed above"; status=1; \
	fi; \
	[ $$status -eq 0 ] && echo "repository: standard files, $(CURRICULUM_ROOT), and project workspaces present"; \
	exit $$status

# Prints each tool's version and fails unless it is on the repository's release line
# (GHC 9.14) or, for hlint and ormolu, the pinned version (Containerfile and ci.yml), so the
# container image and the native CI toolchains stay in step.
toolchain:
	python3 --version || python --version
	make --version | head -1
	@version="$$(ghc --numeric-version)"; echo "$$version"; echo "$$version" | grep -q '^9\.14\.' \
		|| { echo 'toolchain: expected a version matching ^9\.14\.' >&2; exit 1; }
	cabal --version | head -1
	@version="$$(hlint --numeric-version | tr -d '\r')"; echo "hlint $$version"; [ "$$version" = "$(HLINT_VERSION)" ] \
		|| { echo 'toolchain: expected hlint $(HLINT_VERSION)' >&2; exit 1; }
	@version="$$(ormolu --version | head -1 | tr -d '\r')"; echo "$$version"; [ "$${version%% *}" = ormolu ] \
		&& [ "$$(echo "$$version" | cut -d' ' -f2)" = "$(ORMOLU_VERSION)" ] \
		|| { echo 'toolchain: expected ormolu $(ORMOLU_VERSION)' >&2; exit 1; }

projects:
	@[ -n "$(strip $(IMPLEMENTED))" ] || echo "projects: none implemented yet (IMPLEMENTED is empty)"
	@for project in $(IMPLEMENTED); do \
		$(MAKE) --no-print-directory -C "$$project" all lint test test-hidden || exit 1; \
	done

roundtrip:
	@prefix="$${RUNNER_TEMP:-$${TMPDIR:-/tmp}}/dp-roundtrip"; \
	for project in $(IMPLEMENTED); do \
		$(MAKE) --no-print-directory -C "$$project" install PREFIX="$$prefix" \
			&& $(MAKE) --no-print-directory -C "$$project" uninstall PREFIX="$$prefix" || exit 1; \
	done; echo "roundtrip: $(words $(IMPLEMENTED)) project(s)"

help:
	@sed -n '4,13p' Makefile | sed 's/^# \{0,1\}//'

endif
