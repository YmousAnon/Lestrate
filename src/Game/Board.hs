module Game.Board
(
    Board,
    rows,

    newBoard,
    genSolution,

    getBoardSquare,
    initialSol,
) where

    import Control.Monad
    import Control.Monad.Trans.State

    import UI.Coordinate
    import UI.Input
    import UI.Input.Settings
    import UI.Render

    import Game.Board.Row
    import Game.Board.Square
    import Game.Board.Value
    import Game.SolutionState

    import Data.List

    import System.Random


    data Board = Board { rows :: [Row] }

    instance Renderable Board where
        render  window = mapM_ (render window) . rows
        getArea        = foldl (\/) Empty . map getArea . rows

    instance Clickable Board where
        lclick ui pt b = fmap Board (mapM (lclick ui pt) (rows b))
        rclick ui pt b = fmap Board (mapM (rclick ui pt) (rows b))

    instance Solvable Board where
        (Board []    )|-|(Board []      ) = Correct
        (Board (r:rs))|-|(Board (r':rs')) = (r|-|r')-|-(Board rs|-|Board rs')



    newBoard :: Int -> Int -> Point -> IO Board
    newBoard nR nC (x,y) = fmap Board $ sequence $ rowIter 1 $ return y
        where
            rowIter :: Int -> IO Coord -> [IO Row]
            rowIter ri y
                | ri == nR+1 = []
                | otherwise  = let r    = do y'  <- y
                                             newRow ri nC (x,y')
                                   y''  = do bw' <- bw
                                             (+bw') . getYMax . getArea <$> r
                                in r : rowIter (ri+1) y''


            bw :: IO Coord
            bw = read <$> getSetting "rowSpacing"

    genSolution :: Int -> Int -> State ([Int],StdGen) (IO Board)
    genSolution nR nC = fmap Board . sequence <$> mapM (genSolvedRow nC)
                                                       [1..nR]



    getBoardSquare :: Board -> Int -> Int -> Square
    getBoardSquare (Board (r':rs)) 0 c = getRowSquare   r'               c
    getBoardSquare (Board (r':rs)) r c = getBoardSquare (Board rs) (r-1) c

    setBoardSquare :: Board -> Int -> Int -> Square -> Board
    setBoardSquare (Board (r':rs)) 0 c s = Board $
        setRowSquare r' c s : rs
    setBoardSquare (Board (r':rs)) r c s = Board $
        r'                  : rows (setBoardSquare (Board rs) (r-1) c s)

    swapSquare :: Board -> Board -> Int -> Int -> Board
    swapSquare bFrom bTo r c = setBoardSquare bFrom r c
                             $ getBoardSquare bTo   r c

    getPos :: State ([(Int,Int)],StdGen) (Int,Int)
    getPos = do (is,g) <- get
                let (n,g') = randomR (0,length is-1) g
                    i      = is !! n
                    is'    = delete i is
                put (is',g')
                return i

    initialSol :: Int -> Board -> Board -> State ([(Int,Int)], StdGen) Board
    initialSol n b s = foldr (\i' b' -> uncurry (swapSquare b' s) i') b
                   <$> replicateM n getPos
