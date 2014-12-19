module Santa.View.Product where

import Signal
import String
import List (..)
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Lazy as Ref

import Santa.Common (..)
import Santa.Model.Stackable as Stackable
import Santa.Model.Stackable (Stackable)
import Santa.Model.Product as Product
import Santa.Model.Product (Product)
import Santa.View.Stats as Stats
import Santa.View.Changelog as Changelog
import Santa.Controller.Controller (..)

displayList : List (Stackable Product) -> Html
displayList products =
    div [] [ ul [] <| map ((\(x, n) -> toString n ++ "x " ++ x.name) >> text >> (\x -> li [] [x])) products ]

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
                            [ displayList cost ]
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
                [ stringProperty "width" "30%" ]
                [ div
                    [ class "amount" ]
                    [ text <| toString count ]
                ]
            , td 
                [ class "text-left"
                , stringProperty "width" "50%"
                ]
                [ text p.name ]
            , td
                [ class "text-center"
                , stringProperty "width" "20%"
                ]
                [ button' ]
            ]

display : List (Stackable Product) -> Html
display products =
    table
        [ class "table table-condensed" ]
        [ tbody [] <| map displayProduct products ]

readyList : List (Stackable Product) -> Html
readyList products =
    let items = filter (\(x, _) -> x.wrapped) products
    in
        if | isEmpty items -> div [ class "panel-body" ] [ text "Nothing" ]
           | otherwise -> display items

unwrappedList : List (Stackable Product) -> Html
unwrappedList products =
    let items = filter (\(x, _) -> not x.wrapped && x.wrappable) products
    in
        if | isEmpty items -> div [ class "panel-body" ] [ text "Nothing" ]
           | otherwise -> display items

consumables : List (Stackable Product) -> Html
consumables products =
    let notBasic x = all (\p -> p.name /= x.name) Product.basics
        items = filter (\(x, _) -> not x.wrapped && not x.wrappable && notBasic x) products
    in
        if | isEmpty items -> div [ class "panel-body" ] [ text "Nothing" ]
           | otherwise -> display items