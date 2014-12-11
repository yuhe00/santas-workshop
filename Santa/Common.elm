module Santa.Common where

type alias BigNumber = Int

type alias Named x = { x | name : String }
type alias Descriptive x = { x | description : String }

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
