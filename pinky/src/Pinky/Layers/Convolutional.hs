{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}

module Pinky.Layers.Convolutional
    ( Convolutional(..)
    ) where

import Import

import Pinky.Core
import Pinky.CreateRandom
import Pinky.Layers.Reshape
import Pinky.Utils

import Data.Massiv.Array (Array, Stencil, backpermute, compute, size)
import Data.Massiv.Array.Delayed (D)
import qualified Data.Massiv.Array.Manifest as Manifest
import Data.Massiv.Array.Stencil (Stencil, mapStencil)
import Data.Massiv.Core (Load, Mutable, Source)
import Data.Massiv.Core.Index (Ix2(..), IxN(..))

data Convolutional :: Nat -> Nat -> Nat -> Nat -> Nat -> Nat -> * where
    Convolutional
        :: ( KnownNat chanIn
           , KnownNat chanOut
           , KnownNat strideX
           , KnownNat strideY
           , KnownNat kernelX
           , KnownNat kernelY
           )
        => !(Stencil (IxN 3) Double Double)
        -> Convolutional chanIn chanOut kernelX kernelY strideX strideY

instance ( KnownNat c
         , KnownNat c'
         , KnownNat s
         , KnownNat s'
         , KnownNat k
         , KnownNat k'
         ) =>
         CreateRandom (Convolutional c c' s s' k k') where
    createRandom seed =
        let (kernel, seed') = undefined
         in (Convolutional kernel, seed')

instance ( KnownNat c
         , KnownNat c'
         , KnownNat s
         , KnownNat s'
         , KnownNat k
         , KnownNat k'
         ) =>
         UpdateLayer (Convolutional c c' s s' k k') where
    applyGradient (Momentum (Convolutional kernel) (Convolutional kernMom)) (Gradient (Convolutional kernGrad)) hp =
        let (Momentum kernel' kernMom') =
                applyMomentum hp (Gradient kernGrad) $ Momentum kernel kernMom
         in Momentum (Convolutional kernel') (Convolutional kernMom')

instance ( KnownNat c
         , KnownNat c'
         , KnownNat s
         , KnownNat s'
         , KnownNat k
         , KnownNat k'
         ) =>
         Validity (Convolutional c c' s s' k k') where
    validate (Convolutional kernel) = delve "kernel" kernel

instance ( KnownNat s
         , KnownNat s'
         , KnownNat k
         , KnownNat k'
         , x ~ (s * x' + s - k)
         , KnownNat x
         , KnownNat x'
         , y ~ (s' * y' + s' - k')
         , KnownNat y
         , KnownNat y'
         ) =>
         Layer (Convolutional 1 1 s s' k k') ('D2 x y) ('D2 x' y') where
    type Tape (Convolutional 1 1 s s' k k') ('D2 x y) ('D2 x' y') = S ('D2 x y)
    runForwards conv inpt =
        let (_, outpt' :: S ('D3 x' y' 1)) =
                runForwards conv (reshape inpt :: S ('D3 x y 1))
         in (inpt, reshape outpt')
    runBackwards conv tape dCdz =
        let (grad, inpt' :: S ('D3 x y 1)) =
                runBackwards
                    conv
                    (reshape tape :: S ('D3 x y 1))
                    (reshape dCdz :: S ('D3 x' y' 1))
         in (grad, reshape inpt')

instance ( KnownNat c
         , KnownNat c'
         , KnownNat s
         , KnownNat s'
         , KnownNat k
         , KnownNat k'
         , x ~ (s * x' + s - k)
         , KnownNat x
         , KnownNat x'
         , y ~ (s' * y' + s' - k')
         , KnownNat y
         , KnownNat y'
         , KnownNat (y * c)
         , KnownNat (y' * c')
         ) =>
         Layer (Convolutional c c' s s' k k') ('D3 x y c) ('D3 x' y' c') where
    type Tape (Convolutional c c' s s' k k') ('D3 x y c) ('D3 x' y' c') = S ('D3 x y c)
    runForwards (Convolutional kernel) inpt =
        let outpt =
                fromJust . massivToS3 . compute $
                resizeMassiv (natToInt @s) (natToInt @s') $
                (compute . mapStencil kernel $ s3ToMassiv inpt :: Array Manifest.S (IxN 3) Double)
         in (inpt, outpt)
    runBackwards = undefined

resizeMassiv ::
       Source r (IxN 3) Double
    => Int
    -> Int
    -> Array r (IxN 3) Double
    -> Array D (IxN 3) Double
resizeMassiv s s' arr = backpermute newSize indexMap arr
  where
    (x :> y :. z) = size arr
    newSize = (x + s - 1 `div` s) :> (y + s' - 1 `div` s) :. z
    indexMap (a :> b :. c) = (s * a) :> (s' * b) :. c
