module Santa.Controller.Persistence where

import List (..)
import Json.Encode
import Json.Decode
import Json.Decode (Decoder, (:=))

import Santa.Common (..)
import Santa.Model.Stackable (stack)
import Santa.Model.State as State
import Santa.Model.State (State, defaultStartState)
import Santa.Model.Product as Product
import Santa.Model.Product (Product)
import Santa.Model.Producer as Producer
import Santa.Model.Producer (Producer)
import Santa.Model.Unlockable as Unlockable
import Santa.Model.Unlockable (Unlockable)

decode : Decoder State
decode =
    let decodeProduct =
            Json.Decode.object2 (,)
                ("product" := Json.Decode.string)
                ("amount" := Json.Decode.int)
        decodeProducer =
            Json.Decode.object2 (,)
                ("producer" := Json.Decode.string)
                ("amount" := Json.Decode.int)
        decodeUnlockable =
            Json.Decode.object2 (,)
                ("unlockable" := Json.Decode.string)
                ("progressTimer" := Json.Decode.float)
        toProduct (name, n) =
            case find name Product.products of
                Just x -> Just <| stack n x
                Nothing -> Nothing
        toProducer (name, n) =
            case find name Producer.producers of
                Just x -> Just <| stack n { x - cost }
                Nothing -> Nothing
        toUnlockable (name, pt) =
            case find name Unlockable.unlockables of
                Just x -> Just ({ x - cost } |> \y -> { y | progressTimer <- pt })
                Nothing -> Nothing
        toAchievement name = find name State.achievements
        toSingleProduct name = find name Product.products
        decodeState deliveries dps timePlayed products producers unlockables achievements uniqueProductsProduced =
            { defaultStartState
            | deliveries <- deliveries
            , dps <- dps
            , timePlayed <- timePlayed
            , products <- filterMap toProduct products
            , producers <- filterMap toProducer producers
            , unlockables <- filterMap toUnlockable unlockables
            , achievements <- filterMap toAchievement achievements
            , uniqueProductsProduced <- filterMap toSingleProduct uniqueProductsProduced
            }
    in
        Json.Decode.object8
            decodeState
            ("deliveries" := Json.Decode.int)
            ("dps" := Json.Decode.int)
            ("timePlayed" := Json.Decode.float)
            ("products" := Json.Decode.list decodeProduct)
            ("producers" := Json.Decode.list decodeProducer)
            ("unlockables" := Json.Decode.list decodeUnlockable)
            ("achievements" := Json.Decode.list Json.Decode.string)
            ("uniqueProductsProduced" := Json.Decode.list Json.Decode.string)

encode : State -> String
encode state =
    let encodeProduct (x, n) =
            Json.Encode.object
                [ ("product", Json.Encode.string x.name)
                , ("amount", Json.Encode.int n)
                ]
        encodeProducer (x, n) =
            Json.Encode.object
                [ ("producer", Json.Encode.string x.name)
                , ("amount", Json.Encode.int n)
                ]
        encodeUnlockable x =
            Json.Encode.object
                [ ("unlockable", Json.Encode.string x.name)
                , ("progressTimer", Json.Encode.float x.progressTimer)
                ]
        encodeAchievement x = Json.Encode.string x.name
        value =
            Json.Encode.object
                [ ("deliveries", Json.Encode.int state.deliveries)
                , ("dps", Json.Encode.int state.dps)
                , ("timePlayed", Json.Encode.float state.timePlayed)
                , ("products", Json.Encode.list <| map encodeProduct state.products)
                , ("producers", Json.Encode.list <| map encodeProducer state.producers)
                , ("unlockables", Json.Encode.list <| map encodeUnlockable state.unlockables)
                , ("achievements", Json.Encode.list <| map encodeAchievement state.achievements)
                , ("uniqueProductsProduced", Json.Encode.list <| map (.name >> Json.Encode.string) state.uniqueProductsProduced)
                ]
    in
        Json.Encode.encode 0 value