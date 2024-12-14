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



isConex :: Graph -> Bool
isConex (G ns es) = case Set.null ns of
  True -> False
  False -> let start = Set.elemAt 0 ns
               visited = dfs (G ns es) start Set.empty
           in Set.size visited == Set.size ns

--Evaluador de grafos
eval :: (MonadIO m, MonadError Error m) => VarEnv Value -> Term -> m Value
eval ve (V (Global v)) = case lookup v ve of
                            Just x -> return x
                            Nothing -> throwError (ParseErr "Variable no definida")
eval ve (Graph g p) = return $ VGraph g p {conex = isConex g}
eval ve (Union t1 t2) = do e1 <- eval ve t1 
                           e2 <- eval ve t2
                           case (e1,e2) of
                              (VGraph g1 p1, VGraph g2 p2) -> return $ VGraph (unionGraph g1 g2) (unionProperties p1 p2)
                              _ -> throwError (ParseErr "Error de tipo")

eval ve (Intersect t1 t2) = do e1 <- eval ve t1 
                               e2 <- eval ve t2
                               case (e1,e2) of
                                  (VGraph g1 p1, VGraph g2 p2) -> return $ VGraph (intersectionGraph g1 g2) p1 {name = name p1 ++ " /\\ " ++ name p2}
                                  _ -> throwError (ParseErr "Error de tipo")
eval ve (K t) = do e <- eval ve t
                   case e of
                     VGraph g p -> return $ if null g then VInt 0 else VInt (k g)
                     _ -> throwError (ParseErr "Error de tipo")

eval ve (Euler t) = do e <- eval ve t
                       case e of
                            VGraph g p -> let c = isConex g
                                          in return $ if not (null g) && c then VGraph g p {path = euler g, conex = c} else VGraph g p {conex = c}
                            _ -> throwError (ParseErr "Error de tipo")

eval ve (Hamilton t) = do e <- eval ve t
                          case e of
                            VGraph g p -> let c = isConex g
                                          in return $ if not (null g) && c then VGraph g p {path = hamilton g,conex = c} else VGraph g p {conex = c}
                            _ -> throwError (ParseErr "Error de tipo")

eval ve (Diff t1 t2) = do e1 <- eval ve t1
                          e2 <- eval ve t2
                          case (e1,e2) of
                            (VGraph g1 p1, VGraph g2 p2) -> return $ VGraph (differenceGraph g1 g2) p1 {name = name p1 ++ " - " ++ name p2}
                            _ -> throwError (ParseErr "Error de tipo")
