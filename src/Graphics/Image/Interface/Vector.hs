{-# LANGUAGE FlexibleContexts #-}
-- |
-- Module      : Graphics.Image.Interface.Vector
-- Copyright   : (c) Alexey Kuleshevich 2016
-- License     : BSD3
-- Maintainer  : Alexey Kuleshevich <lehins@yandex.ru>
-- Stability   : experimental
-- Portability : non-portable
--
module Graphics.Image.Interface.Vector (
  -- * Conversion
  fromUnboxedVector, toUnboxedVector,
  -- * Representation
  VU(..),
  -- * Linear index conversion
  toIx, fromIx
  ) where

import Graphics.Image.Interface.Vector.Unboxed
