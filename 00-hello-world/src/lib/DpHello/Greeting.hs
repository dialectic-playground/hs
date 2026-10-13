-- | Greeting construction (FR-01, FR-02, FR-04): pure functions, no I/O (NFR-05).
module DpHello.Greeting
  ( greetingLine,
    greetingText,
  )
where

-- | One greeting line: @Hello, @ + name + @!@ + LF (CONV-03).
greetingLine :: String -> String
greetingLine name = "Hello, " <> name <> "!\n"

-- | The complete standard output for greeting @name@ @count@ times.
greetingText :: String -> Int -> String
greetingText name count = concat (replicate count (greetingLine name))
