{-# OPTIONS_GHC -Wno-orphans #-}

module Test.Pinky.ParamOpt.Gen where

import Import
import Test.Pinky.Core.Gen ()

import Pinky

instance GenUnchecked ClassificationAccuracy

instance GenValid ClassificationAccuracy
