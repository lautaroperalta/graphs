module Common where
  -- Comandos interactivos o de archivos
  import qualified Data.Set as Set
  data Stmt = Def String STerm
            | Eval STerm
    deriving (Show)
  -- AST superficiales para el parser
  data STerm = SVar String
             | SGraph SGraph
             | SUnion STerm STerm
             | SIntersect STerm STerm
             | SK STerm
             | SEuler STerm
             | SHamilton STerm 
             | SDiff STerm STerm
    deriving (Show)

  data SGraph = DirectedGraph [(Name,[Name])]
              | UndirectedGraph [(Name,[Name])]
              | EmptyGraph
    deriving (Show)
  -- AST de términos
  data Term = V Var
            | Graph Graph Properties
            | Union Term Term 
            | Intersect Term Term
            | K Term
            | Euler Term
            | Hamilton Term
            | Diff Term Term
    deriving (Show)
  -- Los valores son el grafo o un entero para mostrar cantidad de componentes conexas
  data Value = VGraph Graph Properties
            |  VInt Int
            |  VEdges [Edge]
    deriving (Show)






  -- Entornos
  type VarEnv v = [(String, v)]
  data Var
     =  Global String
     |  Free String
    deriving (Show, Eq)
  -- Grafo y sus definiciones
  data GraphDir = GD { 
                nodes :: Set.Set Node, 
                edges :: Set.Set EdgeD
              }
                deriving (Show)
  
  data GraphUndir = GU {
                nodesU :: Set.Set Node,
                edgesU :: Set.Set EdgeUD
              }
                deriving (Show)

  type EdgeD = (Node, Node)
  type EdgeUD = Set.Set Node
  type Path = [Edge]
  type Node = String
  type Name = String
  -- Propiedades de un grafo
  data Properties = P {
                      name :: String,
                      directed :: Bool,
                      conex :: Bool,
                      weighted :: Bool,
                      path :: Path
                  }
    deriving (Show)


