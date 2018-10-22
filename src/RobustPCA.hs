{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}
--------------------------------------------------------------------------------
-- |
-- Robust Principal Component Analysis Outlier Detection a la Netflix/Surus
---------------------------------------------------------------------------------
module RobustPCA
  ( -- * Datatypes
    LR(..)
  , LRPenalty(..)
  , MaxIters(..)
  , FitIters(..)
  , Periodicity(..)
  , RobustPCA(..)
  , Sparse(..)
  , SparsePenalty(..)
  , Tolerance(..)
    -- * Fitting
  , runRobustPCA
  , optimize
  ) where

import           Control.Foldl            (fold)
import           Control.Foldl.Statistics (LMVSK (..), fastLMVSKu, fastStdDev)
import           Control.Lens             (declareWrapped, makeLenses, use,
                                           (+=), (.=), (^.))
import           Control.Monad            (return)
import           Control.Monad.Identity   (runIdentity)
import           Control.Monad.Loops      (whileM_)
import           Control.Monad.State      (State, execStateT)
import           Data.Functor             (void, (<$>))
import           Data.List                (replicate, take)
import           Numeric.LinearAlgebra    (Matrix, R, cmap, cols, diag, flatten,
                                           rows, sumElements, thinSVD, toList,
                                           tr, (<>), (><))
import           Prelude                  (Double, Int, Show, abs, div,
                                           fromIntegral, max, mod, ($), (&&),
                                           (*), (**), (+), (-), (.), (/), (<),
                                           (>))
import           Utils                    (absL1Norm, frobeniusNorm,
                                           softThreshold)


---------------------------------------------------------------------------------
-- Datatypes --------------------------------------------------------------------
---------------------------------------------------------------------------------

declareWrapped [d|
  newtype LRPenalty     = LRPenalty Double     deriving Show
  newtype SparsePenalty = SparsePenalty Double deriving Show
  newtype Periodicity   = Periodicity Int      deriving Show
  newtype MaxIters      = MaxIters Int         deriving Show
  newtype FitIters      = FitIters Int         deriving Show
  newtype LR            = LR [R]               deriving Show
  newtype Sparse        = Sparse [R]           deriving Show
  newtype Tolerance     = Tolerance [R]        deriving Show
  |]

-- |
-- Optimization state
data RobustPCA
  = RobustPCA
  { _maxIters       :: MaxIters
    -- ^ maximum optimization iterations
  , _lrPenalty      :: LRPenalty
    -- ^ low rank fit penalty
  , _sparsePenalty  :: SparsePenalty
    -- ^ sparse fit penalty
  , _normalizedData :: Matrix R
    -- ^ normalized input data matrix
  , _iters          :: Int
    -- ^ iterations count
  , _obj            :: R
    -- ^ objective
  , _tol            :: R
    -- ^ tolerance
  , _diff           :: R
    -- ^ difference
  , _mean           :: R
    -- ^ input data mean
  , _stdDev         :: R
    -- ^ input data standard deviation
  , _mu             :: R
    -- ^ incoherence factor
  , _lr             :: Matrix R
    -- ^ recovered low rank matrix (underlying data 'approximation')
  , _sparse         :: Matrix R
    -- ^ sparse outliers matrix
  , _tolerance      :: Matrix R
    -- ^ tolerated deviation of real data from the 'fit'
  } deriving (Show)
makeLenses ''RobustPCA

-- | Fitting state monad
type RobustPCAM a = State RobustPCA a


---------------------------------------------------------------------------------
-- Fitting ----------------------------------------------------------------------
---------------------------------------------------------------------------------

-- |
-- Run robust PCA optimization
runRobustPCA
  :: [R]
  -- ^ input 'Real' data
  -> LRPenalty
  -- ^ low rank fit penalty
  -> SparsePenalty
  -- ^ sparse fit penalty
  -> Periodicity
  -- ^ input data periodicity
  -> MaxIters
  -- ^ maximum iteration count allowed
  -> (LR, Sparse, Tolerance, FitIters)
runRobustPCA originalData lpen spen p mi =
    (LR lr', Sparse sparse', Tolerance tol', FitIters itrs)
  where rs      = runIdentity $
                   execStateT optimize $
                    initState originalData lpen spen p mi
        mean'   = rs^.mean
        stdDev' = rs^.stdDev
        lr'     = toList $ flatten $ tr $ cmap ((mean' +) . (stdDev' *)) (rs^.lr)
        sparse' = toList $ flatten $ tr $ cmap (stdDev' *) (rs^.sparse)
        tol'    = toList $ flatten $ tr $ cmap (stdDev' *) (rs^.tolerance)
        itrs    = rs^.iters


---------------------------------------------------------------------------------
-- Internal Functions -----------------------------------------------------------
---------------------------------------------------------------------------------

initState
  :: [R]
  -> LRPenalty
  -> SparsePenalty
  -> Periodicity
  -> MaxIters
  -> RobustPCA
initState originalData lp sp (Periodicity p) mi =
    RobustPCA mi lp sp normalizedData' 0 obj' tol' diff' m sdev mu' z z z
  where (LMVSK l m v _ _) = fold fastLMVSKu originalData
        sdev                   = v ** 0.5
        zeroMeanUnitVariance x = (x - m) / sdev
        paddedLength           = l - (l `mod` p)
        normalizedData'        =
          tr $ ((paddedLength `div` p) >< p)
               (zeroMeanUnitVariance <$> take paddedLength originalData)
        r                      = rows normalizedData'
        c                      = cols normalizedData'
        z                      = (r >< c) (replicate (r * c) 0.0)
        mu'                    =
          fromIntegral c * fromIntegral r / (4 * absL1Norm normalizedData')
        obj'                   = 0.5 * ((frobeniusNorm normalizedData') ** 2.0)
        tol'                   = 1e-8 * obj'
        diff'                  = 2.0 * tol'

optimize :: RobustPCAM ()
optimize = whileM_ checkTolerance go
  where go = do
          nuclearNorm <- computeSparse
          l1Norm      <- computeLR
          l2Norm      <- computeTol
          objPrev     <- use obj
          let obj'     = 0.5 * l2Norm + nuclearNorm + l1Norm
          diff        .= abs (objPrev - obj')
          obj         .= obj'
          void updateMu
          iters += 1
        checkTolerance = do
          iters'       <- use iters
          MaxIters mi' <- use maxIters
          tol'         <- use tol
          diff'        <- use diff
          return $ diff' > tol' && iters' < mi'

computeSparse :: RobustPCAM R
computeSparse = do
  normalizedData'          <- use normalizedData
  SparsePenalty spen       <- use sparsePenalty
  mu'                      <- use mu
  lr'                      <- use lr
  let sparsePenalty'        = spen * mu'
  let normalizedDataMinusLr = normalizedData' - lr'
  let penalizedSparse       = softThreshold normalizedDataMinusLr sparsePenalty'
  sparse                   .= penalizedSparse
  return $ (absL1Norm penalizedSparse) * sparsePenalty'

computeLR :: RobustPCAM R
computeLR = do
  normalizedData'              <- use normalizedData
  LRPenalty lpen               <- use lrPenalty
  mu'                          <- use mu
  sparse'                      <- use sparse
  let lrPenalty'                = lpen * mu'
  let normalizedDataMinusSparse = normalizedData' - sparse'
  let (u, svs, v)               = thinSVD normalizedDataMinusSparse
  let penalizedD                = softThreshold svs lrPenalty'
  let d'                        = diag penalizedD
  lr                           .= u <> d' <> (tr v)
  return $ (sumElements penalizedD) * lrPenalty'

computeTol :: RobustPCAM R
computeTol = do
  normalizedData' <- use normalizedData
  lr'             <- use lr
  sparse'         <- use sparse
  let tolerance'   = normalizedData' - lr' - sparse'
  tolerance       .= tolerance'
  return $ (frobeniusNorm tolerance') ** 2

updateMu :: RobustPCAM ()
updateMu = do
  tolerance'  <- use tolerance
  let tdStdDev = fold fastStdDev (toList $ flatten tolerance')
  let m        = rows tolerance'
  let n        = cols tolerance'
  mu .= max 0.01 (tdStdDev * ((2.0 * (fromIntegral $ max m n)) ** 0.5))

