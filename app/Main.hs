
{-# LANGUAGE ScopedTypeVariables #-}
import System.Environment 
import Text.Read (readMaybe)
import Data.List 
import System.IO (readFile)

split :: Char -> String -> [String]
split _ [] = []
split c s = firstWord : (split c rest)
  where firstWord = takeWhile (/= c) s
        rest = dropWhile (== c) (drop (length firstWord) s)

speedUp :: Float -> Float -> Float
speedUp ts tp = ts / tp

efficiency :: Float -> Float -> Float
efficiency ts tp = (speedUp ts tp) / ts

--Csv Parser
parseLine :: String -> (Int, Int, Float, Float, Float)
parseLine line = 
    let values = split ',' line
        input  = read (head values) :: Int
        cores  = read (values !! 1) :: Int
        run1   = read (values !! 2) :: Float
        run2   = read (values !! 3) :: Float
        run3   = read (values !! 4) :: Float
    in (input, cores, run1, run2, run3)
       
--File reader
processFile :: String -> IO ()
processFile fileName = do
    content <- readFile fileName
    let linesOfFile = lines content
        parsedData = map parseLine (tail linesOfFile)  -- Ignore header
        results = map (\(input, cores, run1, run2, run3) -> 
                        let avgSeq = (run1 + run2 + run3) / 3
                            speedup = speedUp avgSeq (fromIntegral cores * avgSeq)
                            eff = efficiency avgSeq (fromIntegral cores * avgSeq)
                        in (input, cores, avgSeq, speedup, eff)) parsedData
        newCSV = "input,cores,avgRun,speedup,efficiency\n" ++ 
                 unlines (map (\(i, c, avg, sp, eff) -> 
                    intercalate "," [show i, show c, show avg, show sp, show eff]) results)
    writeFile "output.csv" newCSV

-- Main
main :: IO ()
main = do
    args <- getArgs
    let parallelRuntimeFile = case args of
            [f] -> f
            _ -> error "Too much or not enough args/n"
    processFile parallelRuntimeFile
