{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Test.Pinky.Spec.Layer
    ( layerSpec
    ) where

import Import
import Test.Hspec
import Test.Pinky.Layers.Gen ()
import Test.Pinky.Spec.Gen ()
import Test.Validity

import Pinky

import System.Random

layerSpec ::
       forall x (i :: Shape) (o :: Shape).
       ( Layer x i o
       , SingI i
       , SingI o
       , GenValid x
       , GenValid (Tape x i o)
       , Show x
       , Show (Tape x i o)
       , Validity (Tape x i o)
       , Typeable x
       , Typeable (Gradient x)
       , Typeable i
       , Typeable o
       )
    => Spec
layerSpec =
    describe layerName $ do
        genValidSpec @x
        genValidSpec @(Gradient x)
        describe ("createRandom :: MonadRandom m => m " ++ withBrackets xName) $
            it (concat ["creates valid \'", xName, "\'s"]) $
            forAllValid @StdGen $ \seed -> shouldBeValid $ createRandom @x seed
        describe
            (unwords
                 [ "runForwards ::"
                 , xName
                 , "->"
                 , iShapeName
                 , "->"
                 , '(' : tapeName ++ ","
                 , oShapeName ++ ")"
                 ]) $
            it "creates valids on valids" $
            forAllValid @(S i) $ \inpt ->
                forAllValid @x $ \layer ->
                    shouldBeValid (runForwards layer inpt :: (Tape x i o, S o))
        describe
            (unwords
                 [ "runBackwards ::"
                 , xName
                 , "->"
                 , tapeName
                 , "->"
                 , oShapeName
                 , "->"
                 , '(' : gradName ++ ","
                 , iShapeName ++ ")"
                 ]) $
            it "creates valids on valids" $
            forAllValid $ \(tape :: Tape x i o) ->
                forAllValid $ \(net :: x) ->
                    forAllValid $ \(outpt :: S o) ->
                        shouldBeValid
                            (runBackwards net tape outpt :: (Gradient x, S i))
        describe
            (unwords
                 [ "applyGradient :: HyperParams ->"
                 , xName
                 , "->"
                 , gradName
                 , "->"
                 , xName
                 ]) $
            it "creates valids on valids" $
            forAllValid $ \(hp :: HyperParams) ->
                forAllValid $ \(mom :: Momentum x) ->
                    forAllValid $ \(grad :: Gradient x) ->
                        shouldBeValid $ applyGradient mom grad hp
  where
    xName = typeToName @x
    iName = show . typeRep $ Proxy @i
    oName = show . typeRep $ Proxy @o
    withBrackets name =
        case words name of
            [_] -> name
            _ -> '(' : name ++ ")"
    toShapeName name = "S " ++ withBrackets name
    iShapeName = toShapeName iName
    oShapeName = toShapeName oName
    layerName =
        unwords
            [ "Layer"
            , withBrackets xName
            , withBrackets iName
            , withBrackets oName
            ]
    tapeName = unwords ["Tape", xName, iName, oName]
    gradName = unwords ["Gradient", withBrackets xName]
