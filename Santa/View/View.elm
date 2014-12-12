module Santa.View.View where

import Signal
import String
import List (..)
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Lazy as Ref

import Santa.Common (..)
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
import Santa.View.Stats as Stats
import Santa.View.Changelog as Changelog
import Santa.Controller.Controller (..)

-- VIEW

displayTitle : Html
displayTitle =
    img
        [ src "files/logo.png"
        , class "center-block"
        ]
        []
    --h1
    --    [ style [ property "text-align" "center" ] ]
    --    [ text "Santa's Workshop" ]

displayDeliveries : BigNumber -> BigNumber -> Html
displayDeliveries deliveries dps =
    div
        [ class "container text-center" ]
        [ h1 [] [ text <| toString deliveries ]
        , p
            []
            [ text "DELIVERIES MADE"
            , text <| " (+"++ (toString <|dps) ++ "/s)"
            ]
        ]

displayProducts : List (Stackable Product) -> Html
displayProducts products =
    div [] [ ul [] <| map ((\(x, n) -> toString n ++ "x " ++ x.name) >> text >> (\x -> li [] [x])) products ]

displayProductList : List (Stackable Product) -> Html
displayProductList products =
    table
        [ class "table table-condensed" ]
        [ tbody [] <| map displayProduct products ]

displayProduct : Stackable Product -> Html
displayProduct product =
    let (p, count) = product
        action =
            if | p == Product.wrapped -> Just (Deliver, "Deliver")
               | otherwise ->
                    if | p.wrappable -> Just (Wrap p, "Wrap")
                       | otherwise -> Nothing
        button' =
            case action of
                Just (action', label) ->
                    button
                        [ class "btn btn-default"
                        , style [ ("width", "10em") ]
                        , onClick (Signal.send actionChannel action')
                        ]
                        [ text label ]
                _ -> text " "
    in
        tr
            []
            [ td
                []
                [ div
                    [ class "amount" ]
                    [ text <| toString count ]
                ]
            , td 
                [ class "text-left"
                , stringProperty "width" "80%"
                ]
                [ text p.name ]
            , td
                [ class "text-center"
                , stringProperty "width" "20%"
                ]
                [ button' ]
            ]

displayProducerFunction : Producer.Function -> Html
displayProducerFunction function =
    case function of
        Producer.Creator ps ->
            div
                []
                [ em [] [ text "Gathers (per second):" ]
                , div
                    [ class "tooltipFunction" ]
                    [ displayProducts ps ]
                ]
        Producer.Transformer cs ps ->
            div
                []
                [ em [] [ text "Produces (per second):" ]
                , div
                    []
                    <| map (\x -> span [ class "tooltipFunctionTransformer" ] [ x ])
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
                    [ class "tooltipFunction" ]
                    [ text <| (toString n) ++ " packages per second" ]
                ]

displayPurchasableProducers : BigNumber -> List (Stackable Producer) -> List (Stackable Product) -> List (Unlockable) -> Html
displayPurchasableProducers purchaseMultiplier producers products unlockables =
    let ps = State.producers unlockables
        items = map (\x -> displayPurchasableProducer purchaseMultiplier x producers products) ps
    in
        if isEmpty ps
            then
                div
                    [ class "panel-body" ]
                    [ p [] [ text "Research to unlock more workshop items!" ] ]
            else
                table
                    [ id "purchasableProducers"
                    , class "table table-condensed" ]
                    [ tbody
                        []
                        items
                    ]

displayPurchasableProducer : BigNumber -> Purchasable Producer -> List (Stackable Producer) -> List (Stackable Product) -> Html
displayPurchasableProducer purchaseMultiplier purchasableProducer producers products =
    let producer = { purchasableProducer - cost }
        cost = Producer.cost purchasableProducer (Stackable.count producer producers) purchaseMultiplier
        canAfford = Purchasable.canAfford cost products
        costColor =
            if | canAfford -> "#fff"
               | otherwise -> "#f00"
        purchaseAction = Purchase purchasableProducer purchaseMultiplier
        purchaseAmountText =
            if | purchaseMultiplier == 1 -> ""
               | otherwise -> " " ++ toString purchaseMultiplier ++ "x"
        amount = (toString <| Stackable.count producer producers) ++ ""
    in
        tr
            [ class "purchasable" ]
            [ td
                []
                [ div
                    [ class "amount" ]
                    [ text amount ]
                ]
            , td
                []
                [ div
                    [ class "tooltip-wrapper" ]
                    [ span
                        [ class "trigger" ]
                        [ text producer.name ]
                    , div
                        [ class "tooltip" ]
                        [ div
                            []
                            <| map displayProducerFunction producer.function
                        ]
                    ]
                ]
            , td
                [ class "text-center" ]
                [ div
                    [ class "tooltip-wrapper" ]
                    [ button
                        [ class "btn btn-default trigger"
                        , disabled <| not canAfford
                        , style [ ("width", "10em") ]
                        , onClick (Signal.send actionChannel purchaseAction)
                        ]
                        [ text <| "Purchase" ++ purchaseAmountText ]
                    , div
                        []
                        [ div
                            [ class "tooltip text-left" ]
                            [ div
                                [ style
                                    [ ("color", costColor)
                                    , ("width", "auto")
                                    ]
                                ]
                                [ em [] [ text "Cost:" ]
                                , div
                                    [ style [ ("padding","0.5em") ] ]
                                    [ displayProducts cost ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]

primaryResources : List (Stackable Product) -> Html
primaryResources products =
    let actionButton p t =
            let amount = toString <| Stackable.count p products
            in
                div
                    [ class "col-centered text-center primaryResources" ]
                    [ div
                        []
                        [ a
                            [ href "#"
                            , class "hovertext"
                            , title amount
                            ]
                            [ img
                                [ src <| "files/" ++ String.toLower p.name ++ ".png" ]
                                []
                            ]
                        ]
                    , div
                        []
                        [ button
                            [ class "btn btn-default"
                            , onClick (Signal.send actionChannel (Create p))
                            ]
                            [ text t ]
                        ]
                    ]
    in
        div
            [ class "row row-centered" ]
            <| map (uncurry actionButton)
                <| [ (Product.wood, "Cut Wood")
                   , (Product.metal, "Mine Metal")
                   , (Product.oil, "Pump Oil")
                   ]


displayTestButtons : List (Stackable Product) -> Html
displayTestButtons products =
    let actionButtonNoImage action t =
            div
                [ class "col-centered" ]
                [ button
                    [ class "btn btn-default"
                    , onClick (Signal.send actionChannel action)
                    ]
                    [ text t ]
                ]
    in
        div
            [ class "col-sm-12" ]
            [ primaryResources products
            , div
                [ class "row row-centered" ]
                <| map (uncurry actionButtonNoImage)
                <| [ (Create Product.woodenToy, "Produce Wooden Toy")
                   , (Create Product.wrappingPaper, "Produce Wrapping Paper")
                   ]
            ]

displayNavigation : State -> Html
displayNavigation state =
    let displayTab x =
            let navigationClass =
                    if | x == state.selectedTab -> "active"
                       | otherwise -> ""
                icon =
                    case x of
                        State.Workshop -> "cog"
                        State.Research -> "book"
                        State.Stats -> "stats"
                        State.Achievements -> "star"
                        _ -> "align-left"
            in
                li
                    [ class navigationClass ]
                    [ a
                        [ href "#"
                        , onClick (Signal.send actionChannel (SelectTab x))
                        ]
                        [ span
                            [ class <| "glyphicon glyphicon-" ++ icon
                            , stringProperty "aria-hidden" "true"
                            , style [ ("padding-right", "0.5em") ]
                            ] []
                        , text <| toString x
                        ]
                    ]
    in 
        nav
            [ class "navbar navbar-default"
            , stringProperty "role" "navigation"
            ]
            [ ul
                [ class "nav navbar-nav" ]
                <| map displayTab
                    [ State.Workshop
                    , State.Research
                    , State.Stats
                    , State.Achievements
                    ]
            ]

costTooltip : List (Stackable Product) -> Bool -> Html
costTooltip cost canAfford =
    let costColor =
            if | canAfford -> "#fff"
               | otherwise -> "#f00"
    in
        if | isEmpty cost -> text ""
           | otherwise ->
                div
                    [ class "tooltip text-left" ]
                    [ div
                        [ style
                            [ ("color", costColor)
                            , ("width", "auto")
                            ]
                        ]
                        [ em [] [ text "Cost:" ]
                        , div
                            [ style [ ("padding", "0.5em") ] ]
                            [ displayProducts cost ]
                        ]
                    ]

displayUnlockables : List (Purchasable Unlockable) -> List (Stackable Product) -> Html
displayUnlockables unlockables products =
    let progressBar pct =
            let (label, success) = 
                if | pct == 1.0 -> ("COMPLETED", " progress-bar-success")
                   | otherwise -> ((toString <| round <| pct * 100) ++ "%", "")
            in
                div
                    [ class "progress" ]
                    [ span
                        [ class <| "progress-bar" ++ success
                        , stringProperty "role" "progressbar"
                        , stringProperty "aria-valuenow" <| toString <| pct * 100 
                        , stringProperty "aria-valuemin" "0"
                        , stringProperty "aria-valuemax" "100"
                        , style [ ("width", (toString <| pct * 100) ++ "%") ]
                        ]
                        [ text label ]
                    ]
        display x =
            let canAfford = Purchasable.canAfford x.cost products
            in
                tr
                    []
                    [ td
                        [ class "text-center"
                        , stringProperty "width" "20%"
                        ]
                        [ div
                            [ class "tooltip-wrapper" ]
                            [ span
                                [ class "trigger" ]
                                [ text x.name ]
                            , div
                                [ class "tooltip" ]
                                [ div
                                    []
                                    <| intersperse (br [] [])
                                    <| map text <| Unlockable.description x.bonus
                                ]
                            ]
                        ]
                    , td
                        [ stringProperty "width" "60%" ] 
                        [ progressBar <| 1 - (x.progressTimer / x.progressMax) ]
                    , td
                        [ stringProperty "width" "20%" ]
                        [ div
                            [ class "tooltip-wrapper" ]
                            [ button
                                [ class "btn btn-default trigger"
                                , disabled <| x.progressTimer < x.progressMax || not canAfford
                                , onClick (Signal.send actionChannel (Research x))
                                ]
                                [ text "Research" ]
                            , costTooltip x.cost canAfford
                            ]
                        ]
                    ]
    in
        table
            [ class "table" ]
            [ tbody [] <| map display unlockables ]

displayAchievements : List (State.Achievement) -> Html
displayAchievements achievements =
    let check x =
            if | any (\y -> y.name == x.name) achievements ->
                [ div
                    [ class "list-group-item active" ]
                    [ h4 [ class "list-group-item-heading" ] [ text x.name ]
                    , text x.description
                    ]
                ]
               | otherwise ->
                [ div
                    [ class "list-group-item" ]
                    [ h4 [ class "list-group-item-heading" ] [ text x.name ]
                    , text "LOCKED"
                    ]
                ]
    in
        div
            [ class "list-group" ]
            <| concat <| map check State.achievements

displaySelectedTab : State -> Html
displaySelectedTab state =
    case state.selectedTab of
        State.Workshop -> displayPurchasableProducers state.purchaseMultiplier state.producers state.products state.unlockables
        State.Research -> Ref.lazy2 displayUnlockables ((Unlockable.availableUnlockables state.unlockables) ++ map (\x -> {x | cost = []}) state.unlockables) state.products
        State.Stats -> Ref.lazy Stats.display state
        State.Achievements -> Ref.lazy displayAchievements state.achievements
        _ -> text ""

displayReadyList : List (Stackable Product) -> Html
displayReadyList products =
    let items = filter (\(x, _) -> x.wrapped) products
    in
        if | isEmpty items -> div [ class "panel-body" ] [ text "Nothing" ]
           | otherwise -> displayProductList items

displayUnwrappedList : List (Stackable Product) -> Html
displayUnwrappedList products =
    let items = filter (\(x, _) -> not x.wrapped && x.wrappable) products
    in
        if | isEmpty items -> div [ class "panel-body" ] [ text "Nothing" ]
           | otherwise -> displayProductList items

displayConsumables : List (Stackable Product) -> Html
displayConsumables products =
    let notBasic x = all (\p -> p.name /= x.name) Product.basics
        items = filter (\(x, _) -> not x.wrapped && not x.wrappable && notBasic x) products
    in
        if | isEmpty items -> div [ class "panel-body" ] [ text "Nothing" ]
           | otherwise -> displayProductList items

display : State -> Html
display state =
    body
        []
        [ header
            [ id "header" ]
            [ displayTitle ]
        , div
            [ class "jumbotron" ]
            [ Ref.lazy2 displayDeliveries state.deliveries state.dps ]
        , div
            [ class "container" ]
            [ div
                []
                [ div
                    [ class "row"]
                    [ div
                        [ class "col-sm-12" ]
                        [ Ref.lazy primaryResources state.products ]
                    ]
                , main'
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
                            [ div [ class "panel-heading" ] [ text "Ready For Delivery" ]
                            , Ref.lazy displayReadyList state.products
                            ]
                        , div
                            [ class "panel panel-default" ]
                            [ div [ class "panel-heading" ] [ text "Ready For Wrapping" ]
                            , Ref.lazy displayUnwrappedList state.products
                            ]
                        , div
                            [ class "panel panel-default" ]
                            [ div [ class "panel-heading" ] [ text "Raw Products" ]
                            , Ref.lazy displayConsumables state.products
                            ]
                        ]
                    ]
                , footer
                    [ class "row" ]
                    [ div
                        [ class "col-sm-6 text-left" ]
                        [ text "Copyright © 2014 Yu He"
                        , text " | "
                        , a [ href "http://www.inconspicuous.no" ] [ text "http://www.inconspicuous.no" ]
                        ]
                    , div
                        [ class "col-sm-6 text-right" ]
                        [ Changelog.displayVersion
                        , text " | "
                        , a [ href "https://github.com/yuhe00/santas-workshop" ] [ text "Source @ GitHub" ]
                        , text " | "
                        , text "Powered by "
                        , a [ href "http://www.elm-lang.org/" ] [ text "Elm" ]
                        , text ", "
                        , a [ href "http://getbootstrap.com/" ] [ text "Bootstrap" ]
                        ]
                    ]
                ]
            ]
        ]