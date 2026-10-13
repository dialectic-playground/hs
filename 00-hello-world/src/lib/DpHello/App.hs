-- | The pure core of dp-hello: arguments in, the exact standard output, standard error,
-- and exit status out. "Main" only performs the I/O.
module DpHello.App
  ( Outcome (..),
    run,
    helpText,
    versionText,
  )
where

import DpHello.Cli (Action (..), parseArgs)
import DpHello.Diagnostics (UsageError, renderUsageError)
import DpHello.Greeting (greetingText)
import DpHello.Validate (Config (..), validate)

-- | Everything one invocation produces. Usage errors leave 'outStdout' empty (FR-11).
data Outcome = Outcome
  { outStdout :: String,
    outStderr :: String,
    outStatus :: Int
  }
  deriving (Eq, Show)

-- | Scan (CONV-12), then validate, then build the greeting.
run :: [String] -> Outcome
run args = case parseArgs args of
  Left err -> usageError err
  Right ShowHelp -> success helpText
  Right ShowVersion -> success versionText
  Right (Greet inv) -> case validate inv of
    Left err -> usageError err
    Right (Config name count) -> success (greetingText name count)
  where
    success text = Outcome text "" 0
    usageError :: UsageError -> Outcome
    usageError err = Outcome "" (renderUsageError err) 2

-- | The help text, byte-for-byte from the user manual (FR-07, CONV-23).
helpText :: String
helpText =
  unlines
    [ "Usage: dp-hello [OPTION]...",
      "Print a greeting to standard output.",
      "",
      "Options:",
      "  -n, --name=NAME     greet NAME instead of World",
      "  -c, --count=COUNT   print the greeting COUNT times (1-1000, default 1)",
      "      --help          display this help and exit",
      "      --version       output version information and exit"
    ]

-- | The version line (FR-08, CONV-02).
versionText :: String
versionText = "dp-hello (dialectic-playground) 1.0.0\n"
