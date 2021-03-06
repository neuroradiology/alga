import Data.Foldable
import Data.List.Extra (nubOrd)
import Test.QuickCheck

import Algebra.Graph
import Algebra.Graph.Basic
import Algebra.Graph.Util

type G = Basic Int
type R = Reflexive Int
type U = Undirected Int
type P = PartialOrder Int

test :: Testable a => String -> a -> IO ()
test str p = putStr (str ++ ": ") >> quickCheck p

main :: IO ()
main = do
    putStrLn "============ Directed graphs ============"
    test "Overlay identity" $ \(x :: G) ->
        x + empty == x

    test "Overlay commutativity" $ \(x :: G) y ->
        x + y == y + x

    test "Overlay associativity" $ \(x :: G) y z ->
        x + (y + z) == (x + y) + z

    test "Overlay idempotence" $ \(x :: G) ->
        x + x == x

    test "Connect identity" $ \(x :: G) ->
        x * empty == x && empty * x == x

    test "Overlay associativity" $ \(x :: G) y z ->
        x * (y * z) == (x * y) * z

    test "Distributivity" $ \(x :: G) y z ->
        x * (y + z) == x * y + x * z && (x + y) * z == x * z + y * z

    test "Decomposition" $ \(x :: G) y z ->
        x * y * z == x * y + x * z + y * z

    test "Absorption" $ \(x :: G) y ->
        x + x * y == x * y && y + x * y == x * y

    test "Connect saturation" $ \(x :: G) ->
        x * x == x * x * x

    test "Lower bound" $ \(x :: G) ->
        empty `isSubgraphOf` x

    test "Upper bound" $ \(x :: G) ->
        x `isSubgraphOf` (vertices (toList x) * vertices (toList x))

    test "Overlay order" $ \(x :: G) y ->
        x `isSubgraphOf` (x + y)

    test "Connect order" $ \(x :: G) y ->
        x `isSubgraphOf` (x * y) && y `isSubgraphOf` (x * y)

    test "Overlay-connect order" $ \(x :: G) y ->
        (x + y) `isSubgraphOf` (x * y)

    test "Path-circuit order" $ \xs ->
        path xs `isSubgraphOf` (circuit xs :: G)

    let comm  = fmap $ \(a, b) -> (b, a)
        assoc = fmap $ \(a, (b, c)) -> ((a, b), c)
    test "Box commutativity" $ mapSize (min 10) $ \(x :: G) (y :: G) ->
        x `box` y == comm (y `box` x)

    test "Box associativity" $ mapSize (min 10) $ \(x :: G) (y :: G) (z :: G) ->
        (x `box` y) `box` z == assoc (x `box` (y `box` z))

    test "Induce full graph" $ \(x :: G) ->
        induce (const True) x == x

    test "Induce empty graph" $ \(x :: G) ->
        induce (const False) x == empty

    let i x (s :: [Int]) = induce (`elem` s) x
    test "Induce subgraph" $ \s (x :: G) ->
        (x `i` s) `isSubgraphOf` x

    test "Induce commutativity" $ \(x :: G) s t ->
        x `i` s `i` t == x `i` t `i` s

    test "Induce idempotence" $ \(x :: G) s ->
        x `i` s `i` s == x `i` s

    test "Induce homomorphism" $ \(x :: G) y s ->
        x `i` s + y `i` s == (x + y) `i` s && x `i` s * y `i` s == (x * y) `i` s

    test "Remove single vertex" $ \x ->
        removeVertex x (vertex x) == (empty :: G)

    let d x = (foldBasic x) :: Dfs Int
    test "DFS idempotence" $ \x ->
        d x == d (forest . dfsForest $ d x)
    test "DFS subgraph" $ \x ->
        forest (dfsForest $ d x) `isSubgraphOf` x
    test "DFS homomorphism" $ \x y ->
        d x + d y == d (x + y) && d x * d y == d (x * y)
    test "DFS reflexivity" $ \x ->
        (vertex x :: Dfs Int) == vertex x * vertex x

    let ts x = (foldBasic x) :: TopSort Int
    test "TopSort is a topological sort" $ \x ->
        fmap (isTopSort $ foldBasic x) (topSort $ ts x) /= Just False

    test "TopSort of a cyclic graph" $ \x ys -> not (null ys) ==>
        topSort (ts $ x + circuit (nubOrd ys)) == Nothing

    test "TopSort idempotence" $ \x ->
        (topSort . ts . path =<< topSort (ts x)) == (topSort $ ts x)

    test "TopSort homomorphism" $ \x y ->
        ts x + ts y == ts (x + y) && ts x * ts y == ts (x * y)

    let t x = transpose (foldBasic x) :: G
    test "Transpose self-inverse" $ \x ->
        t (t x) == x

    test "Transpose antihomomorphism" $ \x y ->
        t x + t y == t (x + y) && t x * t y == t (y * x)

    putStrLn "============ Reflexive graphs ============"
    test "Vertex self-loop" $ \x ->
        (vertex x :: R) == vertex x * vertex x

    putStrLn "============ Undirected graphs ============"
    test "Connect commutativity" $ \(x :: U) y ->
        x * y == y * x

    putStrLn "============ Partial Orders ============"
    test "Closure" $ mapSize (min 20) $ \(x :: P) y z -> y /= empty ==>
        x * y * z == x * y + y * z

    test "Path equals clique" $ mapSize (min 20) $ \xs ->
        path xs == (clique xs :: P)
