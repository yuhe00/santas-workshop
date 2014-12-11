module Santa.View.Stats where

import List (..)
import String
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Time (..)

import Santa.Common (BigNumber)
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
import Santa.Controller.Controller (..)

formatTime : Time -> String
formatTime time =
    let h = floor <| inHours time
        m = floor <| inMinutes (time - (toFloat h) * hour)
        s = floor <| inSeconds (time - (toFloat h) * hour - (toFloat m) * minute)
    in 
        String.concat [ toString h, "h ", toString m, "m ", toString s, "s" ]

display : State -> Html
display state =
    let achievementsEarned =
            let ca = length state.achievements
                ta = length State.achievements
                pct = toString <| round (toFloat ca / toFloat ta * 100)
            in
                toString ca ++ "/" ++ toString ta ++ " (" ++ pct ++ "%)"
        stats =
            [ ("Time played", formatTime state.timePlayed)
            , ("Achievements earned", achievementsEarned)
            , ("Unique presents", toString <| length state.uniqueProductsProduced)
            , ("Click power", Unlockable.formatPct <| Unlockable.clickPower state.unlockables)
            , ("Spirit multiplier", Unlockable.formatPct <| Unlockable.spiritPower state.unlockables)
            , ("Research speed", Unlockable.formatPct <| Unlockable.researchPower state.unlockables)
            ]
        format (x, y) = [ dt [] [ text x ], dd [] [ text y ] ]
    in
        div
            [ class "panel-body" ]
            [ dl [ class "dl-horizontal" ] <| concatMap format stats ]