module Product where

import Common (..)
import Stackable
import Stackable (Stackable)

type Product = Named { wrappable : Bool, wrapped : Bool }

consumable = { wrappable = False, wrapped = False }
wrappable = { wrappable = True, wrapped = False }

wrapped
    = { consumable | wrapped <- True }
    |> Named "Wrapped Present"

christmasSpirit
    = consumable
    |> Named "Christmas Spirit"

santasBlessing
    = consumable
    |> Named "Santa's Blessing"

toy
    = wrappable
    |> Named "Toy"

{-
movie = Wrappable "Movie"
chocolate = Wrappable "Chocolate"
consoleGame = Wrappable "Console Game"
pcGame = Wrappable "PC Game"
-}

wrap : Product -> BigNumber -> [ Stackable Product ] -> [ Stackable Product ]
wrap product amount products =
    case product.wrappable of
        True ->
            let remaining = Stackable.count product products
                updates = [(product, -amount), (wrapped, amount)]
            in
                if | remaining - amount >= 0 -> foldr (uncurry Stackable.update) products updates
                   | otherwise -> products
        False -> products