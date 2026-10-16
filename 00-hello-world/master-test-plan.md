<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

**Table of Contents** _generated with [DocToc](https://github.com/thlorenz/doctoc)_

- [Master Test Plan (MTP) — Standard Terminal Hello World](#master-test-plan-mtp--standard-terminal-hello-world)
  - [1. Introduction and scope](#1-introduction-and-scope)
    - [1.1 Objectives](#11-objectives)
    - [1.2 In scope / out of scope](#12-in-scope--out-of-scope)
  - [2. Test items](#2-test-items)
  - [3. Test levels and approach](#3-test-levels-and-approach)
  - [4. Test design](#4-test-design)
    - [4.1 Equivalence partitions and boundaries](#41-equivalence-partitions-and-boundaries)
    - [4.2 Additional test cases (beyond the supplied suite)](#42-additional-test-cases-beyond-the-supplied-suite)
    - [4.3 Negative and robustness testing](#43-negative-and-robustness-testing)
    - [4.4 Performance and resource testing](#44-performance-and-resource-testing)
  - [5. Test environments](#5-test-environments)
  - [6. Entry and exit criteria](#6-entry-and-exit-criteria)
  - [7. Defect management](#7-defect-management)
  - [8. Schedule and deliverables](#8-schedule-and-deliverables)
  - [9. Risks and contingencies](#9-risks-and-contingencies)
  - [10. Test summary (complete at the end)](#10-test-summary-complete-at-the-end)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Master Test Plan (MTP) — Standard Terminal Hello World

| Field                   | Value                                                  |
| :---------------------- | :----------------------------------------------------- |
| Project                 | `00-hello-world`                                       |
| Tools                   | dp-hello                                               |
| Implementation language | Haskell (GHC 9.14, cabal)                              |
| Author                  | Brandon Perkins                                        |
| Version / date          | 1.0 — 2026-10-13                                       |
| Standard                | Structure adapted from IEEE 829 / ISO/IEC/IEEE 29119-3 |

## 1. Introduction and scope

### 1.1 Objectives

"Tested enough" means every SRS acceptance criterion (FR-01 … FR-11) is exercised by a unit
test of the pure core or by a black-box test, every CONV-13 diagnostic is checked
byte-for-byte, and the public and hidden suites pass on Linux, macOS, and Windows.

### 1.2 In scope / out of scope

| In scope                                                                            | Out of scope                                                       |
| :---------------------------------------------------------------------------------- | :----------------------------------------------------------------- |
| Every FR/NFR in the SRS and the applicable CONV rules, on Linux, macOS, and Windows | Terminal rendering of non-ASCII names; consoles that are not UTF-8 |
| Option parsing, validation, greeting construction, output encoding                  | File, path, and stdin behavior (the tool has none)                 |

## 2. Test items

| Item                   | Version / location                                    |
| :--------------------- | :---------------------------------------------------- |
| dp-hello               | `00-hello-world/src/` on branch `feat/00-hello-world` |
| Public black-box suite | `tests/public/` (10 tests)                            |
| Hidden black-box suite | `tests/private/` (10 tests, run by CI)                |

## 3. Test levels and approach

| Level              | Purpose                                                         | Technique(s)                                      | Tooling                                                                     | Owner          |
| :----------------- | :-------------------------------------------------------------- | :------------------------------------------------ | :-------------------------------------------------------------------------- | :------------- |
| Unit               | Each unit in isolation: `Cli`, `Validate`, `Greeting`, `Output` | Equivalence partitioning, boundary-value analysis | `cabal test` (`test-suite unit`, assertion runner in `src/test/TestKit.hs`) | Developer      |
| Integration        | Parser → validation → greeting → diagnostics through `App.run`  | Specification-based, exact `Outcome` comparison   | `src/test/AppTest.hs`                                                       | Developer      |
| System (black-box) | The specified CLI behavior, byte-exact                          | Specification-based                               | `make test` → `run-tests.py`                                                | Developer      |
| Acceptance         | Hidden suite passes on all OSes                                 | —                                                 | CI `make test-hidden`                                                       | CI             |
| Static analysis    | Warnings, lint, formatting                                      | —                                                 | `make lint`: `-Wall -Wcompat -Werror`, hlint, `ormolu --mode check`         | Developer / CI |

## 4. Test design

### 4.1 Equivalence partitions and boundaries

| Input         | Valid partitions                                        | Invalid partitions                                                 | Boundaries                           |
| :------------ | :------------------------------------------------------ | :----------------------------------------------------------------- | :----------------------------------- |
| NAME          | non-empty: ASCII, spaces, non-ASCII, leading `-`        | empty                                                              | length 0 / 1                         |
| COUNT         | ASCII digits with value 1–1000, leading zeros           | empty, non-digits, sign, spaces, non-ASCII digits, 0, > 1000, huge | 0, 1, 1000, 1001, `000`, `0001000`   |
| Option syntax | `-nV`, `-n V`, `--name=V`, `--name V`, `--`, repetition | unknown short/long, abbreviation, missing value, `--help=…`        | value at the end of the list         |
| Operands      | none                                                    | any token not an option, any token after `--`                      | `-` alone                            |
| Scan order    | `--help`/`--version` first                              | syntax error before them                                           | operand or bad value before `--help` |

### 4.2 Additional test cases (beyond the supplied suite)

| ID   | Requirement(s)   | Preconditions        | Steps / command                                             | Expected result                             | Level                                        |
| :--- | :--------------- | :------------------- | :---------------------------------------------------------- | :------------------------------------------ | :------------------------------------------- |
| T-01 | FR-04, FR-05     | —                    | `parseCount` on 0, 1, 1000, 1001, `007`, `000`, huge        | `validate: parseCount …` results            | unit                                         |
| T-02 | FR-03            | —                    | `-n ''`, `--name=`                                          | `invalid argument '' for '-n'` / `'--name'` | unit                                         |
| T-03 | FR-06            | —                    | `-c 0 -c 1 -n '' -n B`                                      | `Hello, B!` (only winners validated)        | unit                                         |
| T-04 | CONV-12          | —                    | `--count 0 --help`, `extra --help`                          | help, exit 0                                | unit                                         |
| T-05 | CONV-12          | —                    | `-x --help`                                                 | `invalid option -- 'x'`, exit 2             | unit                                         |
| T-06 | CONV-07          | —                    | `-cn2`                                                      | count value `n2` (rest of the token)        | unit                                         |
| T-07 | CONV-09          | —                    | `--`, `--`; `-- --help`                                     | operands `--`, `--help`                     | unit                                         |
| T-08 | CONV-03, CONV-05 | temporary file       | `emit` of `a\nb\n`, `Zoë`, an escaped byte                  | bytes `a\nb\n`, `Zo\xC3\xAB`, `\xFF`        | unit                                         |
| T-09 | CONV-05, CONV-06 | built `bin/dp-hello` | `env -i bin/dp-hello -n Zoë \| od -c`                       | `Hello, Zo 303 253 !\n` with no locale set  | system                                       |
| T-10 | CONV-25          | built `bin/dp-hello` | `bin/dp-hello -c 1000 -n <30000 × a> \| head -c 10`         | no diagnostic, prompt exit                  | system                                       |
| T-11 | D6, NFR-07       | built `bin/dp-hello` | `dp-hello -n +RTS -c 2 --RTS x`; `env GHCRTS=-xyz dp-hello` | `+RTS` reaches the parser; `GHCRTS` ignored | system                                       |
| T-12 | FR-10            | —                    | `-é`                                                        | `invalid option -- 'é'`                     | unit (`cli: unknown non-ASCII short option`) |

### 4.3 Negative and robustness testing

Every CONV-13 message is produced by at least one `app:` unit test with the exact stderr and
status 2 and an empty stdout. Arbitrarily long COUNT values (`parseCount` saturates),
non-ASCII option letters (T-12), invalid UTF-8 argument bytes (T-08, `output: undecodable
argument bytes are written back unchanged`), runtime option syntax (T-11), and a closed pipe
(T-10) are covered. Stdin, files, and permissions do not apply.

### 4.4 Performance and resource testing

NFR-02 / CONV-31: dp-hello is a native executable, so the limits apply directly. Measured in
the toolchain container (Linux x86_64) with Python's `resource.getrusage(RUSAGE_CHILDREN)`
around `subprocess.run`: `dp-hello --count 1000` took 1.8 ms wall-clock with 10 MiB peak RSS;
`dp-hello` took 1.5 ms. A 30 MB output (`-c 1000` with a 30 000-character name) stays at
10 MiB, showing that output is streamed. Limits: 100 ms and 32 MiB.

## 5. Test environments

| Environment       | OS / version                                | Toolchain                                            | How provisioned                                                     |
| :---------------- | :------------------------------------------ | :--------------------------------------------------- | :------------------------------------------------------------------ |
| Local (container) | Debian bookworm (Fedora host, Podman)       | GHC 9.14.1, cabal 3.16, hlint 3.10, ormolu 0.9.0.0   | `Containerfile` via `make`                                          |
| CI                | ubuntu-latest, macos-latest, windows-latest | GHC 9.14.1, latest cabal, hlint 3.10, ormolu 0.9.0.0 | `.github/workflows/ci.yml` (from `shared/ci/cross-platform-ci.yml`) |

## 6. Entry and exit criteria

- **Entry:** HLD and LLD complete; `make all` succeeds; `make lint` is clean.
- **Exit:** all unit tests and all public and hidden black-box tests pass on all three OSes,
  the container `make check` and native `make check roundtrip` pass, there are no open
  severity-1/2 defects, and the RTM shows every requirement as Verified.
- **Suspension / resumption:** suspend on any toolchain failure in CI (for example a missing
  hlint binary for a runner); resume when the toolchain step is fixed.

## 7. Defect management

Defects are GitHub issues in `dialectic-playground/hs` with a severity label. A fix comes
with a new unit test that fails before it, and is re-tested by `make check` in the container
and by CI on all three operating systems.

| Severity     | Definition                                                              |
| :----------- | :---------------------------------------------------------------------- |
| 1 — Critical | Crash, stack trace, or wrong output on a mainline path                  |
| 2 — Major    | Wrong diagnostic text or exit status; platform-specific byte difference |
| 3 — Minor    | Lint, formatting, or documentation defect                               |

## 8. Schedule and deliverables

| Milestone               | Deliverable                | Target date |
| :---------------------- | :------------------------- | :---------- |
| Design complete         | `hld.md`, `lld.md`         | 2026-10-13  |
| Implementation complete | `src/`, unit tests         | 2026-10-13  |
| Verification complete   | RTM all Verified, CI green | 2026-10-13  |

## 9. Risks and contingencies

| Risk                                                          | Mitigation                                                                  |
| :------------------------------------------------------------ | :-------------------------------------------------------------------------- |
| Windows-only failure (CRLF, UTF-16 arguments) discovered late | Binary mode and UTF-8 unit tests; CI on all OSes from the first commit      |
| hlint has no native macOS arm64 binary                        | Runs under Rosetta 2; fallback: build from source with cabal                |
| GHC point release changes boot-package versions               | GHC pinned to 9.14.1 natively; regenerate `cabal.project.freeze` on upgrade |

## 10. Test summary (complete at the end)

| Metric                                | Value                                                       |
| :------------------------------------ | :---------------------------------------------------------- |
| Unit tests (pass / total)             | 105 / 105                                                   |
| Coverage (line / branch)              | Not measured (every function of the pure core is exercised) |
| Public black-box (pass / 10)          | 10 / 10 (container, Linux, macOS, Windows)                  |
| Hidden black-box (pass / 10, from CI) | 10 / 10                                                     |
| Open defects by severity              | 0 / 0 / 0                                                   |
