-- | Validation (FR-03, FR-04, FR-05, FR-06, FR-09).
module ValidateTest (tests) where

import DpHello.Cli (Invocation (..), OptionValue (..), emptyInvocation)
import DpHello.Diagnostics (UsageError (..))
import DpHello.Validate
import TestKit

withCount :: String -> String -> Invocation
withCount option value = emptyInvocation {invCount = Just (OptionValue option value)}

count :: String -> Maybe Int -> Test
count text expected = test ("validate: parseCount " <> show text) (assertEqual expected (parseCount text))

tests :: [Test]
tests =
  [ test "validate: defaults" $
      assertEqual (Right (Config "World" 1)) (validate emptyInvocation),
    test "validate: name" $
      assertEqual (Right (Config "Ada Lovelace" 1)) (validate emptyInvocation {invName = Just (OptionValue "-n" "Ada Lovelace")}),
    test "validate: empty name, short" $
      assertEqual (Left (InvalidArgument "" "-n")) (validate emptyInvocation {invName = Just (OptionValue "-n" "")}),
    test "validate: empty name, long" $
      assertEqual (Left (InvalidArgument "" "--name")) (validate emptyInvocation {invName = Just (OptionValue "--name" "")}),
    test "validate: count" $
      assertEqual (Right (Config "World" 3)) (validate (withCount "--count" "3")),
    test "validate: invalid count, as written" $
      assertEqual (Left (InvalidArgument "0" "-c")) (validate (withCount "-c" "0")),
    test "validate: invalid count, long" $
      assertEqual (Left (InvalidArgument "1001" "--count")) (validate (withCount "--count" "1001")),
    test "validate: the first operand is reported" $
      assertEqual (Left (ExtraOperand "a")) (validate emptyInvocation {invOperands = ["a", "b"]}),
    test "validate: an operand before an invalid value" $
      assertEqual (Left (ExtraOperand "x")) (validate (withCount "-c" "0") {invOperands = ["x"]}),
    test "validate: an empty name before an invalid count" $
      assertEqual
        (Left (InvalidArgument "" "-n"))
        (validate (withCount "-c" "0") {invName = Just (OptionValue "-n" "")}),
    count "1" (Just 1),
    count "1000" (Just 1000),
    count "0" Nothing,
    count "1001" Nothing,
    count "007" (Just 7),
    count "0001000" (Just 1000),
    count "000" Nothing,
    count "" Nothing,
    count "abc" Nothing,
    count "-1" Nothing,
    count "+1" Nothing,
    count " 1" Nothing,
    count "1 " Nothing,
    count "1.0" Nothing,
    count "1e2" Nothing,
    count "\1633" Nothing, -- ARABIC-INDIC DIGIT THREE is not an ASCII digit
    count "99999999999999999999999999" Nothing
  ]
