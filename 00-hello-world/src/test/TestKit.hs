-- | A minimal assertion runner (base only): named checks, a failure report, an exit status.
module TestKit
  ( Test,
    test,
    assertEqual,
    runTests,
  )
where

import Control.Monad (unless)
import System.Exit (exitFailure)

-- | A named check; 'Nothing' means it passed, 'Just' carries the failure message.
data Test = Test String (IO (Maybe String))

-- | A named check.
test :: String -> IO (Maybe String) -> Test
test = Test

-- | Pass when the two values are equal.
assertEqual :: (Eq a, Show a) => a -> a -> IO (Maybe String)
assertEqual expected actual
  | expected == actual = pure Nothing
  | otherwise = pure (Just ("expected " <> show expected <> "\n     got " <> show actual))

-- | Run every test, print each failure, and exit non-zero if any failed.
runTests :: [Test] -> IO ()
runTests tests = do
  failures <- concat <$> mapM runOne tests
  putStrLn (show (length tests - length failures) <> "/" <> show (length tests) <> " unit tests passed")
  unless (null failures) exitFailure
  where
    runOne (Test name check) = do
      result <- check
      case result of
        Nothing -> pure []
        Just why -> do
          putStrLn ("FAIL " <> name <> "\n     " <> why)
          pure [name]
