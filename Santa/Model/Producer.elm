module Santa.Model.Producer where

import List (..)

import Santa.Common (..)
import Santa.Model.Purchasable as Purchasable
import Santa.Model.Purchasable (Purchasable)
import Santa.Model.Stackable as Stackable
import Santa.Model.Stackable (Stackable, stack)
import Santa.Model.Product as Product
import Santa.Model.Product (Product)

type Function
    = Creator (List (Stackable Product))
    | Transformer (List (Stackable Product)) (List (Stackable Product))
    | Deliverer BigNumber

type alias Functional x = { x | function : List Function }
type alias Producer = Named (Functional {})

cost' : Purchasable Producer -> BigNumber -> List (Stackable Product)
cost' purchasableProducer x =
    --map (\(p, n) -> (p, (n * x)^(x // 2) + x^2)) baseCost
    let calc n = n + ((max 1 (n // 4)) * x)^2 // 2
    in
        map (\(p, n) -> (p, calc n)) purchasableProducer.cost

cost : Purchasable Producer -> BigNumber -> BigNumber -> List (Stackable Product)
cost purchasableProducer existing amount =
    let range = [existing..(existing + amount - 1)]
    in
        foldr Stackable.combine [] <| map (cost' purchasableProducer) range

produce' amount power function products =
    case function of
        Creator ps -> foldr (\(x, n) ps -> Stackable.update x (round (toFloat n * toFloat amount * power)) ps) products ps
        Transformer cs ps ->
            let possible = minimum <| map (\(x, n) -> (Stackable.count x products) // n) cs
                multiplier = min (toFloat amount) (toFloat possible)
                updateConsumers xs = foldr (\(x, n) -> Stackable.update x (round (toFloat n * multiplier))) xs ps
                updateProducers xs = foldr (\(x, n) -> Stackable.update x -(round (toFloat n * multiplier * power))) xs cs
            in
                updateProducers <| updateConsumers <| products 
        _ -> products

produce : Stackable Producer -> Float -> List (Stackable Product) -> List (Stackable Product)
produce (producer, amount) power products =
    foldr (produce' amount power) products producer.function

deliveries : List (Stackable Producer) -> List (Stackable Product) -> BigNumber
deliveries producers products =
    let w = Stackable.count Product.wrapped products
        step (d, amount) c = w - max 0 ((w - c) - (d * amount))
        deliverAmount function =
            case function of
                Deliverer d -> d
                _ -> 0
    in
        foldr step 0 <| map (\(x, n) -> (foldr (+) 0 <| map deliverAmount x.function, n)) producers

-- Santa's Workshop

lumberjack
    = identity {}
    |> Named "Lumberjack"
    |> Purchasable [ stack 1 Product.spirit ]
    |> Functional
        [ Creator [ stack 1 Product.wood ] ]

miner
    = identity {}
    |> Named "Miner"
    |> Purchasable [ stack 1 Product.spirit ]
    |> Functional
        [ Creator [ stack 1 Product.metal ] ]

oilRig
    = identity {}
    |> Named "Oil Rig"
    |> Purchasable
        [ stack 10 Product.wood
        , stack 10 Product.metal
        , stack 1 Product.spirit
        ]
    |> Functional
        [ Creator [ stack 1 Product.oil ] ]

santasLittleHelper
    = identity {}
    |> Named "Santa's Little Helper"
    |> Purchasable [ stack 1 Product.spirit ]
    |> Functional
        [ Creator [ stack 1 Product.spirit ] ]

woodenToyMaker
    = identity {}
    |> Named "Wooden Toy Maker"
    |> Purchasable [ stack 10 Product.wood ]
    |> Functional
        [ Transformer
            [ stack 3 Product.wood ]
            [ stack 1 Product.woodenToy ]
        ]

metalCarFactory
    = identity {}
    |> Named "Toy Car Factory"
    |> Purchasable [ stack 10 Product.metal ]
    |> Functional
        [ Transformer
            [ stack 3 Product.metal ]
            [ stack 1 Product.metalCar ]
        ]

plasticFactory
    = identity {}
    |> Named "Oil Refinery"
    |> Purchasable [ stack 5 Product.metal, stack 5 Product.oil ]
    |> Functional
        [ Transformer
            [ stack 1 Product.oil ]
            [ stack 1 Product.plastic ]
        ]

batteryFactory
    = identity {}
    |> Named "Battery Manufacturer"
    |> Purchasable [ stack 10 Product.metal, stack 10 Product.oil ]
    |> Functional
        [ Transformer
            [ stack 1 Product.metal, stack 1 Product.oil ]
            [ stack 1 Product.battery ]
        ]

microchipFactory
    = identity {}
    |> Named "Microchip Manufacturer"
    |> Purchasable [ stack 20 Product.metal, stack 20 Product.oil ]
    |> Functional
        [ Transformer
            [ stack 1 Product.metal, stack 1 Product.spirit ]
            [ stack 1 Product.microchip ]
        ]

legoFactory
    = identity {}
    |> Named "Lego Factory"
    |> Purchasable [ stack 10 Product.metal, stack 10 Product.oil ]
    |> Functional
        [ Transformer
            [ stack 3 Product.plastic ]
            [ stack 1 Product.legos ]
        ]

rcCarFactory
    = identity {}
    |> Named "RC Car Factory"
    |> Purchasable [ stack 30 Product.metal, stack 10 Product.oil ]
    |> Functional
        [ Transformer
            [ stack 3 Product.plastic, stack 1 Product.battery ]
            [ stack 1 Product.rcCar ]
        ]

computerFactory
    = identity {}
    |> Named "PC Manufacturer"
    |> Purchasable [ stack 50 Product.metal, stack 30 Product.oil ]
    |> Functional
        [ Transformer
            [ stack 3 Product.plastic, stack 3 Product.microchip ]
            [ stack 1 Product.computer ]
        ]

gameConsoleFactory
    = identity {}
    |> Named "Game Console Manufacturer"
    |> Purchasable [ stack 50 Product.metal, stack 30 Product.oil ]
    |> Functional
        [ Transformer
            [ stack 3 Product.plastic, stack 1 Product.microchip, stack 1 Product.battery ]
            [ stack 1 Product.gameConsole ]
        ]

paperFactory
    = identity {}
    |> Named "Paper Factory"
    |> Purchasable [ stack 10 Product.wood, stack 10 Product.metal ]
    |> Functional
        [ Transformer
            [ stack 1 Product.wood ]
            [ stack 5 Product.wrappingPaper ]
        ]

toyWrapper
    = identity {}
    |> Named "Simple Toy Wrapper"
    |> Purchasable [ stack 3 Product.spirit ]
    |> Functional
        [ Transformer
            [ stack 1 Product.woodenToy, stack 1 Product.wrappingPaper ]
            [ stack 1 Product.wrapped ]
        , Transformer
            [ stack 1 Product.metalCar, stack 1 Product.wrappingPaper ]
            [ stack 1 Product.wrapped ]
        ]

advancedToyWrapper
    = identity {}
    |> Named "Boxed Toy Wrapper"
    |> Purchasable [ stack 3 Product.spirit ]
    |> Functional
        [ Transformer
            [ stack 1 Product.legos, stack 1 Product.wrappingPaper ]
            [ stack 1 Product.wrapped ]
        , Transformer
            [ stack 1 Product.rcCar, stack 1 Product.wrappingPaper ]
            [ stack 1 Product.wrapped ]
        ]

highTechToyWrapper
    = identity {}
    |> Named "High-Tech Product Wrapper"
    |> Purchasable [ stack 3 Product.spirit ]
    |> Functional
        [ Transformer
            [ stack 1 Product.computer, stack 1 Product.wrappingPaper ]
            [ stack 1 Product.wrapped ]
        , Transformer
            [ stack 1 Product.gameConsole, stack 1 Product.wrappingPaper ]
            [ stack 1 Product.wrapped ]
        ]

reindeer
    = identity {}
    |> Named "Reindeer"
    |> Purchasable [ stack 5 Product.spirit ]
    |> Functional
        [ Deliverer 3 ]

airplane
    = identity {}
    |> Named "Airplane"
    |> Purchasable
        [ stack 10 Product.metal
        , stack 10 Product.oil
        , stack 10 Product.spirit
        ]
    |> Functional
        [ Deliverer 10 ]

producers : List (Purchasable Producer)
producers =
    [ lumberjack
    , miner
    , oilRig
    , santasLittleHelper
    , woodenToyMaker
    , metalCarFactory
    , plasticFactory
    , batteryFactory
    , microchipFactory
    , legoFactory
    , rcCarFactory
    , computerFactory
    , gameConsoleFactory
    , paperFactory
    , toyWrapper
    , advancedToyWrapper
    , highTechToyWrapper
    , reindeer
    , airplane
    ]