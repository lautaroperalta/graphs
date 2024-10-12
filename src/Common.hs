module Common where

  -- Comandos interactivos o de archivos
  data Stmt = NewGraph Name [(Name,[Name])]
    deriving (Show)
  
  --instance Functor Stmt where
  --  fmap f (DefNode s i) = DefNode s (f i)
  --  fmap f (DefGraph i)  = DefGraph (f i)

  -- Tipos de los nombres
  data Var
     =  Global  String
    deriving (Show, Eq)

  -- Entornos
  type VarEnv v = [(Var, v)]


  data Graph = Graph { 
                nodes :: [Node], 
                edges :: [Edge],
                name :: Name} 
                deriving (Show)


  type Edge = (Int, Int)
  type Node = (Int, Name)
  type Name = String


