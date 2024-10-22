module Common where
  -- Comandos interactivos o de archivos
  import qualified Data.Set as Set
  data Stmt = Def String STerm
            | Eval STerm
    deriving (Show)
  
  data STerm = SVar String
             | SGraph SGraph
             | SUnion STerm STerm
             | SIntersect STerm STerm
    deriving (Show)

  data Term = V Var
            | Graph Graph Propietis
            | Union Term Term 
            | Intersect Term Term
    deriving (Show)

  data Value = VGraph Graph Propietis
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


  data Graph = G { 
                nodes :: Set.Set Node, 
                edges :: Set.Set Edge
              }
                deriving (Show)

  type Edge = (Node, Node)
  type Node = String
  type Name = String


