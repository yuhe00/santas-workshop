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

changelogs : List Changelog
changelogs =
    [ { version = (0, 1, 1)
      , changes =
            [ "Fixed some layout problems."
            , "Content update and rebalanced some numbers."
            , "Game state is now saved between sessions and can be reset."
            , "Refactored and structured code."
            ]
      }
    , { version = (0, 1, 0)
      , changes = [ "Initial release." ]
      }
    ]

versionString : (Int, Int, Int) -> String
versionString (a, b, c) = toString a ++ "." ++ toString b ++ "." ++ toString c 

displayVersion : Html
displayVersion =
    text <| "Version " ++ (versionString <| .version <| head changelogs)

display : Html
display =
    let displayOne changelog =
            div
                []
                [ u [] [ text <| versionString changelog.version ]
                , ul
                    []
                    <| map (\x -> li [] [ text x ] ) changelog.changes
                ]
    in
        div
            []
            <| map displayOne changelogs
