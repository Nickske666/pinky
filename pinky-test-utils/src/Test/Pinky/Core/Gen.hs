{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}

module Test.Pinky.Core.Gen where

import Import
import Test.Pinky.Core.LinearAlgebraGen ()
import Test.Pinky.Utils.Gen ()
import Test.QuickCheck

import Pinky
import Pinky.Core.HyperParams.Internal
import Pinky.Utils.PositiveDouble.Internal

instance GenUnchecked HyperParams

instance GenValid HyperParams where
    genValid = gen `suchThat` isValid
      where
        gen = do
            rate <- genValid
            dr <- genValid
            mom <- genValid
            reg <- PositiveDouble <$> choose (0, posToDouble rate)
            HyperParams rate dr mom reg <$> genValid

instance SingI x => GenUnchecked (S x) where
    genUnchecked =
        case sing :: Sing x of
            D1Sing SNat -> S1D <$> genUnchecked
            D2Sing SNat SNat -> S2D <$> genUnchecked
            D3Sing SNat SNat SNat -> S3D <$> genUnchecked
    shrinkUnchecked = const []

instance SingI x => GenValid (S x) where
    genValid =
        case sing :: Sing x of
            D1Sing SNat -> S1D <$> genValid
            D2Sing SNat SNat -> S2D <$> genValid
            D3Sing SNat SNat SNat -> S3D <$> genValid

instance SingI i => GenUnchecked (Network '[] '[ i]) where
    genUnchecked = pure EmptyNet
    shrinkUnchecked = const []

instance ( GenUnchecked x
         , SingI i
         , SingI m
         , Layer x i m
         , GenUnchecked (Network xs (m ': ss))
         ) =>
         GenUnchecked (Network (x ': xs) (i ': (m ': ss))) where
    genUnchecked = AppendNet <$> genUnchecked <*> genUnchecked
    shrinkUnchecked = const []

instance SingI i => GenValid (Network '[] '[ i]) where
    genValid = pure EmptyNet

instance ( GenValid x
         , SingI i
         , SingI m
         , Layer x i m
         , GenValid (Network xs (m ': ss))
         ) =>
         GenValid (Network (x ': xs) (i ': (m ': ss))) where
    genValid = AppendNet <$> genValid <*> genValid

instance SingI i => GenUnchecked (Tapes '[] '[ i]) where
    genUnchecked = pure EmptyTape
    shrinkUnchecked = const []

instance ( GenUnchecked (Tape x i m)
         , SingI i
         , SingI m
         , Layer x i m
         , GenUnchecked (Tapes xs (m ': ss))
         ) =>
         GenUnchecked (Tapes (x ': xs) (i ': (m ': ss))) where
    genUnchecked = AppendTape <$> genUnchecked <*> genUnchecked
    shrinkUnchecked = const []

instance SingI i => GenValid (Tapes '[] '[ i]) where
    genValid = pure EmptyTape

instance ( GenValid (Tape x i m)
         , SingI i
         , SingI m
         , Layer x i m
         , GenValid (Tapes xs (m ': ss))
         ) =>
         GenValid (Tapes (x ': xs) (i ': (m ': ss))) where
    genValid = AppendTape <$> genValid <*> genValid

instance GenUnchecked x => GenUnchecked (Momentum x) where
    genUnchecked = Momentum <$> genUnchecked <*> genUnchecked

instance GenValid x => GenValid (Momentum x) where
    genValid = Momentum <$> genValid <*> genValid

instance GenUnchecked (ErrorFunc o) where
    genUnchecked = pure SumSquareError
    shrinkUnchecked = const []

instance GenValid (ErrorFunc o)
