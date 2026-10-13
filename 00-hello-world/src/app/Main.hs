-- | dp-hello: print a greeting to standard output (curriculum project 00-hello-world).
-- The I/O shell around the pure core in "DpHello.App".
module Main (main) where

import Control.Monad (unless)
import DpHello.App (Outcome (..), run)
import DpHello.Output (configureHandle, emit, utf8Roundtrip)
import GHC.IO.Encoding (setFileSystemEncoding)
import System.Environment (getArgs)
import System.Exit (ExitCode (..), exitWith)
import System.IO (stderr, stdout)

main :: IO ()
main = do
  -- Arguments are UTF-8 on POSIX whatever the locale says (CONV-05, CONV-06); on Windows,
  -- getArgs already decodes the UTF-16 command line.
  setFileSystemEncoding utf8Roundtrip
  args <- getArgs
  let outcome = run args
  mapM_ configureHandle [stdout, stderr]
  written <- emit stdout (outStdout outcome)
  -- A failed write means the reader went away (CONV-25): stop quietly.
  unless written (exitWith (ExitFailure 1))
  _ <- emit stderr (outStderr outcome)
  exitWith (if outStatus outcome == 0 then ExitSuccess else ExitFailure (outStatus outcome))
