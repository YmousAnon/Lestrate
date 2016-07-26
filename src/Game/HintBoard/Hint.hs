module Game.HintBoard.Hint
(
    HintType (Vertical,Horizontal),
    Hint (Hint,vals,len,area,bgrgb,selected,hidden,htype),

    toggleSelectHint,
    selectHint,
    unSelectHint,
    swapSelectedHint,
    swapTwo,

    toggleHideHint,
) where

    import Game.Board.Value

    import Interface.Coordinate
    import Interface.Input
    import Interface.Input.Settings
    import Interface.Render
    import Interface.Render.Primitive

    import System.Random


    data HintType = Vertical | Horizontal
        deriving (Enum,Eq)

    instance Random HintType where
        random g        = case randomR (0,1) g of
                              (r, g') -> (toEnum r, g')
        randomR (a,b) g = case randomR (fromEnum a, fromEnum b) g of
                              (r, g') -> (toEnum r, g')


    data Hint = Hint
                { vals     :: [Value]
                , len      :: Int
                , area     :: Area
                , bgrgb    :: [Float]
                , selected :: Bool
                , hidden   :: Bool
                , htype    :: HintType
                }

    instance Show Hint where
        show Hint { vals = vs } = concatMap (\v -> '\n':show v) vs++"\n"

    instance Renderable Hint where
        render w Hint
            { vals  = vs
            , area  = a
            , bgrgb = rgb
            } = renderColour w a rgb
             >> mapM_ (render w) vs
        getArea = area

    instance Movable Hint where
        moveTo xy  h = moveBy (xy>-<(getAreaStart $ area h)) h
        moveBy dxy h = Hint
                       { vals     = map (moveBy dxy) $ vals h
                       , len      = len                     h
                       , area     = moveBy dxy       $ area h
                       , bgrgb    = bgrgb                   h
                       , selected = selected                h
                       , hidden   = hidden                  h
                       , htype    = htype                   h
                       }

    instance Clickable Hint where
        lclick pt h = if inArea pt (area h) then toggleSelectHint        h
                                            else return                  h
        rclick pt h = if inArea pt (area h) then return $ toggleHideHint h
                                            else return                  h



    -- Only works for veritcal
    --
    --
    --
    -- = do
        --tw  <- read <$> getSetting "tileWidth"
        --hbw <- read <$> getSetting "hintBorderWidth"

        --bgt <- value 0 True (x,y) 0
        --bgc <- map (/255) . read <$> getSetting "tilergb"

        --let vs' = valList 3 (x+hbw,y+hbw) vs bgt
        --    avs = newArea (x,y) (2*hbw+tw) (2*hbw+3*tw)
        --return Hint
        --    { vals     = vs'
        --    , len      = length vs
        --    , area     = avs
        --    , bgrgb    = bgc
        --    , selected = False
        --    , hidden   = False
        --    , htype    = ht
        --    }
        --where
        --    valList :: Int -> Point -> [Value] -> Value -> [Value]
        --    valList 0 _     _  _   = []
        --    valList i (x,y) vs bgv = v' : valList (i-1)
        --                                          (x,getYMax $ getArea v')
        --                                          vs'
        --                                          bgv
        --         where
        --            v'  | null vs   = moveValueTo bgv       (x,y)
        --                | otherwise = moveValueTo (head vs) (x,y)
        --            vs' | null vs   = []
        --                | otherwise = tail vs



    toggleSelectHint :: Hint -> IO Hint
    toggleSelectHint vh = if selected vh then unSelectHint vh
                                          else selectHint   vh

    selectHint :: Hint -> IO Hint
    selectHint h = do
        bgrgb' <- map (/255) . read <$> getSetting "hintselectedrgb"
        return Hint { vals     = vals   h
                    , len      = len    h
                    , area     = area   h
                    , bgrgb    = bgrgb'
                    , selected = True
                    , hidden   = hidden h
                    , htype    = htype  h
                    }

    unSelectHint :: Hint -> IO Hint
    unSelectHint h = do
        bgrgb' <- map (/255) . read <$> getSetting "hintrgb"
        return Hint { vals     = vals   h
                    , len      = len    h
                    , area     = area   h
                    , bgrgb    = bgrgb'
                    , selected = False
                    , hidden   = hidden h
                    , htype    = htype  h
                    }



    swapSelectedHint :: [Hint] -> IO[Hint]
    swapSelectedHint vhs = let sel   = filter selected         vhs
                               nosel = filter (not . selected) vhs
                            in if length sel == 2
                                   then (++nosel) <$> swapTwo sel
                                   else return vhs

    swapTwo :: [Hint] -> IO[Hint]
    swapTwo [vh0,vh1] =
        let vh0' = unSelectHint $ moveTo (getAreaStart $ getArea vh1) vh0
            vh1' = unSelectHint $ moveTo (getAreaStart $ getArea vh0) vh1
         in sequence [vh0',vh1']



    toggleHideHint :: Hint -> Hint
    toggleHideHint h = if hidden h then unHideHint h else hideHint h

    hideHint :: Hint -> Hint
    hideHint h = let vsh = take (len h) (vals h)
                     vst = drop (len h) (vals h)
                  in Hint
            { vals     = map (changeCol [0.25,0.25,0.25]) vsh++vst
            , len      = len      h
            , area     = area     h
            , bgrgb    = bgrgb    h
            , selected = selected h
            , hidden   = True
            , htype    = htype    h
            }

    unHideHint :: Hint -> Hint
    unHideHint h = let vsh = take (len h) (vals h)
                       vst = drop (len h) (vals h)
                    in Hint
            { vals     = map (changeCol [1,1,1]) vsh++vst
            , len      = len      h
            , area     = area     h
            , bgrgb    = bgrgb    h
            , selected = selected h
            , hidden   = False
            , htype    = htype    h
            }