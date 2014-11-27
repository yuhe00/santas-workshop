module Model.State where

import Common (..)
import Model.Stackable as Stackable
import Model.Stackable (Stackable)
import Model.Product as Product
import Model.Product (Product)
import Model.Producer as Producer
import Model.Producer (Producer, Purchasable)
import Model.Unlockable as Unlockable
import Model.Unlockable (Unlockable)

data Tab
    = Workshop
    | Research
    | Stats
    | Achievements

type State =
    { deliveries : BigNumber
    , dps : BigNumber
    , products : [ Stackable Product ]
    , producers : [ Stackable Producer ]
    , unlockables : [ Unlockable ]
    , achievements : [ Achievement ]
    , notifications : [ String ]
    , purchaseMultiplier : BigNumber
    , selectedTab : Tab
    }

startState : State
startState =
    { deliveries = 0
    , dps = 0
    , products = []
    , producers = []
    , unlockables =
        [ { name = "Test",
            description = "Increases your click power by 1000%",
            bonus = Unlockable.ClickPower 10
        } ]
    , achievements = []
    , notifications = []
    , purchaseMultiplier = 1
    , selectedTab = Workshop
    }

data Condition = Condition (State -> Bool)
type Conditional x = { x | conditions : [ Condition ] }
type Achievement = Named (Descriptive (Conditional {}))

achievements =
    [ identity {}
        |> Named "Merry Christmas!"
        |> Descriptive "Make your first delivery."
        |> Conditional
            [ Condition (\x -> x.deliveries > 0) ]
    , identity {}
        |> Named "Christmas Time Is Here"
        |> Descriptive "Obtain a Christmas Spirit."
        |> Conditional
            [ Condition (\x -> (Stackable.count Product.spirit x.products) > 0) ]
    , identity {}
        |> Named "The Wonders of Automation"
        |> Descriptive "Reach 1 delivery per second."
        |> Conditional
            [ Condition (\x -> x.dps >= 1) ]
    , identity {}
        |> Named "\"Horn\"-aments"
        |> Descriptive "Reach 100 deliveries per second."
        |> Conditional
            [ Condition (\x -> x.dps >= 100) ]
    , identity {}
        |> Named "All Watched Over by Machines of Loving Grace"
        |> Descriptive "Reach 10000 deliveries per second."
        |> Conditional
            [ Condition (\x -> x.dps >= 10000) ]
    ]

producers : [ Unlockable ] -> [ Purchasable Producer ]
producers unlockables =
    let basics = [ Producer.lumberjack, Producer.miner, Producer.toyWrapper ]
        isUnlocked unlockable =
            case unlockable.bonus of
                Unlockable.Unlock x -> Just x
                _ -> Nothing
        unlocked = filterMap isUnlocked unlockables
    in
        basics ++ unlocked

updateProduction : Time -> State -> State
updateProduction deltaTime state =
    { state | products <- foldr Producer.produce state.products state.producers }

updateDeliveries : Time -> State -> State
updateDeliveries deltaTime state =
    let delta = Producer.deliveries state.producers state.products
        state' = deliverWrapped delta state
    in
        { state' | dps <- delta }

canAfford : [ Stackable Product ] -> [ Stackable Product ] -> Bool
canAfford cost products =
    all (\(x, n) -> (Stackable.count x products) >= n) cost

purchase : Purchasable Producer -> BigNumber -> State -> State
purchase purchasableProducer amount state =
    let producer = { purchasableProducer - cost } 
        existing = Stackable.count producer state.producers
        totalCost = Producer.cost purchasableProducer existing amount
    in
        if | canAfford totalCost state.products ->
            { state
            | producers <- Stackable.update producer amount state.producers
            , products <- Stackable.combine state.products <| map (\(x, n) -> (x, -n)) totalCost
            }
           | otherwise -> state

deliverWrapped : BigNumber -> State -> State
deliverWrapped amount state =
    let remaining = Stackable.count Product.wrapped state.products
        target = state.deliveries + amount
        spiritsGained = (abs ((target // 10) - (state.deliveries // 10))) * 100
        deltas = [ (Product.wrapped, -amount), (Product.spirit, spiritsGained) ]
    in
        if | remaining - amount >= 0 ->
            { state
            | deliveries <- target
            , products <- Stackable.combine state.products deltas
            }
           | otherwise -> state

updateAchievements : State -> [ Achievement ]
updateAchievements state =
    let checkCondition condition =
            case condition of
                Condition c -> c state
                _ -> False
        check achievement = all (\x -> checkCondition x) achievement.conditions
    in
        filter check achievements