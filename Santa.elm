module Santa where

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

import Santa.Model.State as State
import Santa.Model.State (State)
import Santa.View.View (..)
import Santa.Controller.Controller as Controller
import Santa.Controller.Controller (..)

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

state : Signal State
state =
    let signals =
            [ actionSignal
            , updateProductionSignal
            , updateDeliveriesSignal
            , updateResearchSignal
            , setPurchaseMultiplierSignal
            ]
    in
        foldp Controller.step State.startState <| mergeMany signals

scene : State -> (Int, Int) -> Element
scene state (w, h) = toElement w h (display state)

port showNotification : Signal (List String)
port showNotification = dropRepeats <| .notifications <~ state

main = scene <~ state ~ Window.dimensions