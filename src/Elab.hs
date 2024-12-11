module Elab
  ( elaborate
      -- conversion a terminos localmente sin nombre
  , eval
  )
where

import           Data.List hiding (null)
import           Data.Maybe
import qualified Data.Set as Set 
import           Prelude                 hiding ( (>>=), null )
--import           Text.PrettyPrint.HughesPJ      ( render )
--import           Data.Graph.Inductive.Graph hiding (Graph)
--import           Data.Graph.Inductive.PatriciaTree
--import           PrettyPrinter
import           Common
import           Debug.Trace (trace)

swap :: (a,b) -> (b,a)
swap (x,y) = (y,x)

unionGraph :: Graph -> Graph -> Graph
unionGraph (G ns1 es1) (G ns2 es2) = G (Set.union ns1 ns2) (Set.union es1 es2)

intersectionGraph :: Graph -> Graph -> Graph
intersectionGraph (G ns1 es1) (G ns2 es2) = G (Set.intersection ns1 ns2) (Set.intersection es1 es2)

differenceGraph :: Graph -> Graph -> Graph
differenceGraph (G ns1 es1) (G ns2 es2) = let diff = Set.difference ns1 ns2
                                              es' = Set.filter (\(x,y) -> Set.member x diff && Set.member y diff) es1
                                          in  G diff es'



toGraph :: [(Name,[Name])] -> Graph
toGraph ns = let v = Set.union (Set.fromList (map fst ns)) (Set.fromList (concat (map snd ns)))
                 e = Set.fromList $ concatMap (\(x,ys) -> map (\y -> (x,y)) ys) ns
             in G v e



defaultProperties :: String -> Bool -> Properties
defaultProperties n b = P {name = n, directed = b, conex = False, weighted = False, path = []}

elaborate :: String -> STerm -> Term
elaborate n (SGraph (DirectedGraph ns)) = Graph (toGraph ns) (defaultProperties n True)
elaborate n (SGraph (UndirectedGraph ns)) = Graph (toGraph ns) (defaultProperties n False)
elaborate n (SGraph EmptyGraph) = Graph (G Set.empty Set.empty) (defaultProperties n True)
elaborate n (SUnion t1 t2) = Union (elaborate n t1) (elaborate n t2)
elaborate n (SIntersect t1 t2) = Intersect (elaborate n t1) (elaborate n t2)
elaborate n (SK t) = K (elaborate n t)
elaborate n (SEuler t) = Euler (elaborate n t)
elaborate n (SHamilton t) = Hamilton (elaborate n t)
elaborate _ (SVar v) = V (Global v)
elaborate n (SDiff t1 t2) = Diff (elaborate n t1) (elaborate n t2)

dfs :: Graph -> Node -> Set.Set Node -> Set.Set Node
dfs (G ns es) n visited = let visited' = Set.insert n visited
                              ns' = Set.difference (Set.map (\(x,y) -> if x == n then y else x) (adyacentes (G ns es) n)) visited'
                          in Set.foldl (\acc x -> dfs (G ns es) x acc) visited' ns'


adyacentes :: Graph -> Node -> Set.Set Edge
adyacentes (G ns es) n = Set.filter (\(x,y) -> x == n || y == n) es

isConex :: Graph -> Bool
isConex (G ns es) = case Set.null ns of
  True -> False
  False -> let start = Set.elemAt 0 ns
               visited = dfs (G ns es) start Set.empty
           in Set.size visited == Set.size ns
  
degreeND:: Graph -> Node -> Int
degreeND (G ns es) n = Set.size (Set.filter (\(x,y) -> x == n || y == n) es)  

{-
A --- B
 | \ |
C --- D
-}

--start = if Set.null odds then Set.elemAt 0 ns else Set.elemAt 0 odds

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

{-
A --- D --- E
 | \ |     |     
B --- C --- F
-}



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



null :: Graph -> Bool
null (G ns _) = Set.null ns                       

k :: Graph -> Int 
k (G ns es) = let start = Set.elemAt 0 ns
                  visited = dfs (G ns es) start Set.empty
              in case Set.size visited < Set.size ns of
                True -> k (G (Set.difference ns visited) es) + 1
                False -> 1

unionProperties :: Properties -> Properties -> Properties
unionProperties p1 p2 = P {name = name p1 ++ " \\/ " ++ name p2, 
                           directed = directed p1 || directed p2, 
                           conex = conex p1 && conex p2, 
                           weighted = weighted p1 || weighted p2, 
                           path = path p1 ++ path p2}

eval :: VarEnv Value -> Term -> Value
eval ve (V (Global v)) = fromJust $ lookup v ve
eval ve (Graph g p) = VGraph g p {conex = isConex g}
eval ve (Union t1 t2) = case eval ve t1 of
  VGraph g1 p1 -> case eval ve t2 of
                  VGraph g2 p2 -> VGraph (unionGraph g1 g2) (unionProperties p1 p2)
                  _ -> error "Error de tipo"
  _ -> error "Error de tipo"
eval ve (Intersect t1 t2) = case eval ve t1 of
  VGraph g1 p1 -> case eval ve t2 of
                  VGraph g2 p2 -> VGraph (intersectionGraph g1 g2) p1 {name = name p1 ++ " /\\ " ++ name p2}
                  _ -> error "Error de tipo"
  _ -> error "Error de tipo"
eval ve (K t) = case eval ve t of
  VGraph g p -> if null g then VInt 0 else VInt (k g)
  _ -> error "Error de tipo"
eval ve (Euler t) = case eval ve t of
  VGraph g p -> let c = isConex g
                in if not (null g) && c then VGraph g p {path = euler g, conex = c} else VGraph g p {conex = c}
  _ -> error "Error de tipo"
eval ve (Hamilton t) = case eval ve t of
  VGraph g p -> let c = isConex g
                in if not (null g) && c then VGraph g p {path = hamilton g,conex = c} else VGraph g p {conex = c}
  _ -> error "Error de tipo"
eval ve (Diff t1 t2) = case eval ve t1 of
  VGraph g1 p1 -> case eval ve t2 of
                  VGraph g2 p2 -> VGraph (differenceGraph g1 g2) p1 {name = name p1 ++ " - " ++ name p2}
                  _ -> error "Error de tipo"
  _ -> error "Error de tipo"



