module Main where

import Utils
import Interaction
import Control.Monad.Free
import UI.NCurses
import Interpret
import GenScala

main :: IO ()
main = do
  words <- genscala
  (runCurses . interpret . dvorak) words
  return ()


dvorak :: [String] -> Program ()
dvorak (first:rest) = step [] (takeWhile (' '==) first) (dropWhile (' '==) first) 
  where step :: String -> String -> String -> Program ()
        step wrong@(_:ws) typed totype = do
          let current = Line [(Cyan, typed), (Magenta, reverse wrong), (White, drop (length wrong) totype)]
          let next = map (Line . (:[]) ) $ zip (repeat White) rest
          printlns $ current : next
          c <- dvorakChar
          if c == '\DEL' 
            then step ws typed totype
            else step (c:wrong) typed totype

        step [] typed totype@(c:cs) = do
          let current = Line [(Cyan, typed), (White, totype)]
          let next = map (Line . (:[]) ) $ zip (repeat White) rest
          printlns $ current : next
          c' <- dvorakChar
	  if c' /= '\DEL'
	    then if c' == c
              then step [] (typed ++ [c']) cs
              else step [c'] typed totype
            else step [] typed totype  

        step [] typed [] = dvorak rest

dvorak [] = return ()


dvorakChar ::  Program Char
dvorakChar = do 
        c <- getchar
	maybe dvorakChar return (qwertyToDvorak c)
