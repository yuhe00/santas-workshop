module Santa.Common where

import List (..)

type alias BigNumber = Int
type alias Named x = { x | name : String }
type alias Descriptive x = { x | description : String }

find : String -> List (Named a) -> Maybe (Named a)
find name xs =
    case filter (\x -> x.name == name) xs of
        found::[] -> Just found
        _ -> Nothing