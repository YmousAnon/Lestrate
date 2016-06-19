module Interface.Texture
(
    Textured,
    --getTexture,
    draw,

    drawTexture,
    loadTextureFromFile,
) where
    import Graphics.GLUtil
    import Graphics.Rendering.OpenGL
    import Graphics.UI.GLUT          as GLUT


    class Textured a where
        --getTexture :: a -> IO [((GLfloat,GLfloat),
        --                        (GLfloat,GLfloat),
        --                        TextureObject)]
        draw :: a -> IO()


    drawTexture :: (GLfloat,GLfloat) -> (GLfloat,GLfloat) -> TextureObject ->
                   IO()
    drawTexture (x,x') (y,y') tex = do
        textureBinding Texture2D $= Just tex
        renderPrimitive Quads $ do
            col
            txc 1 1 >> ver y' x
            txc 1 0 >> ver y' x'
            txc 0 0 >> ver y  x'
            txc 0 1 >> ver y  x
            where col     = color    (Color3 1.0 1.0 1.0 :: Color3    GLfloat)
                  ver x y = vertex   (Vertex2 x y        :: Vertex2   GLfloat)
                  txc u v = texCoord (TexCoord2 u v      :: TexCoord2 GLfloat)


    loadTextureFromFile :: FilePath -> IO TextureObject
    loadTextureFromFile f = do
        gt <- readTexture f
        textureFilter Texture2D $= ((Linear', Nothing), Linear')
        --textureFilter Texture2D $= ((Linear', Nothing), Linear')
        --texture2DWrap $= (Mirrored, ClampToEdge)
        get elapsedTime >>= print
        return $ either error id gt
