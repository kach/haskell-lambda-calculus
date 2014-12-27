An interpreter for the lambda calulus.

The Lambda Calculus (obligatory WP:
http://en.wikipedia.org/wiki/Lambda_calculus) was first formally described by
Alonzo Church. It was a system where, to paraphrase the Beatles, "All you need
is lambda".

Though you might not be familiar with the name `lambda`, you are likely to have
used a language which exposes the concept (Scheme, JavaScript, Python, and of
course Haskell). I will not actually bother to explain it here, partly because
it's past my bedtime and partly because you can get a much better explanation
by reading _Structure and Implementation of Computer Programs_ (Abelson and
Sussman).

Anyhow: I wrote this to help Learn Me a Haskell (for great good). Though I'm
still extremely confused, I've decided that some parts of Haskell make sense.
That being said, if any Haskell-pros would like to comment on the code and
point out issues (both stylistic and technical), I'd be happy to listen. I
consider this file a sample of Illiterate Haskell.

Here goes nothing.

------------------------

A "name" is just a string used as an identifier and bound in an environment. So
we alias `Name` to `[Char]`:

> type Name = [Char]

When the parser runs, it'll generate an abstract syntax tree of type
Expression. The AST consists of only three things: lambda-makers, lambda-calls,
and environment references. So, each of those gets a constructor to make an
Expression:

> data Expression =
>     MakeLambda Name       Expression
>   | Call       Expression Expression
>   | EnvRef     Name

It's probably worth making these prettyprintable for debugging purposes. I'll
make it print in a format that Scheme will accept, just for some piping-fun. :)

> instance Show Expression where
>   show (MakeLambda argname body) =
>       "(lambda (" ++ argname ++ ") " ++ show body ++ ")"
>   show (Call function argument) =
>       "(" ++ show function ++ " " ++ show argument ++ ")"
>   show (EnvRef name) = name

Now we define an actual Lambda data type (which is different from a MakeLambda
expression!). A Lambda includes the name of its argument, the expression it'll
evaluate, and the environment in which *it was created*.

> data Lambda = Lambda { argumentname :: Name, contents :: Expression, parentEnv :: Environment }

Again, prettyprintable in Scheme format.

> instance Show Lambda where
>   show (Lambda argumentname contents parentEnv) =
>       "(lambda (" ++ argumentname ++ ") " ++ show contents ++ ")"

Environments themselves are easy to define. There's only one key in them, so
instead of working with tables, I'm going to cheat and make "frames" and
"environments" look the same.

> data Environment =
>     Root
>   | Environment Name Lambda Environment

Yay, recursion! Environment lookups are all about traversing the chain and
hoping you find the key before you hit root.

> envLookup :: Name -> Environment -> Lambda
> envLookup n (Root) = error "Yikes."
> envLookup n (Environment key value parent) = if n == key then value else (envLookup n parent)

Cool. So now we can actually write the interpreter. It takes an AST and returns
a lambda expression, so we have:

> evalExp :: Environment -> Expression -> Lambda

Each type of AST node gets its own handler:

> evalExp env (MakeLambda argname body) = Lambda argname body env
> evalExp env (EnvRef name) = envLookup name env
> evalExp env (Call function argument) =
>   let arg = evalExp env argument
>       fn  = evalExp env function
>       ne  = Environment (argumentname fn) arg (parentEnv fn)
>   in  evalExp ne (contents fn)

And finally, we wrap that all up in the Root environment frame.

> eval exp = evalExp Root exp

Let's provide a test-case.

> y = (Call (MakeLambda "P" (Call (EnvRef "P") (EnvRef "P"))) (MakeLambda "Q" (EnvRef "Q")))

> main = do  
>   putStrLn $ show $ eval y
