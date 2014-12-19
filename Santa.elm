module Santa where

import Result
import Maybe
import Signal (..)
import Time (..)
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Lazy as Ref
import Graphics.Element (Element)
import Graphics.Input as Input
import Keyboard
import Window
import Json.Decode

import Santa.Common (..)
import Santa.Model.State as State
import Santa.Model.State (State)
import Santa.View.View as View
import Santa.Controller.Controller as Controller
import Santa.Controller.Controller (..)
import Santa.Controller.Persistence as Persistence

-- UPDATE

setPurchaseMultiplierSignal : Signal Action
setPurchaseMultiplierSignal = 
    let selectMultiplier ctrlDown shiftDown =
            if | ctrlDown && shiftDown -> SetPurchaseMultiplier 100
               | ctrlDown -> SetPurchaseMultiplier 25
               | shiftDown -> SetPurchaseMultiplier 10
               | otherwise -> SetPurchaseMultiplier 1
    in
        selectMultiplier <~ Keyboard.ctrl ~ Keyboard.shift

updateProductionSignal : Signal Action
updateProductionSignal = UpdateProduction <~ fps 1

updateDeliveriesSignal : Signal Action
updateDeliveriesSignal = UpdateDeliveries <~ (delay (500 * millisecond) <| fps 1)

updateResearchSignal : Signal Action
updateResearchSignal = UpdateResearch <~ fps 1

startingState : State
startingState =
    case getStorage of
        Just data -> Maybe.withDefault State.startState <| Result.toMaybe <| Json.Decode.decodeString Persistence.decode data
        Nothing -> State.startState

state : Signal State
state =
    let signals =
            [ actionSignal
            , updateProductionSignal
            , updateDeliveriesSignal
            , updateResearchSignal
            , setPurchaseMultiplierSignal
            , sampleOn
                (keepIf (\x -> x == True) False confirmDialog)
                (snd <~ subscribe Controller.requestChannel)
            ]
    in
        foldp Controller.step startingState <| mergeMany signals

scene : State -> (Int, Int) -> Element
scene state (w, h) = toElement w h (View.display state)

port showNotification : Signal (List String)
port showNotification = dropRepeats <| .notifications <~ state

port getStorage : Maybe String

port setStorage : Signal String
port setStorage = sampleOn (every (1 * second)) (Persistence.encode <~ state)

port requestDialog : Signal String
port requestDialog = fst <~ subscribe Controller.requestChannel

port confirmDialog : Signal Bool

main = scene <~ state ~ Window.dimensions