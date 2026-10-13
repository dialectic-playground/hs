# High-Level Design (HLD) — Standard Terminal Hello World

| Field | Value |
| :-- | :-- |
| Project | `00-hello-world` |
| Tools | dp-hello |
| Implementation language | Haskell (GHC 9.14, cabal) |
| Author | Brandon Perkins |
| Version / date | 1.0 — 2026-10-13 |
| Status | Approved |
| Inputs | `specs/URD.md`, `specs/SRS.md`, `specs/user-manual.md`, `shared/CLI-CONVENTIONS.md` |

## 1. Introduction

### 1.1 Scope
`dp-hello` writes a greeting line (`Hello, ` + NAME + `!` + LF) to standard output, COUNT
times (1–1000, default 1), and handles `--help`, `--version`, and usage errors (SRS §1.2). It
reads no input, takes no operands, touches no files, reads no environment variables, and runs
no subprocesses (NFR-07).

### 1.2 Definitions and acronyms
| Term | Meaning |
| :-- | :-- |
| Scan | The left-to-right pass over the arguments that recognizes option syntax (CONV-12) |
| Invocation | The scan's raw result: last `--name` / `--count` value as written, and the operands |
| Config | A validated request: a non-empty name and a count in 1–1000 |
| Outcome | The complete result of one run: stdout text, stderr text, exit status |
| Pure core | The `DpHello.*` library modules except `DpHello.Output`; they perform no I/O |

### 1.3 References
- SRS §3 (interfaces), §4 (FR-01 … FR-11), §5 (NFR-01 … NFR-07), §6 (diagnostics)
- CLI-CONV §2 (CONV-03, CONV-05), §3 (CONV-07 … CONV-12), §4 (CONV-13 … CONV-15), §8, CONV-31
- User manual, "Help output"

## 2. Requirements summary

| Area | SRS requirements | Architectural impact |
| :-- | :-- | :-- |
| Option scanning | FR-02, FR-06, FR-07, FR-08, FR-10; CONV-07 … CONV-12, CONV-22 | A hand-written scanner (`DpHello.Cli`) that only recognizes syntax and stops at the first `--help`/`--version` |
| Validation | FR-03, FR-05, FR-09, FR-11 | A separate step (`DpHello.Validate`) run only after the whole scan |
| Greeting | FR-01, FR-02, FR-04; NFR-05 | A pure function (`DpHello.Greeting`) |
| Diagnostics | SRS §6; CONV-13 … CONV-15 | One error type and one renderer (`DpHello.Diagnostics`) |
| Output and platform | NFR-01; CONV-03, CONV-05, CONV-06, CONV-25 | A single I/O adapter (`DpHello.Output`) plus `Main` |
| Build and tooling | NFR-06 | cabal package, Makefile hooks, container and native CI |

## 3. Architectural overview

### 3.1 Context diagram

```text
          argv ──▶ ┌───────────┐ ──▶ stdout (greeting / help / version, UTF-8, LF)
                   │  dp-hello │ ──▶ stderr (one diagnostic + "Try ..." line)
                   └───────────┘ ──▶ exit status 0 or 2
   (no stdin, no files, no environment, no subprocesses)
```

### 3.2 Component (module) decomposition

| Component | Responsibility | Depends on |
| :-- | :-- | :-- |
| `DpHello.Cli` (`src/lib`) | Scan argv into `ShowHelp`, `ShowVersion`, or `Greet Invocation`, or a syntax `UsageError` | Diagnostics |
| `DpHello.Validate` | Turn an `Invocation` into a `Config` or a value/operand `UsageError` | Cli, Diagnostics |
| `DpHello.Greeting` | Build the greeting text (pure) | — |
| `DpHello.Diagnostics` | `UsageError` and its exact two-line rendering | — |
| `DpHello.App` | `run :: [String] -> Outcome` (pure); help and version text | all of the above |
| `DpHello.Output` | Configure stdout/stderr (binary mode, UTF-8) and write text | base `System.IO` |
| `Main` (`src/app`) | Read arguments, call `run`, emit, exit | App, Output |

### 3.3 Data flow
`Main` sets the argument encoding to UTF-8 and calls `getArgs` → `App.run` → `Cli.parseArgs`
→ (`ShowHelp` | `ShowVersion` | `Greet inv` → `Validate.validate` → `Greeting.greetingText`)
→ `Outcome{stdout, stderr, status}` → `Output.emit` on stdout, then stderr → `exitWith`.
Every error is a `Left UsageError` until `App.run` renders it, so no output is produced before
the decision is complete (FR-11).

## 4. Key design decisions

| # | Decision | Alternatives considered | Rationale |
| :-- | :-- | :-- | :-- |
| D1 | Pure core `run :: [String] -> Outcome`, thin I/O shell | Writing from inside the parser | End-to-end unit tests without processes; error atomicity is structural |
| D2 | Scanner records values, validation after the scan | Validate while scanning | CONV-12 (v1.4.0): value and operand errors never beat `--help`/`--version` |
| D3 | Errors as an algebraic type rendered in one function | Strings built at each error site | Exact CONV-13 texts live in one place (`renderUsageError`) |
| D4 | Build the whole output as a lazy `String` and write it once | Write line by line | At most 1000 short lines; the lazy `String` streams through the handle buffer |
| D5 | Hand-written parser, base only | `optparse-applicative`, `System.Console.GetOpt` | Argument libraries are excluded; `GetOpt` cannot express CONV-12 ordering and messages |
| D6 | Link with `-rtsopts=ignoreAll` | GHC default (`+RTS` honored) | Every argument reaches the parser (`-n +RTS` is a name) and `GHCRTS` is ignored (NFR-07) |

## 5. Cross-platform strategy
- **Line endings (CONV-03):** `DpHello.Output.configureHandle` calls `hSetBinaryMode True` on
  stdout and stderr, which disables GHC's newline translation (CRLF on Windows), then sets a
  UTF-8 encoding. All text uses `\n` only.
- **Arguments (CONV-05, CONV-06):** on Windows GHC's `getArgs` decodes the UTF-16 command line
  (`GetCommandLineW`). On POSIX it decodes bytes with the file-system encoding, which follows
  the locale; `Main` first sets it to UTF-8 with round-trip escapes, so arguments are UTF-8
  under any locale, and invalid bytes are written back unchanged.
- **Paths (CONV-19 … CONV-21):** not applicable; the tool touches no files.
- `DpHello.Output` and the first lines of `Main` are the only platform-sensitive code.

## 6. Error handling and diagnostics
`UsageError` (seven constructors, SRS §6) is produced by `Cli.parseArgs` (syntax errors) and
`Validate.validate` (operand and value errors). `App.run` maps every `UsageError` through
`Diagnostics.renderUsageError` to the two stderr lines and exit status 2; this is the only
mapping. Output write failures (EPIPE, CONV-25) are caught in `Output.emit`, and `Main` exits
with status 1 without a diagnostic. The core uses only total functions, so no exception or
stack trace can escape (CONV-24).

## 7. Non-functional design

| Quality attribute | SRS reference | How the design achieves it |
| :-- | :-- | :-- |
| Performance / memory | NFR-02, CONV-31 | Native executable, so the limits apply directly (CONV-31): measured 1.8 ms and 10 MiB peak RSS for `--count 1000` |
| Portability | NFR-01 | Binary-mode UTF-8 handles; CI on Linux, macOS, Windows |
| Robustness | NFR-03 | Total functions, `Either` errors, EPIPE caught |
| Security / input validation | NFR-07 | No file, environment (`-rtsopts=ignoreAll`), or process APIs used |
| Maintainability | NFR-04, NFR-05 | One module per unit; greeting construction pure and unit-tested |
| Build | NFR-06 | cabal + Makefile hooks for every BASE-MAKEFILE target |

## 8. Risks and open issues

| Risk / issue | Likelihood | Impact | Mitigation |
| :-- | :-- | :-- | :-- |
| GHC text-mode CRLF on Windows | M | H | Binary mode on both handles; unit test checks the bytes; Windows CI |
| Locale-dependent argument decoding on POSIX | M | H | UTF-8 file-system encoding set before `getArgs` |
| `+RTS` arguments consumed by the runtime | L | M | `-rtsopts=ignoreAll` |
| hlint/ormolu version drift between environments | M | L | Same pinned release binaries in the Containerfile and CI; `make toolchain` checks |

## 9. Approval

| Role | Name | Date | Decision |
| :-- | :-- | :-- | :-- |
| Author | Brandon Perkins | 2026-10-13 | Submitted |
| Reviewer | CI (container and native) | 2026-10-13 | Approved when all checks pass |
