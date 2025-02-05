module Eval
  ( Error(..)
  , eval
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
import           UndirectedG
import           DirectedG

--Errores
data Error = ParseErr String
instance Show Error where
  show (ParseErr e) = show e 

--Operaciones básicas generales con grafos dirigidos y no dirigidos
null :: Graph -> Bool
null (G ns _) = Set.null ns                       

k :: Graph -> Int 
k (G ns es) = let start = Set.elemAt 0 ns
                  visited = dfs (G ns es) start Set.empty
              in case Set.size visited < Set.size ns of
                True -> k (G (Set.difference ns visited) es) + 1
                False -> 1

unionGraph :: Graph -> Graph -> Graph
unionGraph (G ns1 es1) (G ns2 es2) = G (Set.union ns1 ns2) (Set.union es1 es2)

intersectionGraph :: Graph -> Graph -> Graph
intersectionGraph (G ns1 es1) (G ns2 es2) = G (Set.intersection ns1 ns2) (Set.intersection es1 es2)

differenceGraph :: Graph -> Graph -> Graph
differenceGraph (G ns1 es1) (G ns2 es2) = let diff = Set.difference ns1 ns2
                                              es' = Set.filter (\(x,y) -> Set.member x diff && Set.member y diff) es1
                                          in  G diff es'


dfs :: Graph -> Node -> Set.Set Node -> Set.Set Node
dfs (G ns es) n visited = let visited' = Set.insert n visited
                              ns' = Set.difference (Set.map (\(x,y) -> if x == n then y else x) (adyacentesND (G ns es) n)) visited'
                          in Set.foldl (\acc x -> dfs (G ns es) x acc) visited' ns'

isConex :: Graph -> Bool
isConex (G ns es) = case Set.null ns of
  True -> False
  False -> let start = Set.elemAt 0 ns
               visited = dfs (G ns es) start Set.empty
           in Set.size visited == Set.size ns

--Operaciones entre propiedades --

unionProperties :: Properties -> Properties -> Properties
unionProperties p1 p2 = P {name = name p1 ++ " \\/ " ++ name p2, 
                           directed = directed p1 || directed p2, 
                           conex = conex p1 && conex p2, 
                           path = path p1 ++ path p2}

differenceProperties :: Properties -> Properties -> Properties
differenceProperties p1 p2 = P {name = name p1 ++ " - " ++ name p2, 
                                directed = directed p1, 
                                conex = conex p1, 
                                path = path p1}

intersectionProperties :: Properties -> Properties -> Properties
intersectionProperties p1 p2 = P {name = name p1 ++ " /\\ " ++ name p2, 
                                  directed = directed p1 && directed p2, 
                                  conex = conex p1 && conex p2, 
                                  path = Set.toList $ Set.intersection (Set.fromList (path p1)) (Set.fromList (path p2))}

--Evaluador de grafos
eval :: (MonadIO m, MonadError Error m) => VarEnv Value -> Term -> m Value
eval ve (V (Global v)) = case lookup v ve of
                            Just x -> return x
                            Nothing -> throwError (ParseErr "Variable no definida")
eval ve (Graph g p) = return $ VGraph g p {conex = isConex g}
eval ve (Union t1 t2) = do e1 <- eval ve t1 
                           e2 <- eval ve t2
                           case (e1,e2) of
                              (VGraph g1 p1, VGraph g2 p2) -> case (directed p1) == (directed p2) of 
                                                                True -> return $ VGraph (unionGraph g1 g2) (unionProperties p1 p2)
                                                                _    -> throwError (ParseErr "Union entre grafos dirigidos y no dirigidos")
                              _ -> throwError (ParseErr "Error de tipo")

eval ve (Intersect t1 t2) = do e1 <- eval ve t1 
                               e2 <- eval ve t2
                               case (e1,e2) of
                                  (VGraph g1 p1, VGraph g2 p2) -> case (directed p1) == (directed p2) of 
                                                                True -> return $ VGraph (intersectionGraph g1 g2) (intersectionProperties p1 p2)
                                                                _    -> throwError (ParseErr "Interseccion entre grafos dirigidos y no dirigidos")
                                  _ -> throwError (ParseErr "Error de tipo")
eval ve (K t) = do e <- eval ve t
                   case e of
                     VGraph g p -> return $ if null g then VInt 0 else VInt (k g)
                     _ -> throwError (ParseErr "Error de tipo")

eval ve (Euler t) = do e <- eval ve t
                       case e of
                            VGraph g p -> let c = isConex g
                                          in return $ if not (null g) && c then VGraph g p {path = if directed p then eulerD g else eulerND g, conex = c} else VGraph g p {conex = c}
                            _ -> throwError (ParseErr "Error de tipo")

eval ve (Hamilton t) = do e <- eval ve t
                          case e of
                            VGraph g p -> let c = isConex g
                                          in return $ if not (null g) && c then VGraph g p {path = if directed p then hamiltonD g else hamiltonND g,conex = c} else VGraph g p {conex = c}
                            _ -> throwError (ParseErr "Error de tipo")

eval ve (Diff t1 t2) = do e1 <- eval ve t1
                          e2 <- eval ve t2
                          case (e1,e2) of
                            (VGraph g1 p1, VGraph g2 p2) -> case (directed p1) == (directed p2) of 
                                                                True -> return $ VGraph (differenceGraph g1 g2) (differenceProperties p1 p2)
                                                                _    -> throwError (ParseErr "Diferencia entre grafos dirigidos y no dirigidos")
                            _ -> throwError (ParseErr "Error de tipo")

eval ve (Complement t) = do e <- eval ve t
                            case e of
                              VGraph g p -> return $ VGraph (complementGraphUD g) p {name = "Complemento de " ++ name p}
                              _ -> throwError (ParseErr "Error de tipo")
                    
