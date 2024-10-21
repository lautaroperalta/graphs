module PrettyPrinter
        ( loadGraph ) where


import Data.Text.Lazy hiding (empty,all)
import Data.GraphViz hiding (empty)
import Data.Graph.Inductive.Graph 
import Data.Graph.Inductive.PatriciaTree
import Data.GraphViz.Printing hiding (empty)
import Data.GraphViz.Attributes.Complete 
import Data.GraphViz.Commands
import qualified Data.Set as Set
import Common 

-- | Parámetros para la generación del grafo
myParams :: String -> GraphvizParams n String String () String
myParams name = nonClusteredParams { 
    globalAttributes = [GraphAttrs [toLabel name] ],  -- Los nodos se colocan de izquierda a derecha
    --fmtEdge = \(_,_,l) -> [toLabel l],  -- Usar las etiquetas de las aristas
    fmtNode = \(_,l) -> [toLabel l]  -- Usar las etiquetas de los nodos
}

loadGraph :: Value -> IO ()
loadGraph (VGraph g P {name = n, directed = d}) = runGraphvizCanvas Dot (graphToDot params {isDirected = d} g) Xlib
                                                where params = myParams n