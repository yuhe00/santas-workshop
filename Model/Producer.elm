module Model.Producer where

import Common (..)
import Model.Stackable as Stackable
import Model.Stackable (Stackable, stack)
import Model.Product as Product
import Model.Product (Product)

data Function
    = Creator [ Stackable Product ]
    | Transformer [ Stackable Product ] [ Stackable Product ]
    | Deliverer BigNumber

type Purchasable x = { x | cost : [ Stackable Product ] }
type Functional x = { x | function : Function }
type Producer = Named (Functional {})

lumberjack
    = identity {}
    |> Named "Lumberjack"
    |> Purchasable [ stack 10 Product.wood, stack 1 Product.spirit ]
    |> Functional
        ( Creator [ stack 1 Product.wood ] )

miner
    = identity {}
    |> Named "Miner"
    |> Purchasable [ stack 10 Product.metal ]
    |> Functional
        ( Creator [ stack 1 Product.metal ] )

oilRig
    = identity {}
    |> Named "Oil Rig"
    |> Purchasable
        [ stack 50 Product.wood
        , stack 50 Product.metal
        ]
    |> Functional
        ( Creator [ stack 1 Product.oil ] )

santasLittleHelper : Purchasable Producer
santasLittleHelper
    = identity {}
    |> Named "Santa's Little Helper"
    |> Purchasable [ stack 1 Product.spirit ]
    |> Functional
        ( Creator [ stack 1 Product.toy ] )

toyWrapper : Purchasable Producer
toyWrapper
    = identity {}
    |> Named "Toy Wrapper"
    |> Purchasable [ stack 3 Product.spirit ]
    |> Functional
        ( Transformer
            [ stack 1 Product.toy, stack 1 Product.wrappingPaper ]
            [ stack 1 Product.wrapped ]
        )

reindeer : Purchasable Producer
reindeer
    = identity {}
    |> Named "Reindeer"
    |> Purchasable [ stack 5 Product.spirit ]
    |> Functional
        ( Deliverer 10 )

cost' : Purchasable Producer -> BigNumber -> [ Stackable Product ] 
cost' purchasableProducer x =
    --map (\(p, n) -> (p, (n * x)^(x // 2) + x^2)) baseCost
    map (\(p, n) -> (p, n + (n * x)^2)) purchasableProducer.cost

cost : Purchasable Producer -> BigNumber -> BigNumber -> [ Stackable Product ] 
cost purchasableProducer existing amount =
    let range = [existing..(existing + amount - 1)]
    in
        foldr Stackable.combine [] <| map (cost' purchasableProducer) range

produce : Stackable Producer -> [ Stackable Product ] -> [ Stackable Product ]
produce (producer, amount) products =
    case producer.function of
        Creator ps -> foldr (\(x, n) ps -> Stackable.update x (n * amount) ps) products ps
        Transformer cs ps ->
            let possible = minimum <| map (\(x, n) -> (Stackable.count x products) // n) cs
                multiplier = min amount possible
                updateConsumers xs = foldr (\(x, n) -> Stackable.update x (n * multiplier)) xs ps
                updateProducers xs = foldr (\(x, n) -> Stackable.update x -(n * multiplier)) xs cs
            in
                updateProducers <| updateConsumers <| products 
        _ -> products

deliveries : [ Stackable Producer ] -> [ Stackable Product ] -> BigNumber
deliveries producers products =
    let wrapped = Stackable.count Product.wrapped products
        step stackableProducer c =
            case stackableProducer of
                (Deliverer d, amount) -> wrapped - max 0 ((wrapped - c) - (d * amount))
                _ -> c
    in
        foldr step 0 <| map (\(x, amount) -> (x.function, amount)) producers