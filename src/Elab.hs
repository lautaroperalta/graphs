module Elab
  ( elaborate
      -- conversion a terminos localmente sin nombre
  , eval
  )
where

import           Data.List
import           Data.Maybe
import qualified Data.Set as Set 
import           Prelude                 hiding ( (>>=) )
--import           Text.PrettyPrint.HughesPJ      ( render )
import           Data.Graph.Inductive.Graph hiding (Graph)
import           Data.Graph.Inductive.PatriciaTree
--import           PrettyPrinter
import           Common

swap :: (a,b) -> (b,a)
swap (x,y) = (y,x)



setNodes :: Int -> [LNode Name] -> [LNode Name]
setNodes n ns = map (\(x,y) -> (n + x, y)) ns

setEdges :: Int -> [LEdge Name] -> [LEdge Name]
setEdges n es = map (\(x,y,z) -> (n + x, n + y, z)) es


unionGraph :: Graph -> Graph -> Graph
unionGraph (G ns1 es1) (G ns2 es2) = G (Set.union ns1 ns2) (Set.union es1 es2)

intersectionGraph :: Graph -> Graph -> Graph
intersectionGraph (G ns1 es1) (G ns2 es2) = G (Set.intersection ns1 ns2) (Set.intersection es1 es2)

toGraph :: [(Name,[Name])] -> Graph
toGraph ns = let v = Set.union (Set.fromList (map fst ns)) (Set.fromList (concat (map snd ns)))
                 e = Set.fromList $ concatMap (\(x,ys) -> map (\y -> (x,y)) ys) ns
             in G v e

-- ({a,b,c},{(a,b),(b,c)}) /\ ({b,c,d},{(b,c),(c,d)}) = ({b,c},{(b,c)})


{-
toGraph :: [(Name,[Name])] -> Gr String String
toGraph ns = let nodos = zip [1..] $ nub ((map fst ns) ++ (concat (map snd ns)))
                 rnodos = map swap nodos
                 aristas' = concatMap (\(x,ys) -> map (\y -> (x,y)) ys) ns
                 in mkGraph nodos (map (\(x,y) -> (fromJust (lookup x rnodos), fromJust (lookup y rnodos),x ++ y)) aristas')
-}

elaborate' :: String -> STerm -> Term
elaborate' n (SGraph (DirectedGraph ns)) = Graph (toGraph ns) (P n True)
elaborate' n (SGraph (UndirectedGraph ns)) = Graph (toGraph ns) (P n False)
elaborate' n (SGraph EmptyGraph) = Graph (G Set.empty Set.empty) (P n True)
elaborate' n (SUnion t1 t2) = Union (elaborate' n t1) (elaborate' n t2)
elaborate' n (SIntersect t1 t2) = Intersect (elaborate' n t1) (elaborate' n t2)
elaborate' _ (SVar v) = V (Global v)

eval :: VarEnv Value -> Term -> Value
eval ve (V (Global v)) = fromJust $ lookup v ve
eval ve (Graph g p) = VGraph g p
eval ve (Union t1 t2) = case eval ve t1 of
  VGraph g1 p1 -> case eval ve t2 of
                  VGraph g2 p2 -> VGraph (unionGraph g1 g2) p1 {name = name p1 ++ " \\/ " ++ name p2}
                  _ -> error "Error de tipo"
  _ -> error "Error de tipo"
eval ve (Intersect t1 t2) = case eval ve t1 of
  VGraph g1 p1 -> case eval ve t2 of
                  VGraph g2 p2 -> VGraph (intersectionGraph g1 g2) p1 {name = name p1 ++ " /\\ " ++ name p2}
                  _ -> error "Error de tipo"
  _ -> error "Error de tipo"

elaborate :: String -> STerm -> Term
elaborate n st = elaborate' n st


