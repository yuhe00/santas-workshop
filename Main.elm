module Main where

import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Tags (..)
import Html.Optimize.RefEq as Ref
import Graphics.Input as Input
import Keyboard
import Window

import Common
import Common (BigNumber)
import Model.Stackable as Stackable
import Model.Stackable (Stackable)
import Model.State as State
import Model.State (State)
import Model.Product as Product
import Model.Product (Product)
import Model.Producer as Producer
import Model.Producer (Producer, Purchasable)
import Model.Unlockable as Unlockable
import Model.Unlockable (Unlockable)

-- VIEW

displayTitle : Html
displayTitle =
    div
        [ class "pure-u-1-1" ]
        [ h1
            [ style [ prop "text-align" "center" ] ]
            [ text "Santa's Workshop" ]
        ]

displayDeliveries : BigNumber -> BigNumber -> Html
displayDeliveries deliveries dps =
    div
        [ class "pure-u-1-1"
        , style [ prop "text-align" "center" ] ]
        [ span
            [ style [ prop "font-size" "50pt" ] ]
            [ text <| show deliveries ]
        , div
            []
            [ text "DELIVERIES MADE"
            , text <| " (+"++ (show <|dps) ++ "/s)"
            ]
        ]

displayProducts : [ Stackable Product ] -> Html
displayProducts products =
    let items = map ((\(x, n) -> show n ++ "x " ++ Common.name x) >> text >> (\x -> li [] [x])) products
    in
        div [] [ ul [] items ]

displayHorizontal : [ Attribute ] -> [ Html ] -> Html
displayHorizontal attributes elements =
    div
        attributes
        <| map (\x -> div [ style [ prop "display" "inline-block" ] ] [ x ]) elements

displayProducerFunction : Producer -> Html
displayProducerFunction producer =
    case producer.function of
        Producer.Creator ps ->
            div
                []
                [ em [] [ text "Gathers (per second):" ]
                , div
                    [ style [ prop "padding" "0.5em" ] ]
                    [ displayProducts ps ]
                ]
        Producer.Transformer cs ps ->
            let vass =
                [ style
                    [ prop "display" "inline-block"
                    , prop "vertical-align" "middle"
                    , prop "padding" "0.5em"
                    ]
                ]
            in
                div
                    []
                    [ em [] [ text "Produces (per second):" ]
                    , div
                        []
                        <| map (\x -> span vass [ x ])
                            [ displayProducts cs
                            , text "➜"
                            , displayProducts ps
                            ]
                    ]
        Producer.Deliverer n ->
            div
                []
                [ em [] [ text "Delivers: " ]
                , div
                    [ style [ prop "padding" "0.5em" ] ]
                    [ text <| (show n) ++ " packages per second" ]
                ] 

displayPurchasableProducers : BigNumber -> [ Stackable Producer ] -> [ Stackable Product ] -> [ Unlockable ] -> Html
displayPurchasableProducers purchaseMultiplier producers products unlockables =
    let ps = State.producers unlockables
        items = map (\x -> displayPurchasableProducer purchaseMultiplier x producers products) ps
    in
        table
            [ id "purchasableProducers"
            , class "table table-condensed" ]
            [ tbody
                []
                items
            ]

displayPurchasableProducer : BigNumber -> Purchasable Producer -> [ Stackable Producer ] -> [ Stackable Product ] -> Html
displayPurchasableProducer purchaseMultiplier purchasableProducer producers products =
    let producer = { purchasableProducer - cost }
        cost = Producer.cost purchasableProducer (Stackable.count producer producers) purchaseMultiplier
        canAfford = State.canAfford cost products
        costColor =
            if | canAfford -> "#fff"
               | otherwise -> "#f00"
        purchaseAction = Purchase purchasableProducer purchaseMultiplier
        purchaseAmountText =
            if | purchaseMultiplier == 1 -> ""
               | otherwise -> " " ++ show purchaseMultiplier ++ "x"
        amount = (show <| Stackable.count producer producers) ++ ""
    in
        tr
            [ class "purchasable" ]
            [ td
                [ style [ prop "vertical-align" "middle" ] ]
                [ div
                    [ style
                        [ prop "font-size" "30pt"
                        , prop "text-align" "right"
                        , prop "width" "3em"
                        ]
                    ]
                    [ text amount ]
                ]
            , td
                [ style [ prop "vertical-align" "middle" ] ]
                [ div
                    [ class "tooltip-wrapper" ]
                    [ span
                        [ class "trigger" ]
                        [ b [] [ text producer.name ] ]
                    , div
                        [ class "tooltip" ]
                        [ div
                            []
                            [ div
                                [ style [ prop "white-space" "nowrap" ] ]
                                [ displayProducerFunction producer ]
                            ]
                        ]
                    ]
                ]
            , td
                [ style [ prop "vertical-align" "middle" ] ]
                [ div
                    [ class "tooltip-wrapper" ]
                    [ button
                        [ class "btn btn-default trigger"
                        , disabled <| not canAfford
                        , style [ prop "width" "10em" ]
                        , onclick actionInput.handle (always purchaseAction) ]
                        [ text <| "Purchase" ++ purchaseAmountText ]
                    , div
                        []
                        [ div
                            [ class "tooltip" ]
                            [ div
                                [ style
                                    [ prop "color" costColor
                                    , prop "width" "auto" ]
                                ]
                                [ em [] [ text "Cost:" ]
                                , div
                                    [ style
                                        [ prop "white-space" "nowrap"
                                        , prop "padding" "0.5em"
                                        ]
                                    ]
                                    [ displayProducts cost ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]

displayTestButtons : Html
displayTestButtons =
    let actionButton action t =
            button
                [ class "btn btn-default"
                , onclick actionInput.handle (always action)
                ]
                [ text t ]
    in
        div
            [ class "col-sm-12"
            , style [ prop "text-align" "center" ]
            ]
            [ div
                []
                <| map (uncurry actionButton)
                <| [ (Create Product.wood, "Cut Wood")
                   , (Create Product.metal, "Mine Metal")
                   , (Create Product.oil, "Pump Oil")
                   ]
            , div
                []
                <| map (uncurry actionButton)
                <| [ (Create Product.woodenToy, "Produce Wooden Toy")
                   , (Create Product.wrappingPaper, "Produce Wrapping Paper")
                   , (Wrap Product.woodenToy, "Wrap Wooden Toy")
                   , (Deliver, "Deliver")
                   ]
            ]

displayNavigation : State -> Html
displayNavigation state =
    let displayTab x =
            let navigationClass =
                if | x == state.selectedTab -> "active"
                   | otherwise -> ""
            in
                li
                    [ class navigationClass ]
                    [ a
                        [ href "#"
                        , onclick actionInput.handle (always (SelectTab x))
                        ]
                        [ text <| show x ]
                    ]
        tabs = map displayTab [ State.Workshop, State.Research, State.Stats, State.Achievements ]
    in 
        nav
            [ class "navbar navbar-default"
            , attr "role" "navigation"
            ]
            [ ul
                [ class "nav navbar-nav" ]
                tabs
            ]

displayUnlockables : [ Unlockable ] -> Html
displayUnlockables unlockables =
    let check x =
            if | any (\y -> y.name == x.name) unlockables ->
                [ dt [ class "unlocked" ] [ text x.name ], dd [] [ text x.description ] ]
               | otherwise ->
                [ dt [ class "locked" ] [ text x.name ], dd [] [ text "LOCKED" ] ]
    in
        div
            [ class "panel-body" ]
            [ dl [ class "achievements" ] <| concat <| map check unlockables ]

displayAchievements : [ State.Achievement ] -> Html
displayAchievements achievements =
    let icon = img [ src "https://cdn2.iconfinder.com/data/icons/medals/500/Award_medal_achievement_acknowledgement-512.png" ] []
        check x =
            if | any (\y -> y.name == x.name) achievements ->
                [ dt [ class "unlocked" ] [ text x.name, icon ]
                , dd [] [ text x.description ]
                ]
               | otherwise ->
                [ dt [ class "locked" ] [ text x.name, icon ]
                , dd [] [ text "LOCKED" ]
                ]
    in
        div
            [ class "panel-body" ]
            [ dl [ class "achievements" ] <| concat <| map check State.achievements ]

displayStats : State -> Html
displayStats state =
    let stats =
            [ ("Test", "This is a test") ]
        format (x, y) = [ dt [] [ text x ], dd [] [ text y ] ]
    in
        div
            [ class "panel-body" ]
            [ dl [ class "stats" ] <| concat <| map format stats ]

displaySelectedTab : State -> Html
displaySelectedTab state =
    case state.selectedTab of
        State.Workshop -> displayPurchasableProducers state.purchaseMultiplier state.producers state.products state.unlockables
        State.Research -> Ref.lazy displayUnlockables state.unlockables
        State.Stats -> Ref.lazy displayStats state
        State.Achievements -> Ref.lazy displayAchievements state.achievements
        _ -> text ""

display : State -> Html
display state =
    body
        []
        [ div
            [ class "page-header" ]
            [ displayTitle ]
        , div
            [ class "container-fluid" ]
            [ div
                []
                [ div
                    [ class "row"]
                    [ div
                        [ class "col-sm-12" ]
                        [ Ref.lazy2 displayDeliveries state.deliveries state.dps ]
                    ]
                , div
                    [ class "row"]
                    [ div
                        [ class "col-sm-12" ]
                        [ displayTestButtons ]
                    ]
                , div
                    [ id "main"
                    , class "row"
                    ]
                    [ div
                        [ class "col-sm-6" ]
                        [ displayNavigation state
                        , div
                            [ class "panel panel-default" ]
                            [ displaySelectedTab state ]
                        ]
                    , div
                        [ class "col-sm-6" ]
                        [ div
                            [ class "panel panel-default" ]
                            [ div [ class "panel-heading" ] [ text "Products" ]
                            , div [ class "panel-body" ] [ Ref.lazy displayProducts state.products ]
                            ]
                        ]
                    ]
                ]
            ]
        ]

-- UPDATE

data Action
    = NoOp
    | UpdateProduction Time
    | UpdateDeliveries Time
    | Create Product
    | Produce Product
    | Wrap Product
    | Deliver
    | Purchase (Purchasable Producer) BigNumber
    | SetPurchaseMultiplier BigNumber
    | SelectTab State.Tab
    | Anything (State -> State)

step : Action -> State -> State
step action state =
    let state' =
            case action of
                NoOp -> state
                UpdateProduction time -> State.updateProduction time state
                UpdateDeliveries time -> State.updateDeliveries time state
                Create x ->
                    let amount = round (Unlockable.clickPower state.unlockables)
                    in
                        { state | products <- Stackable.update x amount state.products }
                Produce x -> state
                Wrap x -> { state | products <- Product.wrap x 1 state.products }
                Deliver -> State.deliverWrapped 1 state
                Purchase producer n -> State.purchase producer n state
                SetPurchaseMultiplier x -> { state | purchaseMultiplier <- x }
                SelectTab x -> { state | selectedTab <- x }
                Anything apply -> apply state
        achievements = State.updateAchievements state'
        newAchievements =
            filter (\x -> all (\y -> y.name /= x.name) state.achievements) achievements
    in
        { state'
        | achievements <- achievements ++ state.achievements
        , notifications <- showAchievements newAchievements
        }

actionInput : Input.Input Action
actionInput = Input.input NoOp

setPurchaseMultiplierSignal : Signal Action
setPurchaseMultiplierSignal = 
    let selectMultiplier ctrlDown shiftDown =
            if | ctrlDown -> SetPurchaseMultiplier 100
               | shiftDown -> SetPurchaseMultiplier 10
               | otherwise -> SetPurchaseMultiplier 1
    in
        selectMultiplier <~ Keyboard.ctrl ~ Keyboard.shift

updateProductionSignal : Signal Action
updateProductionSignal = UpdateProduction <~ fps 1

updateDeliveriesSignal : Signal Action
updateDeliveriesSignal = UpdateDeliveries <~ (delay (500 * millisecond) <| fps 1)

state : Signal State
state =
    let actionSignals =
            [ actionInput.signal
            , updateProductionSignal
            , updateDeliveriesSignal
            , setPurchaseMultiplierSignal
            ]
    in
        foldp step State.startState <| merges actionSignals

showAchievements : [ State.Achievement ] -> [ String ]
showAchievements achievements =
    map (\x -> "<b>ACHIEVEMENT - " ++ x.name ++ "</b><br/>" ++ x.description) achievements

scene : State -> (Int, Int) -> Element
scene state (w, h) = container w h midTop (toElement 1000 h (display state))

main = scene <~ state ~ Window.dimensions

checkNotifications : State -> [ String ]
checkNotifications state = state.notifications

port showNotification : Signal [ String ]
port showNotification = dropRepeats <| checkNotifications <~ state