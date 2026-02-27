{-# LANGUAGE ScopedTypeVariables #-}
import System.Environment
import Data.List
import qualified Data.Map as Map

split :: Char -> String -> [String]
split _ [] = []
split c s = firstWord : split c rest
  where
    firstWord = takeWhile (/= c) s
    rest = drop 1 (dropWhile (/= c) s)

avg :: [Float] -> Float
avg xs = sum xs / fromIntegral (length xs)

-- Parse sequential CSV
parseSeq :: String -> (Int, Float)
parseSeq line =
    let vals = split ',' line
        input = read (vals !! 0)
        runs  = map read (drop 1 vals)
    in (input, avg runs)

-- Parse parallel CSV
parsePar :: String -> (Int, Int, Float)
parsePar line =
    let vals = split ',' line
        input = read (vals !! 0)
        cores = read (vals !! 1)
        runs  = map read (drop 2 vals)
    in (input, cores, avg runs)

processFiles :: String -> String -> IO ()
processFiles seqFile parFile = do
    seqContent <- readFile seqFile
    parContent <- readFile parFile

    let seqData = Map.fromList $
                  map parseSeq (tail (lines seqContent))

        parData = map parsePar (tail (lines parContent))

        results = map (compute seqData) parData

        header = "input,cores,avgRun,speedup,efficiency\n"
        body   = unlines (map format results)

    writeFile "output.csv" (header ++ body)

compute :: Map.Map Int Float -> (Int, Int, Float)
        -> (Int, Int, Float, Float, Float)
compute seqMap (input, cores, tPar) =
    let tSeq = seqMap Map.! input
        sp   = tSeq / tPar
        eff  = sp / fromIntegral cores
    in (input, cores, tPar, sp, eff)

format :: (Int, Int, Float, Float, Float) -> String
format (i,c,t,sp,eff) =
    intercalate "," [show i, show c, show t, show sp, show eff]

main :: IO ()
main = do
    args <- getArgs
    case args of
        [seqFile, parFile] -> processFiles seqFile parFile
        _ -> error "Usage: program <runtime_seq.csv> <runtime_par.csv>"
