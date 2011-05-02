module Formula where

import AppList(AppList)
import qualified Data.Set
import Data.Set(Set)
import Data.Map(Map)
import Data.Ord
import qualified Data.ByteString.Char8 as BS

type Name = BS.ByteString -- for now

data DomainSize = Finite !Int | Infinite deriving (Eq, Ord) 

data Type = Type
  { tname :: !Name,
    -- type is monotone when domain size is >= tmonotone
    tmonotone :: !DomainSize,
    -- if there is a model of size >= tsize then there is a model of size tsize
    tsize :: !DomainSize }

instance Eq Type where
  t1 == t2 = tname t1 == tname t2

instance Ord Type where
  compare = comparing tname

data Function = Function
  { fname :: !Name,
    fres :: !Type }

data Predicate = Predicate { pname :: !Name }

data Variable = Variable { vname :: !Name, vtype :: !Type }

data Problem a = Problem
  { types :: Set Type,
    preds :: Map [Type] Predicate,
    funs :: Map [Type] Function,
    inputs :: [Input a] }

data Input a = Input
  { kind :: !Kind
  , tag :: !Name
  , formula :: !a }

data Term = Var !Variable | !Function :@: [Term] -- use vectors for this?
data Atom = Term :=: Term | !Predicate :?: [Term]
data Signed a = Pos !a | Neg !a
type Literal = Signed Atom

data Formula
  = Literal !Literal
  | And !(AppList Formula)
  | Or !(AppList Formula)
  | Equiv !Formula !Formula
  | ForAll !(Set Variable) !Formula
  | Exists !(Set Variable) !Formula

data Kind = Axiom | Conjecture deriving (Eq, Ord, Show)
