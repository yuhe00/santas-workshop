module Santa.View.Achievements where

import Signal
import String
import List (..)
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Html.Lazy as Ref

import Santa.Common (..)
import Santa.Model.State as State
import Santa.Model.State (State, Achievement)

display : List State.Achievement -> Html
display achievements =
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