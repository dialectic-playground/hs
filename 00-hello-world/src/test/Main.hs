-- | Unit tests for dp-hello: one module per unit (NFR-04, NFR-05).
module Main (main) where

import AppTest qualified
import CliTest qualified
import GreetingTest qualified
import OutputTest qualified
import TestKit (runTests)
import ValidateTest qualified

main :: IO ()
main =
  runTests
    ( CliTest.tests
        <> ValidateTest.tests
        <> GreetingTest.tests
        <> AppTest.tests
        <> OutputTest.tests
    )
