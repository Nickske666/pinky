{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveGeneric #-}

module Pinky.HyperOpt.Train where

import Import

import Pinky.Core
import Pinky.Core.HyperParams.Internal
import Pinky.ParamOpt
import Pinky.ParamOpt.Train
import Pinky.Utils
import Pinky.Utils.PositiveDouble.Internal
import Pinky.Utils.PositiveInt.Internal

import Control.Monad.Random.Lazy
import Control.Monad.State.Lazy
import Control.Monad.Trans.Reader

import Data.Singletons.Prelude (Head, Last)

runHyperParam ::
       forall (layers :: [*]) shapes i o.
       ( i ~ Head shapes
       , o ~ Last shapes
       , SingI o
       , CreateRandom (Network layers shapes)
       )
    => HyperParams
    -> SearchInfo i o
    -> IO ClassificationAccuracy
runHyperParam hp (SearchInfo errorFunc epochs trainData valData) = do
    net <- createRandomM @IO @(Momentum (Network layers shapes))
    let Momentum trainedNet _ =
            flip runReader errorFunc $
            flip evalStateT hp $ trainNetwork net trainData epochs
    pure $ accuracy trainedNet valData

data UpdateHyperParams = UpdateHyperParams
    { paramExp :: Double -- ^ exponent for possible change in parameters
    , decayRateExp :: Double -- ^ exponent for possible change in decay rate
    , batchSizeFactor :: Natural -- ^ factor for possible change in batchSize
    } deriving (Show, Eq, Generic)

updateHyperParams ::
       PositiveDouble -> PositiveDouble -> PositiveInt -> UpdateHyperParams
updateHyperParams (PositiveDouble x) (PositiveDouble y) (PositiveInt z) =
    UpdateHyperParams x y z

eitherGenHP ::
       MonadRandom m
    => HyperParams
    -> UpdateHyperParams
    -> m (Either String HyperParams)
eitherGenHP hp@HyperParams {..} (UpdateHyperParams x y z) = do
    let rateLog = log $ posToDouble hyperRate
    rate <- exp <$> getRandomR (-x + rateLog, x + rateLog)
    let decayRateLog = log $ fracToDouble hyperDecayRate
    decayRate <- exp <$> getRandomR (decayRateLog - y, min (decayRateLog + y) 0)
    let momentumLog = log $ fracToDouble hyperMomentum
    momentum <- exp <$> getRandomR (momentumLog - x, min (momentumLog + x) 0)
    let regLog = log $ posToDouble hyperRegulator
    regulator <- exp <$> getRandomR (regLog - x, regLog + x)
    let bsN = posToNum hyperBatchSize
    let minBatchSize =
            if z >= bsN
                then 1
                else bsN - z
    batchSize <-
        naturalFromInteger <$>
        getRandomR (fromIntegral minBatchSize, fromIntegral $ bsN + z)
    pure $ hyperParamsFromBasics rate decayRate momentum regulator batchSize

genHP :: MonadRandom m => HyperParams -> UpdateHyperParams -> m HyperParams
genHP hp uhp = do
    result <- eitherGenHP hp uhp
    case result of
        Left _ -> genHP hp uhp
        Right r -> pure r

localSearchHyperOptIter ::
       forall (layers :: [*]) shapes i o.
       ( i ~ Head shapes
       , o ~ Last shapes
       , SingI o
       , CreateRandom (Network layers shapes)
       )
    => (HyperParams, ClassificationAccuracy)
    -> SearchInfo i o
    -> IO (HyperParams, ClassificationAccuracy)
localSearchHyperOptIter hp (SearchInfo errorfunc epochs trainSet valSet) =
    undefined

data SearchInfo (i :: Shape) (o :: Shape) = SearchInfo
    { rsErrorFunc :: ErrorFunc o
    , rsEpochs :: Natural
    , rsTrainSet :: DataSet i o
    , rsValSet :: DataSet i o
    } deriving (Generic)

data LocalSearchArgs (i :: Shape) (o :: Shape) = LocalSearchArgs
    { rsInfo :: SearchInfo i o
    , rsMinAcc :: ClassificationAccuracy -- ^ desired accuracy
    , rsaUhp :: UpdateHyperParams
    , rsaUhpDecay :: UpdateHyperParams
    } deriving (Generic)

localSearchHyperOpt ::
       forall (layers :: [*]) shapes i o.
       ( i ~ Head shapes
       , o ~ Last shapes
       , SingI o
       , CreateRandom (Network layers shapes)
       )
    => (HyperParams, ClassificationAccuracy)
    -> Natural -- ^ maximal number of hyperparameter sets tested
    -> LocalSearchArgs i o
    -> IO (HyperParams, ClassificationAccuracy)
localSearchHyperOpt init maxIter rsa@(LocalSearchArgs rsi@(SearchInfo errorFunc epochs trainSet valSet) minAcc uhp@(UpdateHyperParams x y z) uhpDecay@(UpdateHyperParams xDecay yDecay zDecay)) =
    ifThenElse (snd init > minAcc) (pure init) $
    case minusNaturalMaybe maxIter 1 of
        Nothing -> localSearchHyperOptIter @layers @shapes init rsi
        Just iterLeft -> do
            result <- localSearchHyperOptIter @layers @shapes init rsi
            if result == init
                then localSearchHyperOpt @layers @shapes init iterLeft rsa
                else localSearchHyperOpt @layers @shapes init iterLeft newRsa
  where
    uhpNew = UpdateHyperParams (x / xDecay) (y / yDecay) $ z `div` zDecay
    newRsa = rsa {rsaUhp = uhpNew}

ifThenElse :: Bool -> a -> a -> a
ifThenElse True a _ = a
ifThenElse False _ a = a
