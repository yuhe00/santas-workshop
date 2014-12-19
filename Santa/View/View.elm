module Santa.View.View where

import Signal
import String
import List (..)
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Lazy as Ref

import Santa.Common (..)
import Santa.Model.State as State
import Santa.Model.State (State)
import Santa.Model.Unlockable as Unlockable
import Santa.Model.Unlockable (Unlockable)
import Santa.View.Product as Product
import Santa.View.Producer as Producer
import Santa.View.Research as Research
import Santa.View.Stats as Stats
import Santa.View.Achievements as Achievements
import Santa.View.Changelog as Changelog
import Santa.Controller.Controller (..)

logo : Html
logo =
    img
        [ src "files/logo.png"
        , class "center-block"
        ]
        []

deliveries : BigNumber -> BigNumber -> Html
deliveries amount dps =
    div
        [ class "container text-center" ]
        [ h1 [] [ text <| toString amount ]
        , p
            []
            [ text "DELIVERIES MADE"
            , text <| " (+"++ (toString <|dps) ++ "/s)"
            ]
        ]

tabNavigation : State -> Html
tabNavigation state =
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

selectedTabContent : State -> Html
selectedTabContent state =
    case state.selectedTab of
        State.Workshop -> Producer.display state.purchaseMultiplier state.producers state.products state.unlockables
        State.Research -> Ref.lazy2 Research.display ((Unlockable.availableUnlockables state.unlockables) ++ map (\x -> {x | cost = []}) state.unlockables) state.products
        State.Stats -> Ref.lazy Stats.display state
        State.Achievements -> Ref.lazy Achievements.display state.achievements
        _ -> text ""

display : State -> Html
display state =
    body
        []
        [ header
            [ id "header" ]
            [ logo ]
        , div
            [ class "jumbotron" ]
            [ Ref.lazy2 deliveries state.deliveries state.dps ]
        , div
            [ class "container" ]
            [ div
                []
                [ div
                    [ class "row"]
                    [ div
                        [ class "col-sm-12" ]
                        [ Ref.lazy Product.primaryResources state.products ]
                    ]
                , main'
                    [ id "main"
                    , class "row"
                    ]
                    [ div
                        [ class "col-sm-6" ]
                        [ tabNavigation state
                        , div
                            [ class "panel panel-default" ]
                            [ selectedTabContent state ]
                        ]
                    , div
                        [ class "col-sm-6" ]
                        [ div
                            [ class "panel panel-default" ]
                            [ div [ class "panel-heading" ] [ text "Ready For Delivery" ]
                            , Ref.lazy Product.readyList state.products
                            ]
                        , div
                            [ class "panel panel-default" ]
                            [ div [ class "panel-heading" ] [ text "Ready For Wrapping" ]
                            , Ref.lazy Product.unwrappedList state.products
                            ]
                        , div
                            [ class "panel panel-default" ]
                            [ div [ class "panel-heading" ] [ text "Raw Products" ]
                            , Ref.lazy Product.consumables state.products
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