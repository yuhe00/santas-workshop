module Santa.View.Changelog where

import List (..)
import String
import Html (..)
import Html.Attributes (..)
import Html.Events (..)
import Time (..)

type alias Version = (Int, Int, Int)

type alias Changelog =
    { version : (Int, Int, Int)
    , changes : List String
    }

versionString : (Int, Int, Int) -> String
versionString (a, b, c) = toString a ++ "." ++ toString b ++ "." ++ toString c 

display : List Changelog -> Html
display changelogs =
    let displayOne changelog =
            div
                []
                [ u [] [ versionString changelog.version ]
                , ul
                    []
                    <| map (\x -> li [] [ text x ] ) changelog.changes
                ]
    in
        div
            []
            <| map displayOne changelogs
