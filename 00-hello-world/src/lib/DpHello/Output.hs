-- | The output adapter: the only module that touches standard output and standard error.
-- Both are switched to binary mode, so LF is never translated to CRLF on Windows (CONV-03),
-- and text is encoded as UTF-8 regardless of the locale (CONV-05, CONV-06).
module DpHello.Output
  ( utf8Roundtrip,
    configureHandle,
    emit,
  )
where

import Control.Exception (IOException, try)
import GHC.IO.Encoding (TextEncoding)
import GHC.IO.Encoding.Failure (CodingFailureMode (RoundtripFailure))
import GHC.IO.Encoding.UTF8 (mkUTF8)
import System.IO (Handle, hFlush, hPutStr, hSetBinaryMode, hSetEncoding)

-- | UTF-8 that also round-trips undecodable argument bytes: on POSIX, bytes that are not
-- valid UTF-8 are decoded to escape characters and written back as the same bytes.
utf8Roundtrip :: TextEncoding
utf8Roundtrip = mkUTF8 RoundtripFailure

-- | Binary mode (no newline translation), then UTF-8 encoding.
configureHandle :: Handle -> IO ()
configureHandle handle = do
  hSetBinaryMode handle True
  hSetEncoding handle utf8Roundtrip

-- | Write @text@ to @handle@ and flush it. Returns 'False' when the write fails, for example
-- with EPIPE when the reader has gone away (CONV-25); the caller then exits without a
-- diagnostic.
emit :: Handle -> String -> IO Bool
emit _ "" = pure True
emit handle text = do
  result <- try (hPutStr handle text >> hFlush handle) :: IO (Either IOException ())
  pure (either (const False) (const True) result)
