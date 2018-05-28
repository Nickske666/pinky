{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE AllowAmbiguousTypes #-}

module Neural.Spec.CreateRandom
    ( createRandomSpec
    ) where

import Test.Hspec
import Test.Validity
import TestImport

import Neural
import Neural.Spec.Gen ()

import System.Random

import Data.Typeable

createRandomSpec ::
       forall a. (CreateRandom a, Validity a, Typeable a, Show a)
    => Spec
createRandomSpec =
    describe (unwords ["CreateRandom" ++ typeName]) $
    it (concat ["createRandom :: StdGen -> (", typeName, ", StdGen)"]) $
    forAllValid @StdGen $ \seed -> shouldBeValid $ createRandom @a seed
  where
    typeName = typeToName @a
