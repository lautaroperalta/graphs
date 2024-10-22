{
module Parse where
import Common
import Data.Maybe
import Data.Char

}

%monad { P } { thenP } { returnP }
%name parseStmt Def
%name parseStmts Defs
%name term Def

%tokentype { Token }
%lexer {lexer} {TEOF}

%token
    '='     { TEquals }
    ':'     { TColon }
    '.'     { TDot }
    '"'     { TQuote }
    '{'     { TKOpen }
    '}'     { TKClose }
    ';'     { TSemi }
    '('     { TOpen }
    ')'     { TClose }
    ','     { TComa }
    '->'    { TArrow }
    '--'    { TLine }
    VAR     { TVar $$ }
    INT     { TInt $$ }
    DEF     { TDef }
    NAME    { TName $$ }
    '\\/'    { TUnion }
    '/\\'   { TIntersect }
-- x = {a,b,c,d}
-- y = {(a,b),(b,c),(c,d)}
-- Graph = (x,y)
-- Graph [Node] [Edge]

%right VAR INT NAME
%left '='  
%right '\\' '.' DEF  '->' '--' '++' '{' '}' ';' ',' ':' '"' '(' ')' TEOF
%% 

Def     : DEF NAME '=' Exp      { Def $2 $4 }
        | Exp                     { Eval $1 }  

Defgraph :  NAME '->' Edges ';' DirectedGr    { SGraph (DirectedGraph (( $1, $3 )  : $5)) }
         |  NAME '--' Edges ';' UndirectedGr  { SGraph (UndirectedGraph (( $1, $3 )  : $5)) }
         |                                    { SGraph (EmptyGraph) } 

Exp     : NAME                                { SVar $1}
        | '{' Defgraph '}'                    { $2 }
        | Exp '\\/' Exp                        { SUnion $1 $3 }
        | Exp '/\\' Exp                       { SIntersect $1 $3 }
        | '(' Exp ')'                         { $2 }

DirectedGr : NAME '->' Edges ';' DirectedGr   {( $1, $3 )  : $5 }
           |                                  { [] }

UndirectedGr : NAME '--' Edges ';' UndirectedGr   {( $1, $3 )  : $5 }
             |                                    { [] }

Edges : NAME Edges  { $1 : $2 }
      |             { [] }
 


Defs    : Def Defs                  { $1 : $2 }
        |                             { [] }
     
{

data ParseResult a = Ok a | Failed String
                     deriving Show                     
type LineNumber = Int
type P a = String -> LineNumber -> ParseResult a

getLineNo :: P LineNumber
getLineNo = \s l -> Ok l

thenP :: P a -> (a -> P b) -> P b
m `thenP` k = \s l-> case m s l of
                         Ok a     -> k a s l
                         Failed e -> Failed e
                         
returnP :: a -> P a
returnP a = \s l-> Ok a

failP :: String -> P a
failP err = \s l -> Failed err

catchP :: P a -> (String -> P a) -> P a
catchP m k = \s l -> case m s l of
                        Ok a     -> Ok a
                        Failed e -> k e s l

happyError :: P a
happyError = \ s i -> Failed $ "Línea "++(show (i::LineNumber))++": Error de parseo\n"++(s)

data Token = TVar String
               | TDef
               | TDot
               | TOpen
               | TClose 
               | TGr
               | TName String
               | TKClose
               | TKOpen
               | TColon
               | TComa
               | TQuote
               | TSemi
               | TUnion
               | TIntersect
               | TArrow
               | TLine
               | TEquals
               | TEOF
               | TInt Int
               deriving Show

----------------------------------
lexer cont s = case s of
                    [] -> cont TEOF []
                    ('\n':s)  ->  \line -> lexer cont s (line + 1)
                    (c:cs)
                          | isSpace c -> lexer cont cs
                          | isAlpha c -> lexVar (c:cs)
                          | isDigit c -> lexInt (c:cs)
                    ('/':('/':cs)) -> lexer cont $ dropWhile ((/=) '\n') cs
                    ('{':('/':cs)) -> consumirBK 0 0 cont cs	
                    ('/':('}':cs)) -> \ line -> Failed $ "Línea "++(show line)++": Comentario no abierto"
                    ('.':cs) -> cont TDot cs
                    (',':cs) -> cont TComa cs  
                    ('(':cs) -> cont TOpen cs
                    (')':cs) -> cont TClose cs
                    ('"':cs) -> cont TQuote cs
                    (':':cs) -> cont TColon cs
                    ('=':cs) -> cont TEquals cs
                    ('-':('>':cs)) -> cont TArrow cs
                    ('-':('-':cs)) -> cont TLine cs
                    ('\\':('/':cs)) -> cont TUnion cs
                    ('/':('\\':cs)) -> cont TIntersect cs
                    (';':cs) -> cont TSemi cs
                    ('{':cs) -> cont TKOpen cs
                    ('}':cs) -> cont TKClose cs
                    unknown -> \line -> Failed $ 
                     "Línea "++(show line)++": No se puede reconocer "++(show $ take 10 unknown)++ "..."
                    where lexVar cs = case span isAlpha cs of
                              ("def",rest)  -> cont TDef rest
                              (var,'=':rest) -> cont (TVar var) rest
                              (name, rest) -> cont (TName name) rest
                          consumirBK anidado cl cont s = case s of
                              ('/':('/':cs)) -> consumirBK anidado cl cont $ dropWhile ((/=) '\n') cs
                              ('{':('/':cs)) -> consumirBK (anidado+1) cl cont cs	
                              ('/':('}':cs)) -> case anidado of
                                                  0 -> \line -> lexer cont cs (line+cl)
                                                  _ -> consumirBK (anidado-1) cl cont cs
                              ('\n':cs) -> consumirBK anidado (cl+1) cont cs
                              (_:cs) -> consumirBK anidado cl cont cs
                          lexInt cs = case span isDigit cs of
                              (int,rest) -> cont (TInt (read int)) rest     
                                           
stmts_parse s = parseStmts s 1
stmt_parse s = parseStmt s 1
term_parse s = term s 1
}
