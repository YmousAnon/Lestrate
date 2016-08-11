module Game
(
    Game,
    gameInit,
) where

    import Control.Monad.Trans.State

    import Data.IORef

    import Game.Board
    import Game.HintBoard
    import Game.HintBoard.Hint
    import Game.HintBoard.Vertical
    import Game.HintBoard.Horizontal

    import Interface.Input
    import Interface.Input.Settings
    import Interface.Render

    import System.Environment (getArgs)
    import System.Random

    import Interface.Coordinate

    data Game = Game
                { board    :: Board
                , solution :: Board
                , gen      :: StdGen
                , vhb      :: HintBoard
                , hhb      :: HintBoard
                , area     :: Area
                }

    instance Renderable Game where
        render w g = render w (board g)
                  >> render w (vhb   g)
                  >> render w (hhb   g)
        getArea    = area
        --(getArea (board g)
        --           \/ getArea (vhb   g)
        --           \/ getArea (hhb   g))
        --           >+<

    instance Clickable Game where
        lclick pt g = do b'   <- lclick pt $ board g
                         vhb' <- lclick pt $ vhb   g
                         hhb' <- lclick pt $ hhb   g
                         return Game
                             { board    = b'
                             , solution = solution g
                             , gen      = gen      g
                             , vhb      = vhb'
                             , hhb      = hhb'
                             , area     = area     g
                             }
        rclick pt g = do b'   <- rclick pt $ board g
                         vhb' <- rclick pt $ vhb   g
                         hhb' <- rclick pt $ hhb   g
                         return Game
                             { board    = b'
                             , solution = solution g
                             , gen      = gen      g
                             , vhb      = vhb'
                             , hhb      = hhb'
                             , area     = area     g
                             }



    gameInit :: Int -> IO Game
    gameInit seed = do
        let g = mkStdGen seed

        nC  <- read <$> getSetting "columns"
        nR  <- read <$> getSetting "rows"

        is  <- read <$> getSetting "initialSolved"

        wbw <- read <$> getSetting "windowBorderWidth"

        b  <- newBoard nR nC (wbw,wbw)

        let (s, (_, g'))    = runState (genSolution nR nC) ([1..nC],g)
        do s' <- s
           let (b',(us,g'')) = runState (initialSol is b s') (concat [[(r,c)
                                                             | r <- [0..nR-1]]
                                                             | c <- [0..nC-1]]
                                                             ,g')
           let y = getYMax $ getArea b'
               x = getXMax $ getArea b'


           -- !==! --
           let (ioVHint1,g''' ) = runState (genVHint (0,0) s') g''
               (ioVHint2,g'''') = runState (genVHint (0,0) s') g'''
           vhint1 <- ioVHint1
           vhint2 <- ioVHint2

           let (ioHHint1,g''' ) = runState (genHHint (1,1) s') g''
           hhint1 <- ioHHint1

           let emptyVBoard = newEmptyHintBoard (0,y) (getXMax $ getArea b') Vertical
           vhb'  <- fillHintBoard =<< addHintList [vhint1,vhint2] emptyVBoard --addHint vhint2 =<< addHint vhint1 emptyHBoard
           -- !==! --

           --print (getYMax $ getArea b')
           let emptyHBoard = newEmptyHintBoard (x,0) (getYMax $ getArea vhb') Horizontal
           hhb' <- fillHintBoard =<< addHintList [hhint1,vhint1,vhint2] emptyHBoard

           -- !==! --



           --(addHint (newEmptyHintBoard (0,y) (getXMax $ getArea b')))


           --vhb <- fillHintBoard =<< (addHint (newEmptyHintBoard (0,y) (getXMax $ getArea b')) =<< evalState (genHint s') (us,g''))


           --vhb <- fillHintBoard $ newEmptyHintBoard (0,y) (getXMax $ getArea b') Vertical
           --vhb <- fillHintBoard =<< (addHint (newEmptyHintBoard (0,y) (getXMax $ getArea b')) =<< evalState (genHint s') (us,g''))
           --vhb <- fillHintBoard =<< (addVHint (newEmptyHintBoard (0,y) (getXMax $ getArea b')) =<< evalState (genHint s') (us,g''))
           --hhb <- fillHHintBoard $ newEmptyHHintBoard (x,0) (getYMax $ getArea b')
           --print $ evalState (genHint s') (us,g'')
           --print =<<
           --print us
           --print b'
           --print b
           print s'
           --print a
           a <- uncurry (newArea (0,0)) . (\w -> getAreaSize (getArea b'
                                                             \/ getArea vhb'
                                                             \/ getArea hhb'
                ) >+< (w,w)) . read <$> getSetting "windowBorderWidth"
           return Game
               { board    = b'
               , solution = s'
               , gen      = g
               , vhb      = vhb'
               , hhb      = hhb'
               , area     = a
               }
