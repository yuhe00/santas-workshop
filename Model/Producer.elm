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

type Purchasable a = { a | cost : [ Stackable Product ] }
type Functionable a = { a | function : Function }
type Producer = Named (Functionable {})

santasLittleHelper : Purchasable Producer
santasLittleHelper
    = identity {}
    |> Named "Santa's Little Helper"
    |> Purchasable [ stack 1 Product.christmasSpirit ]
    |> Functionable
        ( Creator [ stack 1 Product.toy ] )

toyWrapper : Purchasable Producer
toyWrapper
    = identity {}
    |> Named "Toy Wrapper"
    |> Purchasable [ stack 3 Product.christmasSpirit ]
    |> Functionable
        ( Transformer
            [ stack 1 Product.toy ]
            [ stack 1 Product.wrapped ]
        )

reindeer : Purchasable Producer
reindeer
    = identity {}
    |> Named "Reindeer"
    |> Purchasable [ stack 5 Product.christmasSpirit ]
    |> Functionable
        ( Deliverer 10 )

producers : [ Purchasable Producer ]
producers =
    [ santasLittleHelper,
      toyWrapper,
      reindeer
    ]

cost : Purchasable Producer -> BigNumber -> [ Stackable Product ] 
cost purchasableProducer x =
    --map (\(p, n) -> (p, (n * x)^(x // 2) + x^2)) baseCost
    map (\(p, n) -> (p, (n + x)^2)) purchasableProducer.cost

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