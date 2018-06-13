module Pinky.Core.LinearAlgebra
    ( V
    , konstV
    , M
    , diag
    , (<#>)
    , (<#.>)
    , (<+>)
    , (<->)
    , Prod
    , Min
    , Plus
    , ElemProd
    , outerProd
    , transpose
    , vToM
    , mToV
    , mapV
    , mapMatrix
    , maxIndex
    , intToV
    , listToV
    , listToM
    , unsafeListToM
    , toDoubleList
    , unsafeFromDoubleList
    , unsafeFromTrippleList
    , resizeV
    , resizeM
    ) where

import Pinky.Core.LinearAlgebra.Internal
