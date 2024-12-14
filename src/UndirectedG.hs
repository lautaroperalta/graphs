module UndirectedG where

import           Data.List hiding (null)
import           Data.Maybe
import qualified Data.Set as Set 
import           Prelude                 hiding ( (>>=), null )
import           Common
import           Debug.Trace (trace)
import           Control.Monad
import           Control.Monad.Except

unionGraph :: Graph -> Graph -> Graph
unionGraph (G ns1 es1) (G ns2 es2) = G (Set.union ns1 ns2) (Set.union es1 es2)

intersectionGraph :: Graph -> Graph -> Graph
intersectionGraph (G ns1 es1) (G ns2 es2) = G (Set.intersection ns1 ns2) (Set.intersection es1 es2)

differenceGraph :: Graph -> Graph -> Graph
differenceGraph (G ns1 es1) (G ns2 es2) = let diff = Set.difference ns1 ns2
                                              es' = Set.filter (\(x,y) -> Set.member x diff && Set.member y diff) es1
                                          in  G diff es'

degreeND:: Graph -> Node -> Int
degreeND (G ns es) n = Set.size (Set.filter (\(x,y) -> x == n || y == n) es) 

adyacentes :: Graph -> Node -> Set.Set Edge
adyacentes (G ns es) n = Set.filter (\(x,y) -> x == n || y == n) es

euler' :: Node -> Graph -> Path -> Set.Set Edge -> Int -> Path
euler' n (G ns es) visited ady m = case Set.null ady of
                                True -> visited 
                                False -> let edge = Set.elemAt 0 ady
                                             visited' = (edge:visited)
                                             nextN = if fst edge == n then snd edge else fst edge
                                             es' = Set.delete edge es 
                                             nextAdy = adyacentes (G ns es') nextN
                                             r = euler' nextN (G ns es') visited' nextAdy m
                                         in if length r == m then r else euler' n (G ns es) visited (Set.delete edge ady) m
                                    

euler :: Graph -> Path
euler (G ns es) = let odds = Set.filter (\n -> odd (degreeND (G ns es) n)) ns
                      sodds = Set.size odds
                  in case sodds of
                    0 -> let start = Set.elemAt 0 ns
                         in reverse (euler' start (G ns es) [] (adyacentes (G ns es) start) (Set.size es)) -- Circuito euleriano
                    2 -> let start = Set.elemAt 0 odds
                         in reverse (euler' start (G ns es) [] (adyacentes (G ns es) start) (Set.size es))-- Recorrido euleriano
                    _ -> [] -- Grafo no euleriano



hamilton' :: Node -> Graph -> Path -> Set.Set Edge -> Set.Set Edge -> Path
hamilton' n (G ns es) visited ady adyStart = case Set.null ady of
                                True -> let filterSet = Set.filter (\(x,y) -> x == n || y == n) adyStart
                                        in if Set.null filterSet then [] else (Set.elemAt 0 filterSet):visited
                                False -> let edge =  Set.elemAt 0 ady
                                             visited' = (edge:visited)
                                             nextN = if fst edge == n then snd edge else fst edge
                                             es' = Set.difference es ady
                                             nextAdy = adyacentes (G ns es') nextN
                                             r = hamilton' nextN (G ns es') visited' nextAdy adyStart
                                         in if length r == Set.size ns then r else hamilton' n (G ns (Set.delete edge es)) visited (Set.delete edge ady) adyStart 


hamilton :: Graph -> Path
hamilton (G ns es) = let start = Set.elemAt 0 ns
                         ady = adyacentes (G ns es) start
                     in reverse (hamilton' start (G ns es) [] ady ady)

dfs :: Graph -> Node -> Set.Set Node -> Set.Set Node
dfs (G ns es) n visited = let visited' = Set.insert n visited
                              ns' = Set.difference (Set.map (\(x,y) -> if x == n then y else x) (adyacentes (G ns es) n)) visited'
                          in Set.foldl (\acc x -> dfs (G ns es) x acc) visited' ns'

--Operaciones entre propiedades --

unionProperties :: Properties -> Properties -> Properties
unionProperties p1 p2 = P {name = name p1 ++ " \\/ " ++ name p2, 
                           directed = directed p1 || directed p2, 
                           conex = conex p1 && conex p2, 
                           weighted = weighted p1 || weighted p2, 
                           path = path p1 ++ path p2}

