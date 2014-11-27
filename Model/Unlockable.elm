module Model.Unlockable where

import Common (..)
import Model.Stackable as Stackable
import Model.Stackable (Stackable)
import Model.Product as Product
import Model.Product (Product)
import Model.Producer as Producer
import Model.Producer (Producer, Purchasable)

data Bonus
    = ClickPower Float
    | TotalPower Float
    | ProducerPower Producer Float
    | Unlock (Purchasable Producer)

type Upgrade x = { x | bonus : Bonus }
type Unlockable = Named (Descriptive (Upgrade {}))

clickPower : [ Unlockable ] -> Float
clickPower unlockables =
    let findClickPower unlockable =
            case unlockable.bonus of
                ClickPower x -> x
                _ -> 0
    in
        foldr (*) 1 <| map findClickPower unlockables

