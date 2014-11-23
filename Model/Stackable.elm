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

{-
import String
import Char

type BigInt = [ Int ]

bigInt : Int -> BigInt
bigInt n = map toDigit <| String.toList <| show n

toDigit : Char -> Int
toDigit c = foldr1 (-) <| map Char.toCode [ c, '0' ]

toChar : Int -> Char
toChar i = Char.fromCode (i + (Char.toCode '0'))

add : BigInt -> BigInt -> BigInt
add i1 i2 =
    let comb n1 n2 r zs =
        case (n1, n2) of
            (x::xs, y::ys) -> comb xs ys ((x + y + r) // 10) (((x + y + r) % 10)::zs)
            (x::xs, []) -> comb xs [] ((x + r) // 10) (((x + r) % 10)::zs)
            ([], y::ys) -> comb [] ys ((y + r) // 10) (((y + r) % 10)::zs)
            _ -> if | r == 0 -> zs
                    | otherwise -> (r::zs)
    in
       comb (reverse i1) (reverse i2) 0 []

sub : BigInt -> BigInt -> BigInt
sub x y = x

mul : BigInt -> BigInt -> BigInt
mul x y = x

div : BigInt -> BigInt -> BigInt
div x y = x
-}
