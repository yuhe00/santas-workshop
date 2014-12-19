module Santa.Controller.Controller where

import Signal
import Signal (Signal)
import Time (..)

import Santa.Common
import Santa.Common (BigNumber)
import Santa.Model.Purchasable as Purchasable
import Santa.Model.Purchasable (Purchasable)
import Santa.Model.Stackable as Stackable
import Santa.Model.Stackable (Stackable)
import Santa.Model.State as State
import Santa.Model.State (State)
import Santa.Model.Product as Product
import Santa.Model.Product (Product)
import Santa.Model.Producer as Producer
import Santa.Model.Producer (Producer)
import Santa.Model.Unlockable as Unlockable
import Santa.Model.Unlockable (Unlockable)

type Action
    = NoOp
    | UpdateProduction Time
    | UpdateDeliveries Time
    | UpdateResearch Time
    | Create Product
    | Produce Product
    | Wrap Product
    | Deliver
    | Purchase (Purchasable Producer) BigNumber
    | Research (Purchasable Unlockable)
    | SetPurchaseMultiplier BigNumber
    | SelectTab State.Tab
    | Reset

step : Action -> State -> State
step action state =
    let state' = { state | notifications <- [] }
        state'' =
            case action of
                NoOp -> state'
                UpdateProduction time -> State.updateProduction time state'
                UpdateDeliveries time -> State.updateDeliveries time state'
                UpdateResearch time -> State.updateResearch time state'
                Create x ->
                    let amount = round (Unlockable.clickPower state'.unlockables)
                    in
                        { state' | products <- Stackable.update x amount state'.products }
                Produce x -> state'
                Wrap x -> { state' | products <- Product.wrap x 1 state'.products }
                Deliver -> State.deliverWrapped 1 state'
                Purchase x n -> State.purchaseProducer x n state'
                Research x -> State.researchUnlockable x state'
                SetPurchaseMultiplier x -> { state' | purchaseMultiplier <- x }
                SelectTab x -> { state' | selectedTab <- x }
                Reset -> State.defaultStartState
    in
        State.updateAchievements state''

actionChannel : Signal.Channel Action
actionChannel = Signal.channel NoOp

actionSignal : Signal Action
actionSignal = Signal.subscribe actionChannel

requestChannel : Signal.Channel (String, Action)
requestChannel = Signal.channel ("", NoOp)