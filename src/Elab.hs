module Elab
  ( elaborate
      -- conversion a terminos localmente sin nombre
  , eval
  )
where

import           Data.List
import           Data.Maybe
import           Prelude                 hiding ( (>>=) )
--import           Text.PrettyPrint.HughesPJ      ( render )
import           Data.Graph.Inductive.Graph hiding (Graph)
import           Data.Graph.Inductive.PatriciaTree
--import           PrettyPrinter
import           Common

swap :: (a,b) -> (b,a)
swap (x,y) = (y,x)

unionGraphs :: Gr String String -> Gr String String -> Gr String String
unionGraphs empty g2 = g2
unionGraphs g1 g2 = case matchAny g1 of
                      (c, g1') -> c & (unionGraphs g1' g2)
                      _ -> error "Error de tipo"


toGraph :: [(Name,[Name])] -> Gr String String
toGraph ns = let nodos = zip [1..] $ nub ((map fst ns) ++ (concat (map snd ns)))
                 rnodos = map swap nodos
                 aristas' = concatMap (\(x,ys) -> map (\y -> (x,y)) ys) ns
                 in mkGraph nodos (map (\(x,y) -> (fromJust (lookup x rnodos), fromJust (lookup y rnodos),x ++ y)) aristas')

elaborate' :: String -> STerm -> Term
elaborate' n (SGraph (DirectedGraph ns)) = Graph (toGraph ns) (P n True)
elaborate' n (SGraph (UndirectedGraph ns)) = Graph (toGraph ns) (P n False)
elaborate' n (SGraph EmptyGraph) = Graph (mkGraph [] []) (P n True)
elaborate' n (SUnion t1 t2) = Union (elaborate' n t1) (elaborate' n t2)
elaborate' _ (SVar v) = V (Global v)

eval :: VarEnv Value -> Term -> Value
eval ve (V (Global v)) = fromJust $ lookup v ve
eval ve (Graph g p) = VGraph g p
eval ve (Union t1 t2) = case eval ve t1 of
  VGraph g1 p1 -> case eval ve t2 of
                  VGraph g2 p2 -> VGraph (mkGraph (labNodes g1 ++ [(1,"B")]) (labEdges g1)) p1
                  _ -> error "Error de tipo"
  _ -> error "Error de tipo"

elaborate :: String -> STerm -> Term
elaborate n st = elaborate' n st


