module Santa.Common where

type alias BigNumber = Int
type alias Named x = { x | name : String }
type alias Descriptive x = { x | description : String }