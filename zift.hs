#!/usr/bin/env stack
{- stack
    --install-ghc
    runghc
    --nix
    --package zifter
    --package zifter-git
    --package zifter-hindent
    --package zifter-hlint
-}
import Zifter
import Zifter.Git
import Zifter.Hindent
import Zifter.Hlint

main :: IO ()
main =
    ziftWith $ do
        preprocessor hindentZift
        prechecker gitAddAllZift
        checker hlintZift
