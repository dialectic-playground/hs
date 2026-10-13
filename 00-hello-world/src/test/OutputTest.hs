-- | The output adapter writes UTF-8 bytes with LF line endings only (CONV-03, CONV-05).
module OutputTest (tests) where

import Control.Exception (bracket)
import DpHello.Output (configureHandle, emit)
import System.Directory (getTemporaryDirectory, removeFile)
import System.IO
import TestKit

-- | Write @text@ through a configured handle into a temporary file and return whether 'emit'
-- succeeded and the file's bytes (each byte as a Char in 0..255).
bytesWritten :: String -> IO (Bool, String)
bytesWritten text = do
  dir <- getTemporaryDirectory
  bracket (openTempFile dir "dp-hello-output.tmp") release $ \(path, handle) -> do
    configureHandle handle
    written <- emit handle text
    hClose handle
    bytes <- withBinaryFile path ReadMode $ \h -> do
      contents <- hGetContents h
      length contents `seq` pure contents
    pure (written, bytes)
  where
    release (path, handle) = hClose handle >> removeFile path

tests :: [Test]
tests =
  [ test "output: LF is not translated" $
      bytesWritten "a\nb\n" >>= assertEqual (True, "a\nb\n"),
    test "output: text is encoded as UTF-8" $
      bytesWritten "Zo\235\n" >>= assertEqual (True, "Zo\xC3\xAB\n"),
    test "output: undecodable argument bytes are written back unchanged" $
      bytesWritten "\xDCFF\n" >>= assertEqual (True, "\xFF\n"),
    test "output: nothing to write" $
      bytesWritten "" >>= assertEqual (True, "")
  ]
