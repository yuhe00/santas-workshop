module Santa.Model.Product where

import List (..)

import Santa.Common (..)
import Santa.Model.Stackable as Stackable
import Santa.Model.Stackable (Stackable)

type alias Product = Named { wrappable : Bool, wrapped : Bool }

wrap : Product -> BigNumber -> List (Stackable Product) -> List (Stackable Product)
wrap product amount products =
    case product.wrappable of
        True ->
            let remaining = Stackable.count product products
                updates = [(product, -amount), (wrapped, amount)]
            in
                if | remaining - amount >= 0 -> foldr (uncurry Stackable.update) products updates
                   | otherwise -> products
        False -> products

-- Santa's Workshop

consumable = { wrappable = False, wrapped = False }
wrappable = { wrappable = True, wrapped = False }

wrapped = { consumable | wrapped <- True } |> Named "Wrapped Present"
spirit = consumable |> Named "Christmas Spirit"
-- santasBlessing = consumable |> Named "Santa's Blessing"

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
metalCar = wrappable |> Named "Toy Car"
legos = wrappable |> Named "Lego Set"
rcCar = wrappable |> Named "RC Car"
gameConsole = wrappable |> Named "Game Console"
computer = wrappable |> Named "PC"

presents =
    [ woodenToy
    , metalCar
    , legos
    , rcCar
    , gameConsole
    , computer
    ]

products : List Product
products = [ wrapped, spirit ] ++ consumables ++ presents