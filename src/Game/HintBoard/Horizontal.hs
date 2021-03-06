module Game.HintBoard.Horizontal
(
    newHHint,
    genHHint,

    nextHHintPos,
) where

    import Control.Monad.Trans.State

    import Data.List

    import Game.Board
    import Game.Board.Row
    import Game.Board.Square
    import Game.Board.Value
    import Game.HintBoard.Hint

    import UI.Coordinate
    import UI.Input.Settings
    import UI.Render

    import System.Random


    newHHint :: HintType -> [Value] -> Point -> IO Hint
    newHHint ht vs (x,y) = do
        tw  <- read <$> getSetting "tileWidth"
        hbw <- read <$> getSetting "hintBorderWidth"

        bgv <- value 0 True (x,y) 0

        let vs' = valList 3 (x+hbw,y+hbw) vs bgv
            a   = newArea (x,y) (2*hbw+3*tw) (2*hbw+tw)
            as  = map getArea vs'

        newHint vs' a as Horizontal ht
        where valList :: Int -> Point -> [Value] -> Value -> [Value]
              valList 0 _     _  _   = []
              valList i (x,y) vs bgv = v' : valList (i-1)
                                                    (getXMax $ getArea v',y)
                                                    vs'
                                                    bgv
                   where v'  | null vs   = moveValueTo bgv       (x,y)
                             | otherwise = moveValueTo (head vs) (x,y)
                         vs' | null vs   = []
                             | otherwise = tail vs

    genHHint :: Board -> (Int,Int) -> Bool -> State StdGen (IO (Hint,
                                                               [(Int,Int)]))
    genHHint s (ri,ci) allowInverseSpear = do
        ioHT <- genHintType Horizontal allowInverseSpear

        ri'  <- getRowI
        ri'' <- getRowI

        ci'  <- getColI [ci]     (length $ squares $ head $ rows s)
        ci'' <- getColI [ci,ci'] (length $ squares $ head $ rows s)

        let rcis  = [(ri,ci),(ri',ci'),(ri'',ci'')]

        rev    <- state random
        invSel <- state random

        return $ ioHT >>= \ht ->
            case ht of
                HNeighbour    -> do h <- genHNeighbourHint    rcis            s
                                    return (h,take 2 rcis)
                HSpear        -> do h <- genHSpearHint        rcis rev        s
                                    return (h,rcis)
                HInverseSpear -> do h <- genHInverseSpearHint rcis rev invSel s
                                    let rcis' = sortBy sndGT rcis
                                    return (h,[head rcis',last rcis'])
        where
            getRowI :: State StdGen Int
            getRowI = state $ randomR (0,length (rows s)-1)

            getColI :: [Int] -> Int -> State StdGen Int
            getColI cis lcs
                | maximum cis == lcs-1 = return (minimum cis-1)
                | minimum cis == 0     = return (maximum cis+1)
                | otherwise            = ([minimum cis-1,maximum cis+1] !!) <$>
                                         state (randomR (0,1))

    genHNeighbourHint :: [(Int,Int)] -> Board -> IO Hint
    genHNeighbourHint rcis s =
        newHHint HNeighbour (map (uncurry getV) rcis') (0,0)
        where
            rcis' :: [(Int,Int)]
            rcis' = let [rci,rci',_] = rcis in [rci,rci',rci]

            getV :: Int -> Int -> Value
            getV ri ci = val $ getRowSquare (rows s !! ri) ci

    genHSpearHint :: [(Int,Int)] -> Bool -> Board -> IO Hint
    genHSpearHint rcis rev s = newHHint HSpear (map (uncurry getV) rcis') (0,0)
        where
            rcis' :: [(Int,Int)]
            rcis' = (if rev then reverse else id) $ sortBy sndGT rcis

            getV :: Int -> Int -> Value
            getV ri ci = val $ getRowSquare (rows s !! ri) ci

    genHInverseSpearHint :: [(Int,Int)] -> Bool -> Int -> Board -> IO Hint
    genHInverseSpearHint rcis rev invSel s = do
        nC <- read <$> getSetting "columns"
        let rcis'   = (if rev then reverse else id) $ sortBy sndGT rcis
            ci'     = delete (snd(rcis'!!1)) [0..nC-1] !! mod invSel (nC-1)
            rcis''  = [head rcis',(fst (rcis'!!1),ci'),rcis'!!2]

        newHHint HInverseSpear (map (uncurry getV) rcis'') (0,0)
        where
            getV :: Int -> Int -> Value
            getV ri ci = val $ getRowSquare (rows s !! ri) ci

    sndGT :: (a,Int) -> (a,Int) -> Ordering
    sndGT (_,c) (_,c') = compare c c'



    nextHHintPos :: Hint -> Point -> Coord -> IO Point
    nextHHintPos h (x,y) w = xy'' . read <$> getSetting "hintSpacing"
        where
            (x',y')  = (getXMin $ getArea h,getYMax $ getArea h)
            xy'' hs' = if w < y' + getHeight (getArea h)
                           then (hs' + getXMax (getArea h), y)
                           else (x',hs' + y')
