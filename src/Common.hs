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
             | SK STerm
             | SEuler STerm
             | SHamilton STerm 
             | SDiff STerm STerm
    deriving (Show)

  data Term = V Var
            | Graph Graph Properties
            | Union Term Term 
            | Intersect Term Term
            | K Term
            | Euler Term
            | Hamilton Term
            | Diff Term Term
    deriving (Show)

  data Value = VGraph Graph Properties
            |  VInt Int
            |  VEdges [Edge]
    deriving (Show)

  data Properties = P {
                      name :: String,
                      directed :: Bool,
                      conex :: Bool,
                      weighted :: Bool,
                      path :: Path
                  }
    deriving (Show)

  data SGraph = DirectedGraph [(Name,[Name])]
              | UndirectedGraph [(Name,[Name])]
              | EmptyGraph
    deriving (Show)


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
  type Path = [Edge]
  type Node = String
  type Name = String


