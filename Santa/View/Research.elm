module Santa.View.Research where

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
import Santa.View.Product (costTooltip)
import Santa.View.Stats as Stats
import Santa.View.Changelog as Changelog
import Santa.Controller.Controller (..)

display : List (Purchasable Unlockable) -> List (Stackable Product) -> Html
display unlockables products =
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
        single x =
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
            [ tbody [] <| map single unlockables ]