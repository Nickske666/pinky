{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE AllowAmbiguousTypes #-}

module Pinky.Utils.Proxy where

import Import

import Data.Typeable

natToInt ::
       forall n. KnownNat n
    => Int
natToInt = fromInteger . natVal $ Proxy @n

typeToName ::
       forall a. Typeable a
    => String
typeToName = show . typeRep $ Proxy @a
