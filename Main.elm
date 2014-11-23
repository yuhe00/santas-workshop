import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)
import Html.Optimize.RefEq as Ref
import Graphics.Input as Input
import Window

import Common
import Common (BigNumber)
import Stackable
import Stackable (Stackable)
import State
import State (State)
import Product
import Product (Product)
import Producer
import Producer (Producer, Purchasable)

-- VIEW

displayTitle : Html
displayTitle =
    h1 [] [ text "SANTA'S WORKSHOP" ]

displayDeliveredPresents : State -> Html
displayDeliveredPresents state =
    text <| concat [ "DELIVERED PRESENTS: ", show state.deliveredPresents ]

displayProducts : [ Stackable Product ] -> Html
displayProducts products =
    let listElements = map ((\(x, n) -> show n ++ "x " ++ Common.name x) >> text >> (\x -> li [] [x])) products
    in
        div []
            [ ul [] listElements ]
            

displayProducers : [ Stackable Producer ] -> Html
displayProducers producers =
    ul [] <| map ((\(x, n) -> show n ++ "x " ++ Common.name x) >> text >> (\x -> li [] [x])) producers

displayPurchasableProducers : [ Stackable Producer ] -> Html
displayPurchasableProducers producers =
    div [] <| map (flip displayPurchasableProducer producers) Producer.producers

displayPurchasableProducer : Purchasable Producer -> [ Stackable Producer ] -> Html
displayPurchasableProducer purchasableProducer producers =
    let producer = { purchasableProducer - cost }
        cost = Producer.cost purchasableProducer <| Stackable.count producer producers
        name = Common.name producer
    in
        div
            []
            [ text name
            , displayProducts cost
            , div
                []
                [ button
                    [ onclick actionInput.handle (always (Purchase purchasableProducer 1)) ]
                    [ text "Purchase 1x" ]
                , button
                    [ onclick actionInput.handle (always (Purchase purchasableProducer 10)) ]
                    [ text "Purchase 10x" ]
                ]
            ]

testButtons : Html
testButtons =
    div
        []
        [ button
            [ onclick actionInput.handle (always Click) ]
            [ text "Create Toy" ]
        , button
            [ onclick actionInput.handle (always (Wrap Product.toy)) ]
            [ text "Wrap Toy" ]
        , button
            [ onclick actionInput.handle (always Deliver) ]
            [ text "Deliver Present" ]
        ]

display : State -> Html
display state =
    div
        [ style
            [ prop "margin" "1em" ]
        ]
        [ displayTitle
        , main'
            []
            [ Ref.lazy displayDeliveredPresents state
            , testButtons
            , Ref.lazy displayPurchasableProducers state.producers
            , Ref.lazy displayProducts state.products
            , Ref.lazy displayProducers state.producers
            ]
        ]

-- UPDATE

data Action
    = NoOp
    | UpdateProduction Time
    | UpdateDeliveries Time
    | Click
    | Wrap Product
    | Deliver
    | Purchase (Purchasable Producer) BigNumber
    | Anything (State -> State)

step : Action -> State -> State
step action state =
    case action of
        NoOp -> state
        UpdateProduction time -> State.updateProduction time state
        UpdateDeliveries time -> State.updateDeliveries time state
        Click -> { state | products <- Stackable.update Product.toy 1 state.products }
        Wrap x -> { state | products <- Product.wrap x 1 state.products }
        Deliver -> State.deliverWrapped 1 state
        Purchase producer n -> State.purchase producer n state
        Anything apply -> apply state

actionInput : Input.Input Action
actionInput = Input.input NoOp

updateProductionSignal : Signal Time
updateProductionSignal = fps 3

updateDeliveriesSignal : Signal Time
updateDeliveriesSignal = fps 1

state : Signal State
state =
    let actionSignals =
        [ actionInput.signal
        , UpdateProduction <~ updateProductionSignal
        , UpdateDeliveries <~ updateDeliveriesSignal ]
    in
        foldp step State.startState <| merges actionSignals

scene : State -> (Int, Int) -> Element
scene state (w, h) = container w h midTop (toElement w h (display state))

main = scene <~ state ~ Window.dimensions