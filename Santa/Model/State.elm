module Santa.Model.State where

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
import Santa.Model.Producer (..)
import Santa.Model.Unlockable as Unlockable
import Santa.Model.Unlockable (Unlockable)

type Tab
    = Workshop
    | Research
    | Stats
    | Achievements

type alias State =
    { deliveries : BigNumber
    , dps : BigNumber
    , products : List (Stackable Product)
    , producers : List (Stackable Producer)
    , unlockables : List Unlockable
    , achievements : List Achievement
    , notifications : List String
    , purchaseMultiplier : BigNumber
    , selectedTab : Tab
    , timePlayed : Time
    , uniqueProductsProduced : List Product
    }

defaultStartState : State
defaultStartState =
    { deliveries = 0
    , dps = 0
    , products = []
    , producers = []
    , unlockables = []
    , achievements = []
    , notifications = []
    , purchaseMultiplier = 1
    , selectedTab = Workshop
    , timePlayed = 0
    , uniqueProductsProduced = []
    }

devStartState : State
devStartState =
    { defaultStartState
    | products <- map (stack 1000000) Product.basics
    , unlockables <-
        [ identity {}
            |> Named "RESEARCH TEST"
            |> Unlockable.researchable (1 * second)
            |> Unlockable.Upgrade
                [ Unlockable.ResearchPower 1 ]
        ]
    }

startState : State
startState = defaultStartState

type Condition = Condition (State -> Bool)
type alias Conditional x = { x | conditions : List Condition }
type alias Achievement = Named (Descriptive (Conditional {}))

producers : List Unlockable -> List (Purchasable Producer)
producers unlockables =
    let basics = []
        isUnlocked bonus =
            case bonus of
                Unlockable.UnlockProducer x -> Just x
                _ -> Nothing
        unlocked = filterMap isUnlocked <| concat <| map .bonus <| filter (\x -> x.progressTimer == 0) unlockables
    in
        basics ++ unlocked

updateProduction : Time -> State -> State
updateProduction deltaTime state =
    let powers = map (flip Unlockable.producerPower state.unlockables) <| map fst state.producers
        products = foldr (uncurry Producer.produce) state.products <| map2 (,) state.producers powers
        isUniqueProduct x = x.wrappable && all (\y -> y.name /= x.name) state.uniqueProductsProduced
        uniqueProductsProduced = filter isUniqueProduct <| map fst products
    in
        { state
        | products <- products
        , timePlayed <- state.timePlayed + deltaTime
        , uniqueProductsProduced <- state.uniqueProductsProduced ++ uniqueProductsProduced
        }

updateDeliveries : Time -> State -> State
updateDeliveries deltaTime state =
    let delta = Producer.deliveries state.producers state.products
        state' = deliverWrapped delta state
    in
        { state' | dps <- delta }

updateResearch : Time -> State -> State
updateResearch deltaTime state =
    let dt = deltaTime * (Unlockable.researchPower state.unlockables)
        updatedTimers = map (\x -> { x | progressTimer <- (max 0 (x.progressTimer - dt)) }) state.unlockables
        finished = map fst <| filter (\(x, y) -> x.progressTimer == 0 && y.progressTimer > 0) <| map2 (,) updatedTimers state.unlockables
    in
        { state
        | unlockables <- updatedTimers
        , notifications <- state.notifications ++ showResearchCompleted finished
        }

updateAchievements : State -> State
updateAchievements state =
    let checkCondition condition =
            case condition of
                Condition c -> c state
                _ -> False
        check achievement = all (\x -> checkCondition x) achievement.conditions
        checked = filter check achievements
        newAchievements = filter (\x -> all (\y -> y.name /= x.name) state.achievements) checked
    in
        { state
        | achievements <- state.achievements ++ newAchievements
        , notifications <- state.notifications ++ showAchievements newAchievements
        }

purchaseProducer : Purchasable Producer -> BigNumber -> State -> State
purchaseProducer purchasableProducer amount state =
    let (producers, products) = Purchasable.purchase Producer.cost purchasableProducer amount state.producers state.products
    in
        { state | producers <- producers, products <- products }

researchUnlockable : Purchasable Unlockable -> State -> State
researchUnlockable purchasableUnlockable state =
    let unlockableStack = map (stack 1) state.unlockables
        (unlockables, products) = Purchasable.purchase Purchasable.cost purchasableUnlockable 1 unlockableStack state.products
        unlockables' = map fst unlockables
    in
        { state | unlockables <- unlockables', products <- products }

deliverWrapped : BigNumber -> State -> State
deliverWrapped amount state =
    let remaining = Stackable.count Product.wrapped state.products
        target = state.deliveries + amount
        spiritsGained = round (toFloat amount * (Unlockable.spiritPower state.unlockables))
        --spiritsGained = (abs ((target // 10) - (state.deliveries // 10))) * 100
        deltas = [ (Product.wrapped, -amount), (Product.spirit, spiritsGained) ]
    in
        if | remaining - amount >= 0 ->
            { state
            | deliveries <- target
            , products <- Stackable.combine state.products deltas
            }
           | otherwise -> state

showAchievements : List Achievement -> List String
showAchievements achievements =
    map (\x -> "<b>ACHIEVEMENT - " ++ x.name ++ "</b><br/>" ++ x.description) achievements

showResearchCompleted : List Unlockable -> List String
showResearchCompleted unlockables =
    map (\x -> "<b>RESEARCH COMPLETE - " ++ x.name ++ "</b><br/>" ++ (String.concat <| intersperse ("<br/>") <| Unlockable.description x.bonus)) unlockables

-- Santa's Workshop

achievements =
    concat
        [ deliveryAchievements
        , otherAchievements
        , dpsAchievements
        ]

otherAchievements : List Achievement
otherAchievements =
    [ identity {}
        |> Named "Spirit of Christmas"
        |> Descriptive "Obtain a Christmas Spirit."
        |> Conditional
            [ Condition (\x -> (Stackable.count Product.spirit x.products) >= 1) ]
    , identity {}
        |> Named "It's the Thought That Counts"
        |> Descriptive "Produce a Wooden Toy."
        |> Conditional
            [ Condition (\x -> (Stackable.count Product.woodenToy x.products) >= 1) ]
    , identity {}
        |> Named "High-Tech Enterprise"
        |> Descriptive "Produce a PC."
        |> Conditional
            [ Condition (\x -> (Stackable.count Product.computer x.products) >= 1) ]
    , identity {}
        |> Named "North Pole, Alaska"
        |> Descriptive "Construct an Oil Rig."
        |> Conditional
            [ Condition (\x -> (Stackable.count { oilRig - cost } x.producers) >= 1) ]
    , identity {}
        |> Named "Dualism"
        |> Descriptive "Produce 2 different types of presents."
        |> Conditional
            [ Condition (\x -> (length x.uniqueProductsProduced) >= 2) ]
    , identity {}
        |> Named "Segmentation"
        |> Descriptive "Produce 4 different types of presents."
        |> Conditional
            [ Condition (\x -> (length x.uniqueProductsProduced) >= 4) ]
    , identity {}
        |> Named "Individualism"
        |> Descriptive "Produce 6 different types of presents."
        |> Conditional
            [ Condition (\x -> (length x.uniqueProductsProduced) >= 6) ]
    ]

deliveryAchievements : List Achievement
deliveryAchievements =
    let deliveryAchievement name amount =
            identity {}
                |> Named name
                |> Descriptive ("Deliver a total of " ++ toString amount ++ " presents.")
                |> Conditional [ Condition (\x -> x.deliveries >= amount) ]
        names = [ "Jingle Bells"
                , "Christmas Time Is Here"
                , "Winter Wonderland"
                , "White Christmas"
                , "Santa Clause Is Coming to Town"
                ]
        amounts = map (\x -> 10^x) [1..(length names)]
    in
        [ identity {}
            |> Named "Merry Christmas!"
            |> Descriptive "Make your first delivery."
            |> Conditional
                [ Condition (\x -> x.deliveries >= 1) ]
        ]
        ++ map2 deliveryAchievement names amounts

dpsAchievements : List Achievement
dpsAchievements =
    let dpsAchievement name amount =
            identity {}
                |> Named name
                |> Descriptive ("Reach " ++ toString amount ++ " deliveries per second.")
                |> Conditional [ Condition (\x -> x.dps >= amount) ]
        names = [ "Rudolph the Red-Nosed Reindeer"
                , "The Wonders of Automation"
                , "All Watched Over by Machines of Loving Grace"
                ]
        amounts = map (\x -> 10^x) [0..(length names - 1)]
    in
        map2 dpsAchievement names amounts