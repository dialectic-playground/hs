# Requirements Traceability Matrix (RTM) — Standard Terminal Hello World

| Field | Value |
| :-- | :-- |
| Project | `00-hello-world` |
| Tools | dp-hello |
| Author | Brandon Perkins |
| Version / date | 1.0 — 2026-10-13 |

Code paths are relative to `00-hello-world/src/`. Unit tests are the named checks in
`src/test/*Test.hs` (run by `cabal test`); `P01` … `P10` are the public black-box tests.
Hidden tests run in CI and are not cited.

## 1. User requirements to system requirements

| User requirement (URD) | Derived system requirements (SRS) |
| :-- | :-- |
| UR-01 | FR-01 |
| UR-02 | FR-02 |
| UR-03 | FR-04 |
| UR-04 | FR-07 |
| UR-05 | FR-08 |
| UR-06 | FR-03, FR-05, FR-09, FR-10, FR-11 |
| UR-07 | FR-01, SRS §3.7 |
| UR-08 | NFR-01, CONV-03 |
| UR-09 | FR-02, CONV-05 |
| UR-10 | FR-06, FR-10, CONV-07 … CONV-15 |
| UR-11 | NFR-02 |
| UR-12 | NFR-06 |

## 2. Forward traceability

| Req. ID | Summary | Design (HLD/LLD) | Code (file::function) | Verification (unit / black-box) | Status |
| :-- | :-- | :-- | :-- | :-- | :-- |
| UR-01 … UR-12 | User requirements | via the FR/NFR rows (§1) | — | via the FR/NFR rows | Verified |
| FR-01 | Default greeting | HLD §3.3, LLD §3.3, §3.5 | `lib/DpHello/Validate.hs::defaultName`, `lib/DpHello/Greeting.hs::greetingLine` | `app: default greeting`, `validate: defaults`, P01 | Verified |
| FR-02 | Named greeting, verbatim UTF-8 | LLD §3.1, §3.3 | `lib/DpHello/Cli.hs::parseArgs`, `lib/DpHello/Greeting.hs::greetingLine` | `cli: short name, attached value`, `cli: value may start with -`, `greeting: non-ASCII name`, `app: UTF-8 name`, P02, P03, P04 | Verified |
| FR-03 | Empty name rejected | LLD §3.2 | `lib/DpHello/Validate.hs::validate` | `validate: empty name, short`, `validate: empty name, long`, `app: empty name`, `app: empty attached name` | Verified |
| FR-04 | Repetition 1–1000, leading zeros | LLD §3.2, §3.3 | `lib/DpHello/Validate.hs::parseCount`, `lib/DpHello/Greeting.hs::greetingText` | `validate: parseCount "1"`, `… "1000"`, `… "007"`, `greeting: three lines`, `greeting: 1000 lines`, `app: leading zeros`, P05, P06 | Verified |
| FR-05 | Invalid count rejected | LLD §3.2 | `lib/DpHello/Validate.hs::parseCount`, `validate` | `validate: parseCount "0"`, `… "1001"`, `… "abc"`, `… "-1"`, `… ""`, `app: count 0`, `app: count 1001`, `app: count abc` | Verified |
| FR-06 | Last occurrence wins | LLD §3.1, §4 | `lib/DpHello/Cli.hs::record` | `cli: last name wins`, `cli: last count wins`, `app: last wins, only the winner is validated` | Verified |
| FR-07 | Help text, scan order | LLD §3.5, §4 | `lib/DpHello/App.hs::helpText`, `lib/DpHello/Cli.hs::parseArgs` | `app: help text is exact`, `cli: --help stops the scan`, `app: help after an operand`, `app: help after an invalid count`, P07 | Verified |
| FR-08 | Version line | LLD §3.5 | `lib/DpHello/App.hs::versionText` | `app: version`, `cli: the first of --help/--version wins`, P08 | Verified |
| FR-09 | Operands rejected | LLD §3.2 | `lib/DpHello/Validate.hs::validate` | `validate: the first operand is reported`, `app: extra operand`, `app: operand after --`, P10 | Verified |
| FR-10 | Unknown/malformed options | LLD §3.1 | `lib/DpHello/Cli.hs::parseArgs` | `cli: unknown short option`, `cli: unknown long option`, `cli: abbreviations are rejected`, `cli: --name without a value`, `cli: --version=1`, `app: invalid option`, P09 | Verified |
| FR-11 | No stdout on error | HLD §3.3, LLD §2.3 | `lib/DpHello/App.hs::run` | every `app:` usage-error case (`outStdout` is `""`), P09, P10 | Verified |
| NFR-01 | Byte-identical, LF only | HLD §5, LLD §5 | `lib/DpHello/Output.hs::configureHandle` | `output: LF is not translated`, `output: text is encoded as UTF-8`, P01–P10 on 3 OSes (CI) | Verified |
| NFR-02 | < 100 ms, < 32 MiB (native) | HLD §7, LLD §6 | whole program | Measurement (MTP §4.4): 1.8 ms, 10 MiB peak RSS for `--count 1000` | Verified |
| NFR-03 | No crash / stack trace | HLD §6 | `lib/DpHello/Cli.hs::parseArgs` (total), `lib/DpHello/Output.hs::emit` | all `cli:` error cases, `validate: parseCount "99999999999999999999999999"`, T-10 | Verified |
| NFR-04 | Separate units | HLD §3.2 | `Cli`, `Validate`, `Greeting`, `Output` modules | Design review (LLD §8) | Verified |
| NFR-05 | Pure greeting function | LLD §3.3 | `lib/DpHello/Greeting.hs::greetingText` | `greeting: …` tests | Verified |
| NFR-06 | All Makefile targets | HLD §7 | `00-hello-world/Makefile` (DP_* hooks) | CI `make check roundtrip` (Linux, macOS, Windows) and container `make check` | Verified |
| NFR-07 | No files, env, subprocesses | HLD §7, D6 | `dp-hello.cabal` (`-rtsopts=ignoreAll`), imports of `lib/` | Inspection | Verified |
| CONV-01 | Canonical name | LLD §2.4 | `lib/DpHello/Diagnostics.hs::programName` | `app:` error cases, P09 | Verified |
| CONV-02 | Version format | LLD §3.5 | `lib/DpHello/App.hs::versionText` | `app: version`, P08 | Verified |
| CONV-03 | LF output, binary mode | HLD §5 | `lib/DpHello/Output.hs::configureHandle` | `output: LF is not translated`, P01–P10 | Verified |
| CONV-05 | UTF-8 arguments | HLD §5, LLD §5 | `app/Main.hs::main`, `lib/DpHello/Output.hs::utf8Roundtrip` | `output: text is encoded as UTF-8`, `output: undecodable argument bytes are written back unchanged`, `app: UTF-8 name` | Verified |
| CONV-06 | Locale-independent | HLD §5 | `app/Main.hs::main` | T-09 (run with an empty environment) | Verified |
| CONV-07 | Short options, attached values | LLD §3.1 | `lib/DpHello/Cli.hs::parseArgs` | `cli: bundled count then name`, `cli: a short option consumes the rest of the token`, P06 | Verified |
| CONV-08 | Long options, no abbreviation | LLD §3.1 | `lib/DpHello/Cli.hs::parseArgs` | `cli: long name, = value`, `cli: abbreviations are rejected`, P04 | Verified |
| CONV-09 | `--` terminator | LLD §3.1 | `lib/DpHello/Cli.hs::parseArgs` | `cli: -- ends options`, `cli: a second -- is an operand` | Verified |
| CONV-10 | Operands, lone `-` | LLD §3.1 | `lib/DpHello/Cli.hs::parseArgs` | `cli: operands are collected in order`, `cli: a lone - is an operand` | Verified |
| CONV-11 | Last wins | LLD §4 | `lib/DpHello/Cli.hs::record` | `cli: last name wins`, `cli: last count wins` | Verified |
| CONV-12 | Scan order | LLD §4 | `lib/DpHello/Cli.hs::parseArgs`, `lib/DpHello/App.hs::run` | `cli: an operand before --help`, `cli: an invalid value before --help`, `cli: unknown short option before --help`, `app: invalid option before help` | Verified |
| CONV-13 | Diagnostic formats | LLD §2.4 | `lib/DpHello/Diagnostics.hs::renderUsageError` | `app:` error cases, P09, P10 | Verified |
| CONV-14 | `Try …` line, exit 2 | LLD §2.4 | `lib/DpHello/Diagnostics.hs::renderUsageError`, `lib/DpHello/App.hs::run` | `app:` error cases, P09, P10 | Verified |
| CONV-15 | Values verbatim, `''` | LLD §3.4 | `lib/DpHello/Diagnostics.hs::renderUsageError` | `app: empty name`, `app: unrecognized option with value` | Verified |
| CONV-22 | `--help`, `--version` take no argument | LLD §3.1 | `lib/DpHello/Cli.hs::parseArgs` | `cli: --help=x`, `cli: --version= (empty)`, `app: help with an argument` | Verified |
| CONV-23 | Help text verbatim | LLD §3.5 | `lib/DpHello/App.hs::helpText` | `app: help text is exact`, P07 | Verified |
| CONV-24 | No crash | HLD §6 | total core, `lib/DpHello/Output.hs::emit` | see NFR-03 | Verified |
| CONV-25 | EPIPE: stop quietly | HLD §6, LLD §3.6 | `lib/DpHello/Output.hs::emit`, `app/Main.hs::main` | T-10 | Verified |
| CONV-26 | stdin not read | HLD §3.1 | (no stdin use) | Inspection | Verified |
| CONV-27 … CONV-30 | Harness conditions | — | executable in `bin/` | P01–P10 via `run-tests.py` | Verified |
| CONV-31 | Native memory limits | HLD §7 | — | Measurement (MTP §4.4) | Verified |

CONV-04 and CONV-16 … CONV-21 do not apply: dp-hello copies no input data and touches no files
or paths.

## 3. Backward traceability (test → requirement)

| Test | Type | Requirement(s) verified |
| :-- | :-- | :-- |
| P01 | black-box, public | FR-01, CONV-03 |
| P02, P03 | black-box, public | FR-02 |
| P04 | black-box, public | FR-02, CONV-08 |
| P05 | black-box, public | FR-04 |
| P06 | black-box, public | FR-04, CONV-07 |
| P07 | black-box, public | FR-07, CONV-23 |
| P08 | black-box, public | FR-08, CONV-02 |
| P09 | black-box, public | FR-10, FR-11, CONV-13, CONV-14 |
| P10 | black-box, public | FR-09, FR-11, CONV-13, CONV-14 |
| `cli: …` (41 tests) | unit | FR-02, FR-06 … FR-08, FR-10, CONV-07 … CONV-12, CONV-22 |
| `validate: …` (27 tests) | unit | FR-03 … FR-06, FR-09 |
| `greeting: …` (7 tests) | unit | FR-01, FR-02, FR-04, NFR-05 |
| `app: …` (26 tests) | unit | FR-01 … FR-11, CONV-12 … CONV-15, CONV-23 |
| `output: …` (4 tests) | unit | NFR-01, CONV-03, CONV-05 |
| T-09, T-10 (MTP §4.2) | manual / scripted | CONV-06, CONV-25 |

## 4. Coverage summary

| Category | Total | Designed | Implemented | Verified |
| :-- | :-- | :-- | :-- | :-- |
| User requirements (UR) | 12 | 12 | 12 | 12 |
| Functional (FR) | 11 | 11 | 11 | 11 |
| Non-functional (NFR) | 7 | 7 | 7 | 7 |
| Conventions (CONV) | 24 applicable | 24 | 24 | 24 |

## 5. Gaps and justifications

None. NFR-02, NFR-04, NFR-07, and CONV-26 are verified by measurement or inspection, as the
SRS §7 prescribes.
