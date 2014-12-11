module Santa.Model.Purchasable where

import List (..)

import Santa.Common (..)
import Santa.Model.Stackable as Stackable
import Santa.Model.Stackable (Stackable, stack)
import Santa.Model.Product as Product
import Santa.Model.Product (Product)

type alias Purchasable x = { x | cost : List (Stackable Product) }

cost' : Purchasable a -> BigNumber -> List (Stackable Product) 
cost' purchasableItem x = purchasableItem.cost

cost : Purchasable a -> BigNumber -> BigNumber -> List (Stackable Product)
cost purchasableItem existing amount =
    let range = [existing..(existing + amount - 1)]
    in
        foldr Stackable.combine [] <| map (cost' purchasableItem) range

canAfford : List (Stackable Product) -> List (Stackable Product) -> Bool
canAfford cost products =
    all (\(x, n) -> (Stackable.count x products) >= n) cost

purchase : (Purchasable a -> BigNumber -> BigNumber -> List (Stackable Product)) -> Purchasable a -> BigNumber -> List (Stackable a) -> List (Stackable Product) -> (List (Stackable a), List (Stackable Product))
purchase cost purchasableItem amount items products =
    let item = { purchasableItem - cost } 
        totalCost = cost purchasableItem (Stackable.count item items) amount
    in
        if | canAfford purchasableItem.cost products ->
                let items' = Stackable.update item amount items
                    products' = Stackable.combine products <| map (\(x, n) -> (x, -n)) totalCost
                in
                    (items', products')
           | otherwise -> (items, products)