{-# LANGUAGE TypeApplications #-}

module Test.Pinky.ParamOpt.ParamOptSpec
    ( spec
    ) where

import Test.Hspec
import Test.Validity
import TestImport

import Pinky

import Test.Pinky.Layers.Gen ()

import Control.Monad.State.Lazy
import Control.Monad.Trans.Reader

spec :: Spec
spec = do
    describe
        "applyGradientToNetwork :: Momentum NNet -> Grad (NNet) -> HyperParams -> Momentum NNet" $
        it "produces valids on valids" $
        forAllValid @(Momentum NNet) $ \momNet ->
            forAllValid $ \grad ->
                forAllValid $ \hp ->
                    shouldBeValid $ applyGradientToNetwork momNet grad hp
    describe
        "getGradientOfNetwork :: Momentum NNet -> S i -> S o -> Gradient (NNet)" $
        it "produces valids on valids" $
        forAllValid @NNet $ \net ->
            forAllValid $ \inpt ->
                forAllValid $ \label ->
                    shouldBeValid $
                    flip runReader SumSquareError $
                    getGradientOfNetwork net inpt label
    describe
        "runIteration :: Momentum NNet -> DataSet -> State HyperParams NNet" $
        it "produces valids on valids" $
        forAllValid @(Momentum NNet) $ \momNet ->
            forAllValid $ \dataset ->
                forAllValid $ \hp ->
                    shouldBeValid $
                    flip runReader SumSquareError $
                    flip evalStateT hp $ runIteration momNet dataset
    describe
        "trainNetwork :: Momentum NNet -> DataSet -> Natural -> State HyperParams (Momentum NNet)" $
        it "produces valids on valids" $
        forAllValid @(Momentum NNet) $ \momNet ->
            forAllValid $ \dataset ->
                forAllValid $ \epochs ->
                    forAllValid $ \hp ->
                        shouldBeValid $
                        flip runReader SumSquareError $
                        flip evalStateT hp $ trainNetwork momNet dataset epochs
    describe "accuracy :: NNet -> DataSet -> ClassificationAccuracy" $
        it "produces valids on valids" $
        forAllValid @NNet $ \net ->
            forAllValid $ \dataset -> shouldBeValid $ accuracy net dataset
