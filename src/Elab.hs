module Elab
  ( elaborate
      -- elabora a un término
  )
where

import           Data.List hiding (null)
import           Data.Maybe
import qualified Data.Set as Set 
import           Prelude                 hiding ( (>>=), null )
import           Common
import           Debug.Trace (trace)
import           Control.Monad
import           Control.Monad.Except

 
normalizePair :: (Name,Name) -> (Name,Name)
normalizePair (x,y) = (min x y, max x y)

toGraph :: [(Name,[Name])] -> Bool -> Graph
toGraph ns True = let v = Set.union (Set.fromList (map fst ns)) (Set.fromList (concat (map snd ns)))
                      e = Set.fromList $ concatMap (\(x,ys) -> map (\y -> (x,y)) ys) ns
                  in G v e
toGraph ns False = let v = Set.union (Set.fromList (map fst ns)) (Set.fromList (concat (map snd ns)))
                       e = Set.fromList $ concatMap (\(x,ys) -> map (\y -> normalizePair (x,y)) ys) ns
                   in G v e

defaultProperties :: String -> Bool -> Properties
defaultProperties n b = P {name = n, directed = b, conex = False, weighted = False, path = []}

elaborate :: String -> STerm -> Term
elaborate n (SGraph (DirectedGraph ns)) = Graph (toGraph ns True) (defaultProperties n True)
elaborate n (SGraph (UndirectedGraph ns)) = Graph (toGraph ns False) (defaultProperties n False)
elaborate n (SGraph EmptyGraph) = Graph (G Set.empty Set.empty) (defaultProperties n True)
elaborate n (SUnion t1 t2) = Union (elaborate n t1) (elaborate n t2)
elaborate n (SIntersect t1 t2) = Intersect (elaborate n t1) (elaborate n t2)
elaborate n (SK t) = K (elaborate n t)
elaborate n (SEuler t) = Euler (elaborate n t)
elaborate n (SHamilton t) = Hamilton (elaborate n t)
elaborate _ (SVar v) = V (Global v)
elaborate n (SDiff t1 t2) = Diff (elaborate n t1) (elaborate n t2)




