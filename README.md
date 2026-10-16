<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

**Table of Contents** _generated with [DocToc](https://github.com/thlorenz/doctoc)_

- [hs](#hs)
  - [Haskell at a glance](#haskell-at-a-glance)
  - [Toolchain](#toolchain)
  - [Layout](#layout)
  - [Development](#development)
  - [Implementing a project](#implementing-a-project)
  - [Contributing](#contributing)
  - [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/dialectic-playground/.github/main/assets/hs/dist/logo-dark.svg">
    <img alt="dialectic playground / hs" src="https://raw.githubusercontent.com/dialectic-playground/.github/main/assets/hs/dist/logo.svg" height="96">
  </picture>
</p>

# hs

Haskell implementation of the Dialectic Playground SDLC curriculum.

📖 **Documentation:** <https://dialectic-playground.github.io/docs/reference/languages/hs/>

This repository implements the eleven projects of the
[SDLC curriculum](https://github.com/dialectic-playground/sdlc-curriculum) in Haskell. Each project is
specified to the byte by the curriculum and verified by its black-box tests on Linux, macOS,
and Windows.

**Status:** Implemented projects: 00-hello-world.

## Haskell at a glance

| Aspect                  | Haskell                                                              |
| :---------------------- | :------------------------------------------------------------------- |
| File extension          | `.hs`                                                                |
| CLI classification      | Included                                                             |
| Image category          | First-Class                                                          |
| Access to OS primitives | High (via System.Environment primitives)                             |
| Entry-point mechanism   | Compiles to binary; runtime initializes and wraps options to getArgs |

## Toolchain

|                      |                                                                                   |
| :------------------- | :-------------------------------------------------------------------------------- |
| Release line         | GHC 9.14                                                                          |
| Build / package tool | cabal                                                                             |
| Container image      | `haskell:9.14-slim-bookworm`, pinned by digest ([`Containerfile`](Containerfile)) |
| Native CI            | haskell-actions/setup (GHC 9.14.1, latest cabal)                                  |
| Lint / format        | hlint 3.10, ormolu 0.9.0.0 (pinned prebuilt release binaries)                     |

`make toolchain` verifies that the container and native toolchains are on this release line
and that hlint and ormolu are the pinned versions.

| Task       | Tool                                                                        | Project hook                                  |
| :--------- | :-------------------------------------------------------------------------- | :-------------------------------------------- |
| Build      | `cabal build` (`-Wall -Wcompat -Werror`), executable copied to `bin/<tool>` | `make all`                                    |
| Unit tests | `cabal test` (an `exitcode-stdio-1.0` suite with a small assertion runner)  | `make test` (then the public black-box suite) |
| Lint       | `cabal build all` with `-Werror`, `hlint src`, `ormolu --mode check`        | `make lint`                                   |
| Format     | `ormolu --mode inplace`                                                     | `make format`                                 |

Each project is a cabal package (`<tool>.cabal`, `cabal.project`, and the
`cabal.project.freeze` lock file in the project directory) with a library in `src/lib/`, the
executable in `src/app/`, and unit tests in `src/test/`. The projects use only packages that
ship with GHC, so `cabal.project` disables the Hackage index (`active-repositories: :none`):
builds need no `cabal update` and no network. Dependabot does not support cabal; regenerate
the freeze file with `cabal freeze` when the GHC version changes (the native CI pins GHC
9.14.1, the container image's version, for that reason).

hlint and ormolu are not part of the GHC image. The `Containerfile` installs their official
prebuilt release binaries (x86_64 Linux; on other hosts use `DP_PLATFORM=linux/amd64`), and
the native CI installs the same versions for Linux, macOS (hlint under Rosetta 2), and
Windows. Both are verified by SHA-256. To work natively, install the same versions (for
example from the [hlint](https://github.com/ndmitchell/hlint/releases) and
[ormolu](https://github.com/tweag/ormolu/releases) release pages) and put them on `PATH`.

## Layout

| Path                                  | Contents                                                                                                          |
| :------------------------------------ | :---------------------------------------------------------------------------------------------------------------- |
| `00-hello-world/` … `10-sys-monitor/` | One workspace per curriculum project: `Makefile` (with `DP_*` hooks), HLD, LLD, RTM, master test plan, and `src/` |
| `sdlc-curriculum/`                    | The curriculum, as a git submodule pinned to a release tag                                                        |
| `Makefile`                            | `make check` (repository, toolchain, implemented projects), `toolchain`, `projects`, `roundtrip`                  |
| `Containerfile`, `.devcontainer/`     | The toolchain image and the matching dev container                                                                |
| `tools/dp-run`, `tools/container.mk`  | Shared container tooling (copies of the canonical files in `dialectic-playground/.github`)                        |
| `.github/workflows/ci.yml`            | CI: container and native (Linux, macOS, Windows) `make` targets, shared-tooling check, DCO                        |

## Development

Container-first: `make` targets and `tools/dp-run <command>` run in the toolchain container
via Podman, then Docker, then the local system. `DP_RUNTIME=podman|docker|local` overrides
the choice.

```sh
git clone --recurse-submodules https://github.com/dialectic-playground/hs.git
cd hs
make check                    # repository, toolchain, and every implemented project
DP_RUNTIME=local make check   # the same with your native toolchain
make -C 00-hello-world help   # a project's configuration and hooks
```

## Implementing a project

1. Complete the project's `hld.md` and `lld.md` before writing code.
2. Write the implementation and its unit tests under the project's `src/`, add the
   repository's cabal configuration, and fill in `BIN_DIR` and the `DP_*` hooks in
   the project's `Makefile`.
3. Pass `make -C <project> test` (container) and `DP_RUNTIME=local make -C <project> test`.
4. Add the project directory to `IMPLEMENTED` in the root `Makefile`. CI then builds, lints,
   and tests it in the container and natively on all three operating systems.
5. Keep `rtm.md` and `master-test-plan.md` current.

Specifications: [curriculum reference](https://dialectic-playground.github.io/docs/reference/curriculum/). Language setup:
[Set up a language repository](https://dialectic-playground.github.io/docs/how-to/set-up-a-language-repository/).

## Contributing

See the [organization contributing guide](https://github.com/dialectic-playground/.github/blob/main/CONTRIBUTING.md).
Pull requests are squash-merged, titles follow Conventional Commits, and every commit needs a
DCO sign-off.

## License

[MIT](LICENSE)
