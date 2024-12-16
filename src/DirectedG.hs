module DirectedG where

import           Data.List hiding (null)
import           Data.Maybe
import qualified Data.Set as Set 
import           Prelude                 hiding ( (>>=), null )
import           Common
import           Debug.Trace (trace)
import           Control.Monad
import           Control.Monad.Except

complementGraphD :: Graph -> Graph
complementGraphD (G ns es) = let allEdges = [(x,y) | x <- Set.toList ns, y <- Set.toList ns, x /= y]
                                 complementEdges = Set.fromList allEdges `Set.difference` es
                              in G ns complementEdges

degreeDout :: Graph -> Node -> Int
degreeDout (G ns es) n = Set.size (Set.filter (\(x,y) -> x == n) es) 

degreeDin :: Graph -> Node -> Int
degreeDin (G ns es) n = Set.size (Set.filter (\(x,y) -> y == n) es) 

adyacentesD :: Graph -> Node -> Set.Set Edge
adyacentesD (G ns es) n = Set.filter (\(x,y) -> x == n) es

eulerD' :: Node -> Graph -> Path -> Set.Set Edge -> Int -> Path
eulerD' n (G ns es) visited ady m = case Set.null ady of
                                True -> visited 
                                False -> let edge = Set.elemAt 0 ady
                                             visited' = (edge:visited)
                                             nextN = snd edge
                                             es' = Set.delete edge es 
                                             nextAdy = adyacentesD (G ns es') nextN
                                             r = eulerD' nextN (G ns es') visited' nextAdy m
                                         in if length r == m then r else eulerD' n (G ns es) visited (Set.delete edge ady) m
                                    
--{A->B;B-> A D;C->A;D -> E;E->C;}
eulerD :: Graph -> Path
eulerD (G ns es) =
    let samedg = Set.filter (\n -> degreeDin (G ns es) n == degreeDout (G ns es) n) ns
        nsamedg = Set.size samedg
    in startEulerD (G ns es) samedg
    where startEulerD (G ns es) n | Set.size ns == Set.size n = let start = Set.elemAt 0 ns
                                                                in reverse (eulerD' start (G ns es) [] (adyacentesD (G ns es) start) (Set.size es))
                                  | Set.size ns - 2 == Set.size n = case Set.toList (Set.difference ns n) of
                                                                        [n1, n2]
                                                                            | compareStart n1 n2 (G ns es) ->
                                                                                    reverse (eulerD' n1 (G ns es) [] (adyacentesD (G ns es) n1) (Set.size es))  -- Caso 1: n1 es el inicio
                                                                            
                                                                            | compareStart n2 n1 (G ns es) ->
                                                                                    reverse (eulerD' n2 (G ns es) [] (adyacentesD (G ns es) n2) (Set.size es))  -- Caso 2: n2 es el inicio
                                                                            
                                                                            | otherwise -> []  -- Si los grados no cumplen las condiciones, no es euleriano
                                                                        _ -> []  -- No hay exactamente dos nodos desbalanceados, no es euleriano
                                  | otherwise = []
          compareStart n1 n2 g = degreeDout g n1 == ((degreeDin g n1) + 1) &&
                                            degreeDin g n2 == ((degreeDout g n2) + 1)




hamiltonD' :: Node -> Graph -> Path -> Set.Set Edge ->  Path
hamiltonD' n (G ns es) visited ady = case Set.null ady of
                                True -> visited
                                False -> let edge =  Set.elemAt 0 ady
                                             visited' = (edge:visited)
                                             nextN = snd edge
                                             es' = Set.difference es ady
                                             nextAdy = adyacentesD (G ns es') nextN
                                             r = hamiltonD' nextN (G ns es') visited' nextAdy 
                                         in if length r == Set.size ns then r else hamiltonD' n (G ns (Set.delete edge es)) visited (Set.delete edge ady) 


hamiltonD :: Graph -> Path
hamiltonD (G ns es) = let start = Set.elemAt 0 ns
                          ady = adyacentesD (G ns es) start
                      in reverse (hamiltonD' start (G ns es) [] ady)



--Operaciones entre propiedades --



