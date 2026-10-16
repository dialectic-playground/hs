<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

**Table of Contents** _generated with [DocToc](https://github.com/thlorenz/doctoc)_

- [Low-Level Design (LLD) — Standard Terminal Hello World](#low-level-design-lld--standard-terminal-hello-world)
  - [1. Source layout](#1-source-layout)
  - [2. Data types](#2-data-types)
    - [2.1 `OptionValue`, `Invocation`, `Action` (`DpHello.Cli`)](#21-optionvalue-invocation-action-dphellocli)
    - [2.2 `Config` (`DpHello.Validate`)](#22-config-dphellovalidate)
    - [2.3 `Outcome` (`DpHello.App`)](#23-outcome-dphelloapp)
    - [2.4 Error type (`DpHello.Diagnostics.UsageError`)](#24-error-type-dphellodiagnosticsusageerror)
  - [3. Module and function specifications](#3-module-and-function-specifications)
    - [3.1 `DpHello.Cli.parseArgs`](#31-dphellocliparseargs)
    - [3.2 `DpHello.Validate.validate` and `parseCount`](#32-dphellovalidatevalidate-and-parsecount)
    - [3.3 `DpHello.Greeting.greetingLine` and `greetingText`](#33-dphellogreetinggreetingline-and-greetingtext)
    - [3.4 `DpHello.Diagnostics.renderUsageError`](#34-dphellodiagnosticsrenderusageerror)
    - [3.5 `DpHello.App.run`](#35-dphelloapprun)
    - [3.6 `DpHello.Output.configureHandle`, `emit`; `Main.main`](#36-dphellooutputconfigurehandle-emit-mainmain)
  - [4. Algorithms](#4-algorithms)
  - [5. Platform-specific details](#5-platform-specific-details)
  - [6. Resource management](#6-resource-management)
  - [7. Sequence of one invocation](#7-sequence-of-one-invocation)
  - [8. Design-to-code checklist](#8-design-to-code-checklist)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Low-Level Design (LLD) — Standard Terminal Hello World

| Field                   | Value                                                 |
| :---------------------- | :---------------------------------------------------- |
| Project                 | `00-hello-world`                                      |
| Tools                   | dp-hello                                              |
| Implementation language | Haskell (GHC 9.14, cabal)                             |
| Author                  | Brandon Perkins                                       |
| Version / date          | 1.0 — 2026-10-13                                      |
| Status                  | Approved                                              |
| Inputs                  | `hld.md`, `specs/SRS.md`, `shared/CLI-CONVENTIONS.md` |

## 1. Source layout

```text
00-hello-world/
├── dp-hello.cabal          # library, executable dp-hello, test-suite unit; -Wall -Wcompat -Werror
├── cabal.project           # packages: . ; no package index (base and boot packages only)
├── cabal.project.freeze    # lock file (cabal freeze)
└── src/
    ├── lib/DpHello/
    │   ├── Cli.hs          # scanner: argv -> Action (CONV-07 … CONV-12)
    │   ├── Validate.hs     # Invocation -> Config (FR-03, FR-05, FR-06, FR-09)
    │   ├── Greeting.hs     # pure greeting construction (NFR-05)
    │   ├── Diagnostics.hs  # UsageError and its rendering (CONV-13 … CONV-15)
    │   ├── App.hs          # pure core run :: [String] -> Outcome; help and version text
    │   └── Output.hs       # binary-mode UTF-8 handles, write + flush, EPIPE
    ├── app/Main.hs         # I/O shell: argument encoding, getArgs, emit, exit
    └── test/               # Main.hs (runner entry), TestKit.hs (assertions), *Test.hs per unit
```

## 2. Data types

### 2.1 `OptionValue`, `Invocation`, `Action` (`DpHello.Cli`)

| Field           | Type                | Default   | Constraint / invariant                            | SRS          |
| :-------------- | :------------------ | :-------- | :------------------------------------------------ | :----------- |
| `optionWritten` | `String`            | —         | `-n`, `--name`, `-c`, or `--count`, as written    | FR-03, FR-05 |
| `optionText`    | `String`            | —         | Value verbatim (may be empty or start with `-`)   | FR-02        |
| `invName`       | `Maybe OptionValue` | `Nothing` | Last `-n`/`--name` (CONV-11)                      | FR-06        |
| `invCount`      | `Maybe OptionValue` | `Nothing` | Last `-c`/`--count` (CONV-11)                     | FR-06        |
| `invOperands`   | `[String]`          | `[]`      | All operands in order, including those after `--` | FR-09        |

`Action = ShowHelp | ShowVersion | Greet Invocation`.

### 2.2 `Config` (`DpHello.Validate`)

| Field      | Type     | Default   | Constraint / invariant | SRS           |
| :--------- | :------- | :-------- | :--------------------- | :------------ |
| `cfgName`  | `String` | `"World"` | non-empty              | FR-01 … FR-03 |
| `cfgCount` | `Int`    | `1`       | 1 ≤ count ≤ 1000       | FR-04, FR-05  |

### 2.3 `Outcome` (`DpHello.App`)

`Outcome { outStdout, outStderr :: String, outStatus :: Int }`; `outStdout` is empty
whenever `outStatus` is 2 (FR-11).

### 2.4 Error type (`DpHello.Diagnostics.UsageError`)

Every variant renders as `dp-hello: <message>` + LF + `Try 'dp-hello --help' for more
information.` + LF and exits with status 2.

| Variant                     | Diagnostic (first line)                            | Exit status |
| :-------------------------- | :------------------------------------------------- | :---------- |
| `InvalidOption c`           | `dp-hello: invalid option -- 'c'`                  | 2           |
| `UnrecognizedOption token`  | `dp-hello: unrecognized option 'token'`            | 2           |
| `MissingShortArgument c`    | `dp-hello: option requires an argument -- 'c'`     | 2           |
| `MissingLongArgument opt`   | `dp-hello: option 'opt' requires an argument`      | 2           |
| `UnexpectedArgument opt`    | `dp-hello: option 'opt' doesn't allow an argument` | 2           |
| `InvalidArgument value opt` | `dp-hello: invalid argument 'value' for 'opt'`     | 2           |
| `ExtraOperand operand`      | `dp-hello: extra operand 'operand'`                | 2           |

## 3. Module and function specifications

### 3.1 `DpHello.Cli.parseArgs`

- **Signature:** `parseArgs :: [String] -> Either UsageError Action`
- **Responsibility:** recognize option syntax left to right (CONV-12).
- **Preconditions:** none (any list of strings).
- **Postconditions:** `ShowHelp`/`ShowVersion` if reached before any syntax error; otherwise
  `Greet` with the last values and all operands.
- **Errors:** `InvalidOption`, `UnrecognizedOption`, `MissingShortArgument`,
  `MissingLongArgument`, `UnexpectedArgument`.
- **Algorithm:** for each token: `--` → all remaining tokens are operands, stop; `--NAME[=V]`
  → `help`/`version` without `=` return immediately, with `=` fail; `name`/`count` take `V`
  or the next token (missing → error); anything else is unrecognized (the full token);
  `-L…` (two or more characters) → `n`/`c` take the rest of the token or the next token,
  any other letter is invalid; anything else (including `-`) is an operand.
- **Complexity:** O(n) time and memory in the number of arguments.
- **Satisfies:** FR-02, FR-06, FR-07, FR-08, FR-10; CONV-07 … CONV-12, CONV-22.
- **Unit tests:** `src/test/CliTest.hs`, every `cli: …` test.

### 3.2 `DpHello.Validate.validate` and `parseCount`

- **Signatures:** `validate :: Invocation -> Either UsageError Config`;
  `parseCount :: String -> Maybe Int`
- **Responsibility:** decide operand and value errors after the scan.
- **Errors:** first operand → `ExtraOperand`; empty name → `InvalidArgument "" opt`; bad count →
  `InvalidArgument value opt` (checked in that order).
- **Algorithm (`parseCount`):** reject empty text or any character outside `'0'..'9'`
  (`Data.Char.isDigit` is ASCII-only); fold the digits saturating at 1001, so arbitrarily long
  inputs cannot overflow; accept 1–1000.
- **Complexity:** O(length of the value).
- **Satisfies:** FR-03, FR-04, FR-05, FR-06, FR-09.
- **Unit tests:** `src/test/ValidateTest.hs` (`validate: …`, `validate: parseCount …`).

### 3.3 `DpHello.Greeting.greetingLine` and `greetingText`

- **Signatures:** `greetingLine :: String -> String`; `greetingText :: String -> Int -> String`
- **Responsibility:** `"Hello, " <> name <> "!\n"`, repeated `count` times. Pure (NFR-05).
- **Satisfies:** FR-01, FR-02, FR-04. **Unit tests:** `src/test/GreetingTest.hs`.

### 3.4 `DpHello.Diagnostics.renderUsageError`

- **Signature:** `renderUsageError :: UsageError -> String`
- **Responsibility:** the exact stderr text of §2.4 (CONV-13 … CONV-15; values inserted
  verbatim, an empty value as `''`). **Unit tests:** the `app: …` error cases in `AppTest.hs`.

### 3.5 `DpHello.App.run`

- **Signature:** `run :: [String] -> Outcome`
- **Algorithm:** `parseArgs`; on `ShowHelp`/`ShowVersion` return the text with status 0; on
  `Greet inv` run `validate`, then `greetingText`; any `UsageError` → empty stdout, rendered
  stderr, status 2.
- **Satisfies:** FR-01 … FR-11. **Unit tests:** `src/test/AppTest.hs`.

### 3.6 `DpHello.Output.configureHandle`, `emit`; `Main.main`

- **Signatures:** `configureHandle :: Handle -> IO ()`; `emit :: Handle -> String -> IO Bool`
- **Responsibility:** binary mode + UTF-8 (round-trip) encoding; write and flush, returning
  `False` on an `IOException` (EPIPE, CONV-25).
- **`main`:** `setFileSystemEncoding utf8Roundtrip`, `getArgs`, `run`, configure both handles,
  emit stdout (on failure exit 1 silently), emit stderr, exit with `outStatus`.
- **Satisfies:** CONV-03, CONV-05, CONV-06, CONV-25. **Unit tests:** `src/test/OutputTest.hs`.

## 4. Algorithms

The only non-trivial algorithm is the scan (§3.1). It is a single recursive pass with an
accumulator (`Invocation`), so "last wins" (CONV-11) is replacement and "first of
`--help`/`--version` wins" is an early return. Because values are recorded and not checked,
`--count 0 --help` and `extra --help` print the help, while `-x --help` fails (CONV-12).
dp-hello has no flag-only short options, so a bundle's first letter is always either a
value option (consuming the rest of the token) or invalid.

## 5. Platform-specific details

| Concern             | Linux                       | macOS                  | Windows                      | Abstraction                                                 |
| :------------------ | :-------------------------- | :--------------------- | :--------------------------- | :---------------------------------------------------------- |
| Newline translation | none                        | none                   | GHC text mode writes CRLF    | `hSetBinaryMode True` in `Output.configureHandle`           |
| Argument decoding   | bytes, locale encoding      | bytes, locale encoding | UTF-16 via `GetCommandLineW` | `setFileSystemEncoding (mkUTF8 RoundtripFailure)` in `Main` |
| Output encoding     | locale                      | locale                 | code page                    | `hSetEncoding h (mkUTF8 RoundtripFailure)`                  |
| Broken pipe         | EPIPE (GHC ignores SIGPIPE) | same                   | `ERROR_NO_DATA`              | `IOException` caught in `Output.emit`                       |
| Executable name     | `bin/dp-hello`              | `bin/dp-hello`         | `bin/dp-hello.exe`           | `$(EXE)` in the Makefile                                    |

## 6. Resource management

No files, sockets, or child processes. The output `String` is produced lazily and consumed by
the handle's buffer, so memory stays constant in COUNT (peak RSS about 10 MiB, dominated by
the GHC runtime). Handles are flushed explicitly; the runtime closes them at exit.

## 7. Sequence of one invocation

P06 `dp-hello -c2 -n Ken`: `main` → `getArgs` = `["-c2","-n","Ken"]` → `run` →
`parseArgs`: `-c2` records `OptionValue "-c" "2"`; `-n` takes `Ken` →
`Greet (Invocation (Just (OptionValue "-n" "Ken")) (Just (OptionValue "-c" "2")) [])` →
`validate` → `Config "Ken" 2` → `greetingText "Ken" 2` = `"Hello, Ken!\nHello, Ken!\n"` →
`Outcome text "" 0` → `emit stdout` → `exitWith ExitSuccess`.

## 8. Design-to-code checklist

| HLD component | LLD section | Source file(s)                                 | Unit-test file(s)          |
| :------------ | :---------- | :--------------------------------------------- | :------------------------- |
| Cli           | §3.1        | `src/lib/DpHello/Cli.hs`                       | `src/test/CliTest.hs`      |
| Validate      | §3.2        | `src/lib/DpHello/Validate.hs`                  | `src/test/ValidateTest.hs` |
| Greeting      | §3.3        | `src/lib/DpHello/Greeting.hs`                  | `src/test/GreetingTest.hs` |
| Diagnostics   | §3.4        | `src/lib/DpHello/Diagnostics.hs`               | `src/test/AppTest.hs`      |
| App           | §3.5        | `src/lib/DpHello/App.hs`                       | `src/test/AppTest.hs`      |
| Output, Main  | §3.6        | `src/lib/DpHello/Output.hs`, `src/app/Main.hs` | `src/test/OutputTest.hs`   |
