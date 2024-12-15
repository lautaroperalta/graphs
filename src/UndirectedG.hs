module UndirectedG where

import           Data.List hiding (null)
import           Data.Maybe
import qualified Data.Set as Set 
import           Prelude                 hiding ( (>>=), null )
import           Common
import           Debug.Trace (trace)
import           Control.Monad
import           Control.Monad.Except


degreeND:: Graph -> Node -> Int
degreeND (G ns es) n = Set.size (Set.filter (\(x,y) -> x == n || y == n) es) 

adyacentesND :: Graph -> Node -> Set.Set Edge
adyacentesND (G ns es) n = Set.filter (\(x,y) -> x == n || y == n) es

eulerND' :: Node -> Graph -> Path -> Set.Set Edge -> Int -> Path
eulerND' n (G ns es) visited ady m = case Set.null ady of
                                True -> visited 
                                False -> let edge = Set.elemAt 0 ady
                                             visited' = (edge:visited)
                                             nextN = if fst edge == n then snd edge else fst edge
                                             es' = Set.delete edge es 
                                             nextAdy = adyacentesND (G ns es') nextN
                                             r = eulerND' nextN (G ns es') visited' nextAdy m
                                         in if length r == m then r else eulerND' n (G ns es) visited (Set.delete edge ady) m
                                    

eulerND :: Graph -> Path
eulerND (G ns es) = let odds = Set.filter (\n -> odd (degreeND (G ns es) n)) ns
                        sodds = Set.size odds
                    in case sodds of
                      0 -> let start = Set.elemAt 0 ns
                          in reverse (eulerND' start (G ns es) [] (adyacentesND (G ns es) start) (Set.size es)) -- Circuito euleriano
                      2 -> let start = Set.elemAt 0 odds
                          in reverse (eulerND' start (G ns es) [] (adyacentesND (G ns es) start) (Set.size es))-- Recorrido euleriano
                      _ -> [] -- Grafo no euleriano



hamiltonND' :: Node -> Graph -> Path -> Set.Set Edge -> Set.Set Edge -> Path
hamiltonND' n (G ns es) visited ady adyStart = case Set.null ady of
                                True -> let filterSet = Set.filter (\(x,y) -> x == n || y == n) adyStart
                                        in if Set.null filterSet then [] else (Set.elemAt 0 filterSet):visited
                                False -> let edge =  Set.elemAt 0 ady
                                             visited' = (edge:visited)
                                             nextN = if fst edge == n then snd edge else fst edge
                                             es' = Set.difference es ady
                                             nextAdy = adyacentesND (G ns es') nextN
                                             r = hamiltonND' nextN (G ns es') visited' nextAdy adyStart
                                         in if length r == Set.size ns then r else hamiltonND' n (G ns (Set.delete edge es)) visited (Set.delete edge ady) adyStart 


hamiltonND :: Graph -> Path
hamiltonND (G ns es) = let start = Set.elemAt 0 ns
                           ady = adyacentesND (G ns es) start
                       in reverse (hamiltonND' start (G ns es) [] ady ady)





