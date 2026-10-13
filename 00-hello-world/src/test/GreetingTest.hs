-- | Greeting construction (FR-01, FR-02, FR-04, NFR-05).
module GreetingTest (tests) where

import DpHello.Greeting
import TestKit

tests :: [Test]
tests =
  [ test "greeting: default name" $ assertEqual "Hello, World!\n" (greetingLine "World"),
    test "greeting: name verbatim" $ assertEqual "Hello, Ada Lovelace!\n" (greetingLine "Ada Lovelace"),
    test "greeting: non-ASCII name" $ assertEqual "Hello, Zo\235!\n" (greetingLine "Zo\235"),
    test "greeting: punctuation kept" $ assertEqual "Hello, -x!!\n" (greetingLine "-x!"),
    test "greeting: one line" $ assertEqual "Hello, A!\n" (greetingText "A" 1),
    test "greeting: three lines" $ assertEqual "Hello, A!\nHello, A!\nHello, A!\n" (greetingText "A" 3),
    test "greeting: 1000 lines" $
      assertEqual (1000, 1000 * length "Hello, B!\n") (let t = greetingText "B" 1000 in (length (lines t), length t))
  ]
