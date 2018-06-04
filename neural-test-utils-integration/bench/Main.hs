{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators #-}

module Main
    ( main
    ) where

import Criterion.Main

import NN.Network
import Neural

import Data.GenValidity

import Test.Neural.Layers.Gen ()
import Test.QuickCheck (generate)

import GHC.Natural
import GHC.TypeLits

import MNIST.Load

import Control.Monad.State.Lazy

type Xdim = 28

type Ydim = 28

type ImageShape = 'D2 Xdim Ydim

type Image = S ImageShape

type I = Xdim * Ydim

type IShape = 'D1 I

type H = 30

type HShape = 'D1 H

type O = 10

type OShape = 'D1 O

type FCL = FullyConnected I O

type NNet
     = Network '[ Reshape, FullyConnected I H, Sigmoid, FullyConnected H O, Sigmoid] '[ ImageShape, IShape, HShape, HShape, OShape, OShape]

type NNetData = DataSet ImageShape OShape

main :: IO ()
main =
    defaultMain
        -- bench "Generate fully connected layer" $ eval genFCL
        --,
        [ bench "Generate input" $ eval genInputShape
        , bench "Generate input and runForwards on NNet" $
          eval genAndRunForwards
        , bench "Train NNet on MNIST" $ eval trainNNet
        ]

eval :: IO a -> Benchmarkable
eval action =
    nfIO $ do
        result <- action
        seq result $ pure ()

genAndRunForwards :: IO (S OShape)
genAndRunForwards = do
    inpt <- genInputShape
    net <- createRandomM @IO @NNet
    pure . snd $ runForwards net inpt

genFCL :: IO FCL
genFCL = createRandomM @IO @FCL

genInputShape :: IO (S ImageShape)
genInputShape = generate genValid

nOfTrain, nOfVal, nOfTest :: Int
nOfTrain = 1000

nOfVal = 100

nOfTest = 100

epochs :: Natural
epochs = 2

trainNNet :: IO NNet
trainNNet = do
    net <- createRandomM @IO @NNet
    (trainSet, _, _) <- load nOfTrain nOfVal nOfTest
    pure $ evalState (trainNetwork net trainSet epochs) params
