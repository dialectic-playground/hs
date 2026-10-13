-- | The pure core end to end: exact stdout, stderr, and status (FR-01 ... FR-11).
module AppTest (tests) where

import DpHello.App
import TestKit

try' :: String
try' = "Try 'dp-hello --help' for more information.\n"

runs :: String -> [String] -> Outcome -> Test
runs name args expected = test ("app: " <> name) (assertEqual expected (run args))

ok :: String -> Outcome
ok out = Outcome out "" 0

usage :: String -> Outcome
usage line = Outcome "" ("dp-hello: " <> line <> "\n" <> try') 2

tests :: [Test]
tests =
  [ runs "default greeting" [] (ok "Hello, World!\n"),
    runs "named greeting" ["--name", "Ada"] (ok "Hello, Ada!\n"),
    runs "UTF-8 name" ["-n", "Zo\235"] (ok "Hello, Zo\235!\n"),
    runs "count and name" ["-c2", "-n", "Ken"] (ok "Hello, Ken!\nHello, Ken!\n"),
    runs "leading zeros" ["--count=003"] (ok "Hello, World!\nHello, World!\nHello, World!\n"),
    runs "last wins, only the winner is validated" ["-c", "0", "-c", "1", "-n", "", "-n", "B"] (ok "Hello, B!\n"),
    runs "help" ["--help"] (ok helpText),
    runs "help after an operand" ["extra", "--help"] (ok helpText),
    runs "help after an invalid count" ["--count", "0", "--help"] (ok helpText),
    runs "version" ["--version"] (ok "dp-hello (dialectic-playground) 1.0.0\n"),
    runs "invalid option" ["-x"] (usage "invalid option -- 'x'"),
    runs "invalid option before help" ["-x", "--help"] (usage "invalid option -- 'x'"),
    runs "unrecognized option" ["--nme", "Ada"] (usage "unrecognized option '--nme'"),
    runs "unrecognized option with value" ["--xyz=1"] (usage "unrecognized option '--xyz=1'"),
    runs "missing short argument" ["-c"] (usage "option requires an argument -- 'c'"),
    runs "missing long argument" ["--name"] (usage "option '--name' requires an argument"),
    runs "help with an argument" ["--help=1"] (usage "option '--help' doesn't allow an argument"),
    runs "version with an argument" ["--version=1"] (usage "option '--version' doesn't allow an argument"),
    runs "empty name" ["--name", ""] (usage "invalid argument '' for '--name'"),
    runs "empty attached name" ["--name="] (usage "invalid argument '' for '--name'"),
    runs "count 0" ["--count", "0"] (usage "invalid argument '0' for '--count'"),
    runs "count 1001" ["-c", "1001"] (usage "invalid argument '1001' for '-c'"),
    runs "count abc" ["-c", "abc"] (usage "invalid argument 'abc' for '-c'"),
    runs "extra operand" ["extra"] (usage "extra operand 'extra'"),
    runs "operand after --" ["--", "-n"] (usage "extra operand '-n'"),
    test "app: help text is exact" $
      assertEqual
        "Usage: dp-hello [OPTION]...\nPrint a greeting to standard output.\n\nOptions:\n\
        \  -n, --name=NAME     greet NAME instead of World\n\
        \  -c, --count=COUNT   print the greeting COUNT times (1-1000, default 1)\n\
        \      --help          display this help and exit\n\
        \      --version       output version information and exit\n"
        helpText
  ]
