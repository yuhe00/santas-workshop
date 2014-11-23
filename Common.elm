module Common where

type BigNumber = Int

type Named a = { a | name : String }

name : Named a -> String
name named = named.name