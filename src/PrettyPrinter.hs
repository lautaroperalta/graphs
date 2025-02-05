module PrettyPrinter
        ( loadGraph ) where


--import Data.Text.Lazy hiding (empty,all,map,zip,reverse)
import Data.GraphViz hiding (empty,Path)
import Data.Graph.Inductive.Graph hiding (Graph,Edge,Node,Path)
import Data.Graph.Inductive.PatriciaTree
import Control.Monad (void)
import Data.GraphViz.Printing hiding (empty)
import Data.GraphViz.Attributes.Complete 
import Data.GraphViz.Commands
import Data.Maybe
import Data.List
import Data.Char (isAlphaNum)
import qualified Data.Set as Set
import Common 


instance Labellable Edge where
    toLabelValue = toLabelValue . show

-- | Parámetros para la generación del grafo
myParams :: Properties -> GraphvizParams Int Node Edge () String
myParams p = nonClusteredParams { 
    globalAttributes = [GraphAttrs [toLabel (name p), Overlap ScaleOverlaps, Mode IpSep], NodeAttrs [Shape Circle]] ++ if directed p then [] else [EdgeAttrs [ArrowHead (AType [(ArrMod FilledArrow RightSide, NoArrow)])]],  -- Los nodos se colocan de izquierda a derecha
    fmtNode = \(n,l) -> [toLabel l],  -- Usar las etiquetas de los nodos
    fmtEdge = \(x,y,l) -> case elemIndex l (path p) of
                            Just i -> [toLabel (i+1),Color [toWC (X11Color Red)]]
                            Nothing -> []
    }
-- Pasamos el graph a estructura de grafo intermedia para poder plotearlo
graphToGr :: Graph -> Gr Node Edge
graphToGr (G ns es) = let ns' = zip [1..] $ Set.toList ns
                          rns' = map swap ns' 
                          es' = map (\(x,y) -> (fromJust (lookup x rns'), fromJust (lookup y rns'), (x,y))) $ Set.toList es
                          in mkGraph ns' es'
                      where swap (x,y) = (y,x)
                      

loadGraph :: Value -> IO ()
loadGraph (VGraph g p) = do runGraphvizCanvas Neato graph Xlib
                            void $ runGraphvizCommand Neato graph Png ("images/" ++ (filter isAlphaNum (name p)) ++ ".png") 
                                                where params = myParams p
                                                      graph = graphToDot params (graphToGr g)
loadGraph (VInt i) = putStrLn (show i)
