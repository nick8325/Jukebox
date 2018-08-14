{-# LANGUAGE CPP #-}
module Main where

import Control.Monad
import Jukebox.Options
import Jukebox.Toolbox
import Jukebox.Form
#if __GLASGOW_HASKELL__ < 710
import Control.Applicative
import Data.Monoid
#endif
import Data.List
import System.Exit
import System.Environment

main = do
  prog <- getProgName
  args <- getArgs
  let
    progTool = prog ++ " <toolname>"
    help =
      printHelp ExitSuccess $
        intercalate [""] $
          [usageText progTool "Jukebox, a first-order logic toolbox"] ++
          [["<toolname> can be any of the following:"] ++
           [ "  " ++ name tool ++ " - " ++ description tool
           | tool <- tools, name tool `notElem` map name internal ]] ++
          [["For more information about each tool, run " ++ progTool ++ " --help."]]
    usage msg = printError prog msg
  case args of
    [] -> help
    ["help"] -> help
    ["--help"] -> help
    ["--version"] ->
      putStrLn $ "Jukebox version " ++ VERSION_jukebox
    (('-':_):_) -> usage "Expected a tool name as first argument"
    (arg:args) ->
      case [tool | tool <- tools, name tool == arg] of
        [] -> usage ("No such tool " ++ arg)
        [tool] ->
          join $
            parseCommandLineWithArgs
              (prog ++ " " ++ name tool) args (description tool) (pipeline tool)

data Tool =
  Tool {
    name :: String,
    description :: String,
    pipeline :: OptionParser (IO ()) }

tools = external ++ internal
external = [fof, cnf, uncnf, smt, monotonox, hornToUnit, inferTypes]
internal = [guessmodel, parse]

fof =
  Tool "fof" "Translate a problem from TFF (typed) to FOF (untyped)" $
    forAllFilesBox <*>
      (readProblemBox =>>=
       toFofBox =>>=
       printProblemBox)

monotonox =
  Tool "monotonox" "Analyse a problem for monotonicity" $
    forAllFilesBox <*>
      (readProblemBox =>>=
       clausifyBox =>>=
       oneConjectureBox =>>=
       showMonotonicityBox =>>=
       writeFileBox)

smt =
  Tool "smt" "Translate a problem from TPTP format to SMTLIB format" $
    forAllFilesBox <*>
      (readProblemBox =>>=
       printProblemSMTBox)

cnf =
  Tool "cnf" "Clausify a TPTP (TFF or FOF) problem" $
    forAllFilesBox <*>
      (readProblemBox =>>=
       clausifyBox =>>=
       oneConjectureBox =>>=
       printClausesBox)

uncnf =
  Tool "uncnf" "Introduce explicit quantification into a problem" $
    forAllFilesBox <*>
      (readProblemBox =>>=
       printProblemBox)

inferTypes =
  Tool "infer-types" "Infer types" $
    forAllFilesBox <*>
      (readProblemBox =>>=
       clausifyBox =>>=
       oneConjectureBox =>>=
       inferBox =>>=
       printInferredBox =>>=
       printClausesBox)

guessmodel =
  Tool "guessmodel" "Guess an infinite model (internal use)" $
    forAllFilesBox <*>
      (readProblemBox =>>=
       guessModelBox =>>=
       printProblemBox)

hornToUnit =
  Tool "horn-to-unit" "Encode a Horn problem as unit equality" $
    forAllFilesBox <*>
      (readProblemBox =>>=
       clausifyBox =>>=
       oneConjectureBox =>>=
       hornToUnitBox =>>=
       (printAnswerOr <$> printClausesBox))
  where
    printAnswerOr _ (Left answer) = do
      mapM_ putStrLn (answerSZS answer)
    printAnswerOr printClauses (Right clauses) =
      printClauses clauses

parse =
  Tool "parse" "Parse the problem and exit (internal use)" $
    forAllFilesBox <*>
      (readProblemBox =>>=
       pure (const (return ())))
