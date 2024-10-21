module Common where
  import Data.Graph.Inductive.Graph
  import Data.Graph.Inductive.PatriciaTree
  -- Comandos interactivos o de archivos
  data Stmt = Def String STerm
            | Eval STerm
    deriving (Show)
  
  data STerm = SVar String
             | SGraph SGraph
             | SUnion STerm STerm
    deriving (Show)

  data Term = V Var
            | Graph (Gr String String) Propietis
            | Union Term Term 
    deriving (Show)

  data Value = VGraph (Gr String String) Propietis
    deriving (Show)

  data Propietis = P {
                      name :: String,
                      directed :: Bool
                  }
    deriving (Show)

  data SGraph = DirectedGraph [(Name,[Name])]
              | UndirectedGraph [(Name,[Name])]
              | EmptyGraph
    deriving (Show)

  --instance Functor Stmt where
  --  fmap f (DefNode s i) = DefNode s (f i)
  --  fmap f (DefGraph i)  = DefGraph (f i)

  -- Tipos de los nombres
  data Var
     =  Global String
     |  Free String
    deriving (Show, Eq)

  -- Entornos
  type VarEnv v = [(String, v)]


  --data Graph = Graph { 
  --              nodes :: [Node], 
  --              edges :: [Edge],
  --              name :: Name} 
  --              deriving (Show)


  type Edge = (Int, Int)
  type Node = (Int, Name)
  type Name = String


