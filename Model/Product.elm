module Model.Product where

import Common (..)
import Model.Stackable as Stackable
import Model.Stackable (Stackable)

type Product = Named { wrappable : Bool, wrapped : Bool }

consumable = { wrappable = False, wrapped = False }
wrappable = { wrappable = True, wrapped = False }

-- Letter Reader (adds to wishlist)

wrapped
    = { consumable | wrapped <- True }
    |> Named "Wrapped Present"

spirit -- Gained through successful deliveries
    = consumable
    |> Named "Christmas Spirit"

santasBlessing
    = consumable
    |> Named "Santa's Blessing"

toy
    = wrappable
    |> Named "Toy"

wood = consumable |> Named "Wood"
metal = consumable |> Named "Metal"
oil = consumable |> Named "Oil"

wrappingPaper = consumable |> Named "Wrapping Paper"
battery = consumable |> Named "Battery"
plastic = consumable |> Named "Plastic"
microchip = consumable |> Named "Microchip"

basics =
    [ wood      -- Can be gathered by Lumberjacks
    , metal     -- Can be gathered by Miners
    , oil       -- Can be gathered by Oil Rigs
    ]

parts =
    [ wrappingPaper   -- Made from wood
    , battery         -- Made from metal
    , plastic         -- Made from oil
    , microchip       -- Made from metal, spirit
    ]

consumables = basics ++ parts

woodenToy = wrappable |> Named "Wooden Toy"
toyCar = wrappable |> Named "Toy Car"
movie = wrappable |> Named "Movie"
rcCar = wrappable |> Named "RC Car"
gameConsole = wrappable |> Named "Game Console"
computer = wrappable |> Named "Computer"

wrappables =
    [ woodenToy
    , toyCar
    , movie
    , rcCar
    , gameConsole
    , computer
    ]

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