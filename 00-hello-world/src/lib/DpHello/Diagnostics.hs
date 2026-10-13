-- | Usage errors and their exact diagnostics (CONV-13, CONV-14, CONV-15). This is the only
-- place where an error becomes text.
module DpHello.Diagnostics
  ( programName,
    UsageError (..),
    renderUsageError,
  )
where

-- | The canonical name used in every message (CONV-01), never @argv[0]@.
programName :: String
programName = "dp-hello"

-- | Every usage error dp-hello can report (SRS section 6). Each one exits with status 2.
data UsageError
  = -- | An unknown short option letter, e.g. @-x@.
    InvalidOption Char
  | -- | An unknown or abbreviated long option, as the full token (including any @=value@).
    UnrecognizedOption String
  | -- | A short option (@-n@, @-c@) at the end of the arguments, without its value.
    MissingShortArgument Char
  | -- | A long option (@--name@, @--count@) at the end of the arguments, without its value.
    MissingLongArgument String
  | -- | @--help=…@ or @--version=…@: the long option name, e.g. @--help@.
    UnexpectedArgument String
  | -- | An invalid value: the value and the option as the user wrote it (@-n@, @--count@).
    InvalidArgument String String
  | -- | The first operand.
    ExtraOperand String
  deriving (Eq, Show)

-- | The complete standard-error text for a usage error: the diagnostic line and the
-- @Try ...@ line, each ending in LF.
renderUsageError :: UsageError -> String
renderUsageError err =
  programName
    <> ": "
    <> message err
    <> "\nTry '"
    <> programName
    <> " --help' for more information.\n"

message :: UsageError -> String
message (InvalidOption letter) = "invalid option -- '" <> [letter] <> "'"
message (UnrecognizedOption token) = "unrecognized option '" <> token <> "'"
message (MissingShortArgument letter) = "option requires an argument -- '" <> [letter] <> "'"
message (MissingLongArgument option) = "option '" <> option <> "' requires an argument"
message (UnexpectedArgument option) = "option '" <> option <> "' doesn't allow an argument"
message (InvalidArgument value option) = "invalid argument '" <> value <> "' for '" <> option <> "'"
message (ExtraOperand operand) = "extra operand '" <> operand <> "'"
