---------------------------------------------------------------------------------
-- |
-- Utility functions for matrix operations
---------------------------------------------------------------------------------
module Utils where

import           Numeric.LinearAlgebra (Container, Element, Matrix, R, cmap,
                                        sumElements)
import           Prelude               (Num, Ord, (**), (.), (*), (-), abs, flip,
                                        max, signum)


frobeniusNorm :: Matrix R -> R
frobeniusNorm = flip (**) 0.5 . sumElements . cmap ((flip (**) 2) . abs)

absL1Norm :: Matrix R -> R
absL1Norm = sumElements . cmap abs

softThreshold
  :: (Ord e, Num e, Element e, Container c e)
  => c e
  -> e
  -> c e
softThreshold xs mu' = cmap f xs
  where f x = (signum x) * max ((abs x) - mu') 0

