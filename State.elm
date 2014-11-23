module State where

import Common (..)
import Stackable
import Stackable (Stackable)
import Product
import Product (Product)
import Producer
import Producer (Producer, Purchasable)

type State =
    { deliveredPresents : BigNumber
    , products : [ Stackable Product ]
    , producers : [ Stackable Producer ]
    }

{-
    IDEAS:
        - Reindeer (delivers wrapped presents)
        - Letter Reader (adds to wishlist)
-}

startState : State
startState =
    { deliveredPresents = 0
    , products = []
    , producers = []
    }

updateProduction : Time -> State -> State
updateProduction deltaTime state =
    { state | products <- foldr Producer.produce state.products state.producers }

updateDeliveries : Time -> State -> State
updateDeliveries deltaTime state =
    Producer.deliveries state.producers state.products |> flip deliverWrapped state

purchase : Purchasable Producer -> BigNumber -> State -> State
purchase purchasableProducer amount state =
    let producer = { purchasableProducer - cost } 
        existing = Stackable.count producer state.producers
        range = [existing..(existing + amount - 1)]
        totalCost = foldr Stackable.combine [] <| map (Producer.cost purchasableProducer) range
        canAfford = all (\(x, n) -> (Stackable.count x state.products) >= n) totalCost
    in
        if | canAfford ->
            { state
            | producers <- Stackable.update producer amount state.producers
            , products <- Stackable.combine state.products <| map (\(x, n) -> (x, -n)) totalCost
            }
           | otherwise -> state

deliverWrapped : BigNumber -> State -> State
deliverWrapped amount state =
    let remaining = Stackable.count Product.wrapped state.products
        target = state.deliveredPresents + amount
        spiritsGained = (abs ((target // 10) - (state.deliveredPresents // 10))) * 100
        deltas = [ (Product.wrapped, -amount), (Product.christmasSpirit, spiritsGained) ]
    in
        if | remaining - amount >= 0 ->
            { state
            | deliveredPresents <- target
            , products <- Stackable.combine state.products deltas
            }
           | otherwise -> state