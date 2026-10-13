-- | The hand-written command-line scanner (CONV-07 ... CONV-12). It only recognizes option
-- syntax: values are recorded as written and operands collected; their validity is decided
-- afterwards by "DpHello.Validate".
module DpHello.Cli
  ( OptionValue (..),
    Invocation (..),
    Action (..),
    emptyInvocation,
    parseArgs,
  )
where

import DpHello.Diagnostics (UsageError (..))

-- | An option value together with the option as the user wrote it (@-n@ or @--name@), which
-- the diagnostics need (CONV-13).
data OptionValue = OptionValue
  { optionWritten :: String,
    optionText :: String
  }
  deriving (Eq, Show)

-- | The raw result of a complete scan: the last @--name@ and @--count@ (CONV-11) and every
-- operand in order.
data Invocation = Invocation
  { invName :: Maybe OptionValue,
    invCount :: Maybe OptionValue,
    invOperands :: [String]
  }
  deriving (Eq, Show)

-- | What the scan decided.
data Action
  = -- | @--help@ was reached first (CONV-12).
    ShowHelp
  | -- | @--version@ was reached first (CONV-12).
    ShowVersion
  | -- | The whole list was scanned without a syntax error.
    Greet Invocation
  deriving (Eq, Show)

-- | No options, no operands.
emptyInvocation :: Invocation
emptyInvocation = Invocation Nothing Nothing []

-- | The value-taking options, by short letter and by long name.
data ValueOption = NameOption | CountOption

shortOption :: Char -> Maybe ValueOption
shortOption 'n' = Just NameOption
shortOption 'c' = Just CountOption
shortOption _ = Nothing

longOption :: String -> Maybe ValueOption
longOption "name" = Just NameOption
longOption "count" = Just CountOption
longOption _ = Nothing

-- | Record a value; a later occurrence replaces an earlier one (CONV-11).
record :: ValueOption -> OptionValue -> Invocation -> Invocation
record NameOption value inv = inv {invName = Just value}
record CountOption value inv = inv {invCount = Just value}

-- | Scan the arguments from left to right (CONV-12). The first @--help@ or @--version@ wins
-- unless an option syntax error comes before it.
parseArgs :: [String] -> Either UsageError Action
parseArgs = go emptyInvocation
  where
    go inv [] = Right (Greet (finish inv))
    go inv ("--" : rest) = Right (Greet (finish inv {invOperands = reverse rest <> invOperands inv}))
    go inv (token : rest) = case token of
      '-' : '-' : long -> longToken inv token long rest
      '-' : letter : attached -> shortToken inv letter attached rest
      _ -> go inv {invOperands = token : invOperands inv} rest

    -- "--name=VALUE", "--name VALUE", "--help", "--version", or an unrecognized option.
    longToken inv token long rest =
      let (name, suffix) = break (== '=') long
          option = "--" <> name
       in case (name, suffix, longOption name) of
            ("help", "", _) -> Right ShowHelp
            ("version", "", _) -> Right ShowVersion
            ("help", _, _) -> Left (UnexpectedArgument option)
            ("version", _, _) -> Left (UnexpectedArgument option)
            (_, '=' : value, Just opt) -> go (record opt (OptionValue option value) inv) rest
            (_, _, Just opt) -> case rest of
              value : rest' -> go (record opt (OptionValue option value) inv) rest'
              [] -> Left (MissingLongArgument option)
            (_, _, Nothing) -> Left (UnrecognizedOption token)

    -- "-nVALUE" or "-n VALUE". dp-hello has no flag-only short options, so the first letter
    -- either takes the rest of the token as its value or is invalid (CONV-07).
    shortToken inv letter attached rest =
      let option = ['-', letter]
       in case shortOption letter of
            Nothing -> Left (InvalidOption letter)
            Just opt
              | not (null attached) -> go (record opt (OptionValue option attached) inv) rest
              | value : rest' <- rest -> go (record opt (OptionValue option value) inv) rest'
              | otherwise -> Left (MissingShortArgument letter)

    finish inv = inv {invOperands = reverse (invOperands inv)}
