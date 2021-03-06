module Interpret(interpret) where

import Control.Monad.Free
import UI.NCurses
import Utils
import Interaction

interpret :: Program r -> Curses r
interpret prog = do 
    setEcho False
    setCursorMode CursorInvisible
    cyan <- newColorID ColorCyan ColorBlack 1
    white <- newColorID ColorWhite ColorBlack 2
    magenta <- newColorID ColorWhite ColorMagenta 3
    let colorFor Cyan = cyan
        colorFor White = white
        colorFor Magenta = magenta
    w <- defaultWindow
    r <- interpret' colorFor w prog
    closeWindow w
    return r
  where 
  interpret' :: (ColorType -> ColorID) -> Window -> Program r -> Curses r
  interpret' _ _ (Pure r) = return r
  interpret' cf w (Free (Signal sig next)) = case sig of 
        (Success) -> flash >> interpret' cf w next
        (WrongChar) -> flash >> interpret' cf w next
  interpret' cf w (Free (Print lines next)) = do
        clearScreen w
        (rows,cols) <- screenSize
        let row = 4
        let col = 4
        updateWindow w $ do 
            drawBox Nothing Nothing
            let positions = zip [row..(rows-2)] (repeat col)
            mapM update (zip lines positions)
        render
        interpret' cf w next
    where update (Line ln, (row, col)) = do
            moveCursor row col
            mapM draw ln
          draw (c, s) = do 
            setColor (cf c)
            drawString s
            setColor defaultColorID
  interpret' cf w (Free (GetChar g)) = loop
    where loop = getEvent w Nothing >>= handleEvent  
          handleEvent (Just (EventCharacter '\ESC')) = do
            closeWindow w 
            fail "ESC => Quit" --Esc takes weirdly longer than, say, '1' to fire. o well.
          handleEvent (Just (EventCharacter c)) = interpret' cf w (g c)
          handleEvent _ = loop



clearScreen :: Window -> Curses ()
clearScreen w = 
    do (rows, cols) <- screenSize
       let blankline = (`replicate` ' ') . fromIntegral . subtract 1 $ cols
       let clrLine row = moveCursor row 0 >> drawString blankline
       updateWindow w $ mapM clrLine [0..(rows-1)] 
       render
