# 00-hello-world: Standard Terminal Hello World
#
# Project Makefile template. It extends the universal build contract in
# shared/templates/BASE-MAKEFILE, which defines the standard targets:
#
#   make all | install | uninstall | test | check | lint | format | clean | distclean
#   make test-hidden | grade | help
#
# A language implementation repository copies this file next to its sources, sets BIN_DIR,
# fills in each DP_* hook with its toolchain's commands, and points CURRICULUM_ROOT at its
# checkout of sdlc-curriculum (for example a git submodule). Hooks that are left empty make
# their target fail with an explanation. `make help` shows which hooks are defined.
#
# Container-first: goals run in the toolchain container built from the repository's
# Containerfile (podman, then docker, then local; override with DP_RUNTIME). The image needs
# the language toolchain, make, and python3 >= 3.11. Use DP_RUNTIME=local for native builds.

PROJECT := 00-hello-world
TOOLS   := dp-hello

# Path to the sdlc-curriculum checkout (the specs, test suites, and runner live there).
CURRICULUM_ROOT ?= ../sdlc-curriculum

# Haskell (cabal): dp-hello.cabal, cabal.project, and cabal.project.freeze live here. The
# library (src/lib), executable (src/app), and unit tests (src/test) depend only on packages
# that ship with GHC, so no package index or network is needed. Build output goes to
# dist-newstyle/; the cabal store lives outside the project (HOME / XDG directories).
CABAL   ?= cabal
HLINT   ?= hlint
ORMOLU  ?= ormolu
HS_SOURCES := $(wildcard src/*/*.hs src/*/*/*.hs)

# Directory that contains the built executables after `make all`.
BIN_DIR := bin

# Language-specific commands. Use $(TOOLS), $(EXE), $(PREFIX), and $(BINDIR) as needed.
# Build with -Wall -Werror (dp-hello.cabal), then copy the executable out of dist-newstyle.
define DP_BUILD
$(CABAL) build exe:$(TOOLS)
mkdir -p "$(BIN_DIR)"
cp "$$($(CABAL) list-bin exe:$(TOOLS))" "$(BIN_DIR)/$(TOOLS)$(EXE)"
endef
define DP_INSTALL
mkdir -p "$(BINDIR)"
cp "$(BIN_DIR)/$(TOOLS)$(EXE)" "$(BINDIR)/$(TOOLS)$(EXE)"
endef
DP_UNINSTALL = rm -f "$(BINDIR)/$(TOOLS)$(EXE)"
DP_UNIT_TEST = $(CABAL) test --test-show-details=direct
# Compile every component with -Wall -Werror, then hlint, then fail if ormolu would change
# any file.
define DP_LINT
$(CABAL) build all
$(HLINT) src
$(ORMOLU) --mode check $(HS_SOURCES)
endef
DP_FORMAT    = $(ORMOLU) --mode inplace $(HS_SOURCES)
DP_CLEAN     = rm -rf "$(BIN_DIR)" dist-newstyle
# Also remove local cabal configuration and GHC environment files; the cabal store and
# package index live outside the project (HOME / XDG directories).
DP_DISTCLEAN = rm -rf "$(BIN_DIR)" dist-newstyle cabal.project.local cabal.project.local~ .ghc.environment.*

include $(CURRICULUM_ROOT)/shared/templates/BASE-MAKEFILE
