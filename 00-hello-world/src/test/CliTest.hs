-- | Parsing (CONV-07 ... CONV-12, FR-02, FR-06, FR-07, FR-08, FR-10).
module CliTest (tests) where

import DpHello.Cli
import DpHello.Diagnostics (UsageError (..))
import TestKit

greet :: Maybe (String, String) -> Maybe (String, String) -> [String] -> Either UsageError Action
greet name count operands =
  Right (Greet (Invocation (uncurry OptionValue <$> name) (uncurry OptionValue <$> count) operands))

parses :: String -> [String] -> Either UsageError Action -> Test
parses name args expected = test ("cli: " <> name) (assertEqual expected (parseArgs args))

tests :: [Test]
tests =
  [ parses "no arguments" [] (greet Nothing Nothing []),
    parses "short name, separate value" ["-n", "Ada"] (greet (Just ("-n", "Ada")) Nothing []),
    parses "short name, attached value" ["-nAda"] (greet (Just ("-n", "Ada")) Nothing []),
    parses "long name, separate value" ["--name", "Ada"] (greet (Just ("--name", "Ada")) Nothing []),
    parses "long name, = value" ["--name=Ada"] (greet (Just ("--name", "Ada")) Nothing []),
    parses "long name, empty = value" ["--name="] (greet (Just ("--name", "")) Nothing []),
    parses "long name, = inside value" ["--name=a=b"] (greet (Just ("--name", "a=b")) Nothing []),
    parses "value may start with -" ["--name", "-x"] (greet (Just ("--name", "-x")) Nothing []),
    parses "attached value may start with -" ["-n-x"] (greet (Just ("-n", "-x")) Nothing []),
    parses "value may be --help" ["-n", "--help"] (greet (Just ("-n", "--help")) Nothing []),
    parses "bundled count then name" ["-c2", "-nKen"] (greet (Just ("-n", "Ken")) (Just ("-c", "2")) []),
    parses "a short option consumes the rest of the token" ["-cn2"] (greet Nothing (Just ("-c", "n2")) []),
    parses "long count" ["--count", "3"] (greet Nothing (Just ("--count", "3")) []),
    parses "last name wins" ["-n", "A", "--name=B"] (greet (Just ("--name", "B")) Nothing []),
    parses "last count wins" ["-c", "0", "-c", "5"] (greet Nothing (Just ("-c", "5")) []),
    parses "non-ASCII value" ["--name", "Zo\235"] (greet (Just ("--name", "Zo\235")) Nothing []),
    parses "operands are collected in order" ["a", "-n", "X", "b"] (greet (Just ("-n", "X")) Nothing ["a", "b"]),
    parses "a lone - is an operand" ["-"] (greet Nothing Nothing ["-"]),
    parses "-- ends options" ["--", "-n", "x"] (greet Nothing Nothing ["-n", "x"]),
    parses "-- after an operand keeps the order" ["a", "--", "b"] (greet Nothing Nothing ["a", "b"]),
    parses "a second -- is an operand" ["--", "--"] (greet Nothing Nothing ["--"]),
    parses "--help" ["--help"] (Right ShowHelp),
    parses "--version" ["--version"] (Right ShowVersion),
    parses "the first of --help/--version wins" ["--version", "--help"] (Right ShowVersion),
    parses "--help stops the scan" ["--help", "extra", "-x"] (Right ShowHelp),
    parses "an operand before --help" ["extra", "--help"] (Right ShowHelp),
    parses "an invalid value before --help" ["--count", "0", "--help"] (Right ShowHelp),
    parses "--help after -- is an operand" ["--", "--help"] (greet Nothing Nothing ["--help"]),
    parses "unknown short option" ["-x"] (Left (InvalidOption 'x')),
    parses "unknown short option before --help" ["-x", "--help"] (Left (InvalidOption 'x')),
    parses "unknown non-ASCII short option" ["-\235"] (Left (InvalidOption '\235')),
    parses "unknown long option" ["--nme", "Ada"] (Left (UnrecognizedOption "--nme")),
    parses "abbreviations are rejected" ["--nam=Ada"] (Left (UnrecognizedOption "--nam=Ada")),
    parses "--= is unrecognized" ["--=x"] (Left (UnrecognizedOption "--=x")),
    parses "-n without a value" ["-n"] (Left (MissingShortArgument 'n')),
    parses "-c without a value" ["-c"] (Left (MissingShortArgument 'c')),
    parses "--name without a value" ["--name"] (Left (MissingLongArgument "--name")),
    parses "--count without a value" ["--count"] (Left (MissingLongArgument "--count")),
    parses "--help=x" ["--help=x"] (Left (UnexpectedArgument "--help")),
    parses "--version=1" ["--version=1"] (Left (UnexpectedArgument "--version")),
    parses "--version= (empty)" ["--version="] (Left (UnexpectedArgument "--version"))
  ]
