module Santa.View.Producer where

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
import Santa.View.Product (..)
import Santa.Controller.Controller (..)

displayProducerFunction : Producer.Function -> Html
displayProducerFunction function =
    case function of
        Producer.Creator ps ->
            div
                []
                [ em [] [ text "Gathers (per second):" ]
                , div
                    [ class "tooltipFunction" ]
                    [ displayList ps ]
                ]
        Producer.Transformer cs ps ->
            div
                []
                [ em [] [ text "Produces (per second):" ]
                , div
                    []
                    <| map (\x -> span [ class "tooltipFunctionTransformer" ] [ x ])
                        [ displayList cs
                        , text "➜"
                        , displayList ps
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

display' : BigNumber -> Purchasable Producer -> List (Stackable Producer) -> List (Stackable Product) -> Html
display' purchaseMultiplier purchasableProducer producers products =
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
                    , costTooltip cost canAfford
                    ]
                ]
            ]

display : BigNumber -> List (Stackable Producer) -> List (Stackable Product) -> List (Unlockable) -> Html
display purchaseMultiplier producers products unlockables =
    let ps = State.producers unlockables
        items = map (\x -> display' purchaseMultiplier x producers products) ps
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