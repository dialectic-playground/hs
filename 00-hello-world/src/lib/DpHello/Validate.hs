-- | Validation of a scanned invocation (FR-03, FR-05, FR-06, FR-09). Runs only after the
-- whole argument list has been scanned (CONV-12).
module DpHello.Validate
  ( Config (..),
    defaultName,
    defaultCount,
    minCount,
    maxCount,
    validate,
    parseCount,
  )
where

import Data.Char (isDigit, ord)
import DpHello.Cli (Invocation (..), OptionValue (..))
import DpHello.Diagnostics (UsageError (..))

-- | A validated greeting request: a non-empty name and a count in
-- ['minCount', 'maxCount'].
data Config = Config
  { cfgName :: String,
    cfgCount :: Int
  }
  deriving (Eq, Show)

-- | Greeted when @--name@ is absent (FR-01).
defaultName :: String
defaultName = "World"

-- | Lines printed when @--count@ is absent.
defaultCount :: Int
defaultCount = 1

-- | The bounds of COUNT (FR-04).
minCount, maxCount :: Int
minCount = 1
maxCount = 1000

-- | Check a scanned invocation: the first operand (FR-09), then an empty name (FR-03), then
-- an invalid count (FR-05). Only the last occurrence of each option is present, so earlier
-- values are never validated (FR-06).
validate :: Invocation -> Either UsageError Config
validate inv = do
  case invOperands inv of
    operand : _ -> Left (ExtraOperand operand)
    [] -> Right ()
  name <- maybe (Right defaultName) checkName (invName inv)
  count <- maybe (Right defaultCount) checkCount (invCount inv)
  pure (Config name count)
  where
    checkName (OptionValue option value)
      | null value = Left (InvalidArgument value option)
      | otherwise = Right value
    checkCount (OptionValue option value) =
      maybe (Left (InvalidArgument value option)) Right (parseCount value)

-- | COUNT as an integer: one or more ASCII digits (leading zeros allowed) with a value in
-- ['minCount', 'maxCount']. Arbitrarily long digit strings cannot overflow: accumulation
-- saturates just above 'maxCount'.
parseCount :: String -> Maybe Int
parseCount text
  | null text || not (all isDigit text) = Nothing -- isDigit accepts only '0'..'9'
  | value < minCount || value > maxCount = Nothing
  | otherwise = Just value
  where
    value = foldl' step 0 text
    step acc digit = min (maxCount + 1) (acc * 10 + ord digit - ord '0')
