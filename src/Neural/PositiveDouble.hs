module Neural.PositiveDouble
    ( PositiveDouble
    , constructPositiveDouble
    , pMultiply
    , posToDouble
    , posOne
    ) where

import Import

import Neural.PositiveDouble.Internal

pMultiply :: PositiveDouble -> PositiveDouble -> Either String PositiveDouble
pMultiply x y = constructPositiveDouble $ posToDouble x * posToDouble y