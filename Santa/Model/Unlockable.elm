module Santa.Model.Unlockable where

import List (..)
import String
import Time (..)

import Santa.Common (..)
import Santa.Model.Purchasable as Purchasable
import Santa.Model.Purchasable (Purchasable)
import Santa.Model.Stackable as Stackable
import Santa.Model.Stackable (Stackable, stack)
import Santa.Model.Product as Product
import Santa.Model.Product (Product)
import Santa.Model.Producer as Producer
import Santa.Model.Producer (Producer)

type Bonus
    = ClickPower Float
    | SpiritPower Float
    | ResearchPower Float
    | ProducerPower (Purchasable Producer) Float
    | UnlockProducer (Purchasable Producer)
    | Unlock (Purchasable Unlockable)

type alias Upgrade x = { x | bonus : List Bonus }
type alias Researchable x = { x | progressTimer : Time, progressMax : Time }
type alias Unlockable = Named (Researchable (Upgrade {}))

researchable time = Researchable time time

formatPct : Float -> String
formatPct pct = toString (round (pct * 100)) ++ "%" 

description : List Bonus -> List String
description bonuses =
    let formatPower function displayFunction bonuses =
            let x = foldr (+) 0 <| map function bonuses
            in
                if | x > 0 -> Just <| displayFunction x
                   | otherwise -> Nothing
        powers = map (\(x, y) -> formatPower x y bonuses)
            [ (clickPower', (\x -> "Increases resources gained from clicking by " ++ formatPct x ++ "."))
            , (spiritPower', (\x -> "Increases the amount of spirits gained from deliveries by " ++ formatPct x ++ "."))
            , (researchPower', (\x -> "Increases research speed by " ++ formatPct x ++ "."))
            ]
        producerPowers =
            let ps = filterMap producerPower' bonuses
                products = map fst ps
                totals = map (\x -> foldr (+) 0 <| map (\(y, n) -> if y.name == x.name then n else 1) ps) products
                display x n =
                    "Increases the efficiency of " ++ x.name ++ " by " ++ formatPct n ++ "."
            in
                if | isEmpty ps -> Nothing
                   | otherwise -> Just <| String.concat <| map2 display products totals
        unlockedProducers =
            let check bonus =
                    case bonus of
                        UnlockProducer x -> Just x
                        _ -> Nothing
                showProducers xs =
                    if | isEmpty xs -> Nothing
                       | otherwise -> Just <| "Allows you to build " ++ (foldr1 (\x y -> x ++ ", " ++ y) <| map .name xs) ++ "."
            in 
                showProducers <| filterMap check bonuses
        unlockeds =
            let check bonus =
                    case bonus of
                        Unlock x -> Just x
                        _ -> Nothing
                showUnlockeds xs =
                    if | isEmpty xs -> Nothing
                       | otherwise -> Just <| "Unlocks " ++ (foldr1 (\x y -> x ++ ", " ++ y) <| map .name xs) ++ "."
            in
                showUnlockeds <| filterMap check bonuses
    in
        filterMap identity <| concat
            [ powers
            , [ producerPowers, unlockedProducers, unlockeds ]
            ]

availableUnlockables : List Unlockable -> List (Purchasable Unlockable)
availableUnlockables current =
    let basic = [ forestry, mining ]
        findUnlockable bonus =
            case bonus of
                Unlock x -> Just x
                _ -> Nothing
        completed = filter (\x -> x.progressTimer == 0) current
        available = filterMap findUnlockable <| concatMap .bonus completed
    in
        filter (\x -> all (\y -> x.name /= y.name) current) (basic ++ available)

clickPower' : Bonus -> Float
clickPower' bonus =
    case bonus of
        ClickPower x -> x
        _ -> 0

spiritPower' : Bonus -> Float
spiritPower' bonus =
    case bonus of
        SpiritPower x -> x
        _ -> 0

researchPower' : Bonus -> Float
researchPower' bonus =
    case bonus of
        ResearchPower x -> x
        _ -> 0

bonuses : List Unlockable -> List Bonus
bonuses unlockables =
    concatMap .bonus <| filter (\x -> x.progressTimer == 0) unlockables

producerPower' : Bonus -> Maybe (Producer, Float)
producerPower' bonus =
    case bonus of
        ProducerPower p x -> Just ({ p - cost }, x)
        _ -> Nothing

clickPower : List Unlockable -> Float
clickPower unlockables =
    foldr (+) 1 <| map clickPower' <| bonuses unlockables

spiritPower : List Unlockable -> Float
spiritPower unlockables =
    foldr (+) 1 <| map spiritPower' <| bonuses unlockables

researchPower : List Unlockable -> Float
researchPower unlockables =
    foldr (+) 1 <| map researchPower' <| bonuses unlockables

producerPower : Producer -> List Unlockable -> Float
producerPower producer unlockables =
    let pp (p, x) =
            if | p.name == producer.name -> Just x
               | otherwise -> Nothing
    in
        foldr (+) 1 <| filterMap pp <| filterMap producerPower' <| bonuses unlockables

-- Santa's Workshop

forestry
    = identity {}
    |> Named "Forestry"
    |> researchable (5 * second)
    |> Purchasable [ stack 5 Product.wood ]
    |> Upgrade
        [ UnlockProducer Producer.lumberjack
        , Unlock woodworking
        , Unlock reindeerFarm
        , Unlock chainsaws
        ]

mining
    = identity {}
    |> Named "Mining"
    |> researchable (5 * second)
    |> Purchasable [ stack 5 Product.metal ]
    |> Upgrade
        [ UnlockProducer Producer.miner
        , Unlock manufacturing
        ]

manufacturing
    = identity {}
    |> Named "Manufacturing"
    |> researchable (10 * second)
    |> Purchasable [ stack 10 Product.metal ]
    |> Upgrade
        [ UnlockProducer Producer.metalCarFactory
        , Unlock advancedTechnology
        , Unlock scientificMethod
        ]

scientificMethod
    = identity {}
    |> Named "Scientific Method"
    |> researchable (10 * second)
    |> Purchasable
        [ stack 10 Product.wood
        , stack 10 Product.metal
        , stack 10 Product.oil
        ]
    |> Upgrade
        [ ResearchPower 0.2 ]

advancedTechnology
    = identity {}
    |> Named "Advanced Technology"
    |> researchable (30 * minute)
    |> Purchasable 
        [ stack 300 Product.wood
        , stack 300 Product.metal
        , stack 100 Product.oil
        , stack 10 Product.spirit
        ]
    |> Upgrade
        [ UnlockProducer Producer.oilRig
        , UnlockProducer Producer.advancedToyWrapper
        , Unlock plastics
        , Unlock batteries
        , Unlock microchips
        ]

plastics
    = identity {}
    |> Named "Plastics"
    |> researchable (1 * hour)
    |> Purchasable [ stack 300 Product.oil, stack 100 Product.spirit ]
    |> Upgrade
        [ UnlockProducer Producer.plasticFactory
        , UnlockProducer Producer.legoFactory
        ]

batteries
    = identity {}
    |> Named "Battery Power"
    |> researchable (1 * hour)
    |> Purchasable [ stack 300 Product.oil, stack 100 Product.spirit ]
    |> Upgrade
        [ UnlockProducer Producer.batteryFactory
        , UnlockProducer Producer.rcCarFactory
        ]

microchips
    = identity {}
    |> Named "Integrated Circuits"
    |> researchable (1 * hour)
    |> Purchasable [ stack 300 Product.oil, stack 100 Product.spirit ]
    |> Upgrade
        [ UnlockProducer Producer.microchipFactory
        , UnlockProducer Producer.computerFactory
        , UnlockProducer Producer.gameConsoleFactory
        , UnlockProducer Producer.highTechToyWrapper
        , Unlock roboticArms
        ]

roboticArms
    = identity {}
    |> Named "Robotic Arms"
    |> researchable (2 * hour)
    |> Purchasable
        [ stack 300 Product.metal
        , stack 300 Product.oil
        , stack 100 Product.spirit
        ]
    |> Upgrade
        [ ClickPower 5 ]

chainsaws
    = identity {}
    |> Named "Chainsaws"
    |> researchable (3 * minute)
    |> Purchasable [ stack 30 Product.metal ]
    |> Upgrade
        [ ProducerPower Producer.lumberjack 1 ]

woodworking
    = identity {}
    |> Named "Woodworking"
    |> researchable (10 * second)
    |> Purchasable [ stack 10 Product.wood, stack 10 Product.metal ]
    |> Upgrade
        [ UnlockProducer Producer.woodenToyMaker
        , Unlock naturalOrder
        , Unlock papermaking
        ]

naturalOrder
    = identity {}
    |> Named "Natural Order"
    |> researchable (1 * minute)
    |> Purchasable [ stack 20 Product.wood, stack 20 Product.metal ]
    |> Upgrade [ ClickPower 1 ]

papermaking
    = identity {}
    |> Named "Paper-making"
    |> researchable (30 * second)
    |> Purchasable [ stack 20 Product.wood, stack 20 Product.metal ]
    |> Upgrade
        [ UnlockProducer Producer.paperFactory
        , UnlockProducer Producer.toyWrapper
        ]

reindeerFarm
    = identity {}
    |> Named "Reindeer Farm"
    |> researchable (1 * minute)
    |> Purchasable
        [ stack 30 Product.wood
        , stack 30 Product.metal
        , stack 10 Product.spirit
        ]
    |> Upgrade
        [ UnlockProducer Producer.reindeer
        , Unlock spiritsOfTheForest
        ]

spiritsOfTheForest
    = identity {}
    |> Named "Spirits of the Forest"
    |> researchable (5 * minute)
    |> Purchasable [ stack 100 Product.wood ]
    |> Upgrade [ SpiritPower 1 ]