module Model.Stackable where

import Common (..)

type Stackable a = (a, BigNumber)

stack : BigNumber -> a -> Stackable a
stack amount n = (n, amount)

count : a -> [ Stackable a ] -> BigNumber
count n ns =
    case filter (\x -> fst x == n) ns of
        found::[] -> snd found
        [] -> 0

update : a -> BigNumber -> [ Stackable a ] -> [ Stackable a ]
update s delta products =
    let update ( x, oldAmount ) = if | x == s -> (x, oldAmount + delta)
                                     | otherwise -> (x, oldAmount)
        updated = filter (\(_, n) -> n > 0) <| map update products
    in
        if | updated == products && delta > 0 -> (s, delta) :: products
           | otherwise -> updated

combine : [ Stackable a ] -> [ Stackable a ] -> [ Stackable a ]
combine x y = foldr (uncurry update) x y