module PrettyPrinter
        ( loadGraph ) where


import Data.Text.Lazy hiding (empty,all,map,zip,reverse)
import Data.GraphViz hiding (empty)
import Data.Graph.Inductive.Graph hiding (Graph)
import Data.Graph.Inductive.PatriciaTree
import Data.GraphViz.Printing hiding (empty)
import Data.GraphViz.Attributes.Complete 
import Data.GraphViz.Commands
import Data.Maybe
import qualified Data.Set as Set
import Common 

-- | Parámetros para la generación del grafo
myParams :: String -> GraphvizParams n String String () String
myParams name = nonClusteredParams { 
    globalAttributes = [GraphAttrs [toLabel name] ],  -- Los nodos se colocan de izquierda a derecha
    --fmtEdge = \(_,_,l) -> [toLabel l],  -- Usar las etiquetas de las aristas
    fmtNode = \(_,l) -> [toLabel l]  -- Usar las etiquetas de los nodos
    --fmtEdge = \(_,_,l) -> [ArrowHead (AType [(ArrMod FilledArrow RightSide, NoArrow)])]  -- Usar las etiquetas de las aristas
    }

graphToGr :: Graph -> Gr String String
graphToGr (G ns es) = let ns' = zip [1..] $ Set.toList ns
                          rns' = map swap ns' 
                          es' = map (\(x,y) -> (fromJust (lookup x rns'), fromJust (lookup y rns'), x++y)) $ Set.toList es
                          in mkGraph ns' es'
                      where swap (x,y) = (y,x)
                      

loadGraph :: Value -> IO ()
loadGraph (VGraph g P {name = n, directed = d}) = runGraphvizCanvas Neato (graphToDot params {isDirected = d} (graphToGr g)) Xlib
                                                where params = myParams n