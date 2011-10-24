module Main where

import Control.Monad
import Options
import Control.Applicative
import Data.Monoid
import Toolbox

tools = mconcat [fof, cnf, monotonox, justparser]

fof = tool info pipeline
  where
    info = Tool "fof" "Jukebox TFF-to-FOF translator" "1"
                "Translate from TFF to FOF"
    pipeline =
      greetingBox info =>>
      allFilesBox <*>
        (parseProblemBox =>>=
         toFofBox =>>=
         prettyPrintBox <*> pure "fof")

monotonox = tool info pipeline
  where
    info = Tool "monotonox" "Monotonox" "1"
                "Monotonicity analysis"
    pipeline =
      greetingBox info =>>
      allFilesBox <*>
        (parseProblemBox =>>=
         clausifyBox =>>=
         oneConjectureBox =>>=
         monotonicityBox =>>=
         writeFileBox)

cnf = tool info pipeline
  where
    info = Tool "cnf" "Jukebox clausifier" "1"
                "Clausify a problem"
    pipeline =
      greetingBox info =>>
      allFilesBox <*>
        (parseProblemBox =>>=
         clausifyBox =>>=
         oneConjectureBox =>>=
         prettyClauseBox)

justparser = tool info pipeline
  where
    info = Tool "parser" "Parser" "1"
                "Just parse the problem"
    pipeline =
      greetingBox info =>>
      allFilesBox <*>
        (parseProblemBox =>>=
         pure (const (return ())))

jukebox = Tool "jukebox" "Jukebox" "1"
               "A first-order logic toolbox"

main = join (parseCommandLine jukebox tools)
