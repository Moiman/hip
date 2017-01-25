{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
-- |
-- Module      : Graphics.Image.ColorSpace.YCbCr
-- Copyright   : (c) Alexey Kuleshevich 2017
-- License     : BSD3
-- Maintainer  : Alexey Kuleshevich <lehins@yandex.ru>
-- Stability   : experimental
-- Portability : non-portable
--
module Graphics.Image.ColorSpace.YCbCr (
  YCbCr(..), YCbCrA(..), Pixel(..), 
  ToYCbCr(..), ToYCbCrA(..)
  ) where

import Prelude hiding (map)
import Control.Applicative
import Data.Foldable
import Data.Typeable (Typeable)
import Foreign.Ptr
import Foreign.Storable

import Graphics.Image.Interface


-------------
--- YCbCr ---
-------------


-- | Color space is used to encode RGB information and is used in JPEG compression.
data YCbCr = LumaYCbCr  -- ^ Luma component (commonly denoted as __Y'__)
           | CBlueYCbCr -- ^ Blue difference chroma component
           | CRedYCbCr  -- ^ Red difference chroma component
           deriving (Eq, Enum, Show, Bounded, Typeable)

data instance Pixel YCbCr e = PixelYCbCr !e !e !e deriving Eq


instance Show e => Show (Pixel YCbCr e) where
  show (PixelYCbCr y b r) = "<YCbCr:("++show y++"|"++show b++"|"++show r++")>"


instance (Elevator e, Typeable e) => ColorSpace YCbCr e where
  type Components YCbCr e = (e, e, e)

  promote !e = PixelYCbCr e e e
  {-# INLINE promote #-}
  fromComponents !(y, b, r) = PixelYCbCr y b r
  {-# INLINE fromComponents #-}
  toComponents (PixelYCbCr y b r) = (y, b, r)
  {-# INLINE toComponents #-}
  getPxC (PixelYCbCr y _ _) LumaYCbCr  = y
  getPxC (PixelYCbCr _ b _) CBlueYCbCr = b
  getPxC (PixelYCbCr _ _ r) CRedYCbCr  = r
  {-# INLINE getPxC #-}
  setPxC (PixelYCbCr _ b r) LumaYCbCr  y = PixelYCbCr y b r
  setPxC (PixelYCbCr y _ r) CBlueYCbCr b = PixelYCbCr y b r
  setPxC (PixelYCbCr y b _) CRedYCbCr  r = PixelYCbCr y b r
  {-# INLINE setPxC #-}
  mapPxC f (PixelYCbCr y b r) = PixelYCbCr (f LumaYCbCr y) (f CBlueYCbCr b) (f CRedYCbCr r)
  {-# INLINE mapPxC #-}
  liftPx = fmap
  {-# INLINE liftPx #-}
  liftPx2 = liftA2
  {-# INLINE liftPx2 #-}
  foldlPx = foldl'
  {-# INLINE foldlPx #-}
  foldlPx2 f !z (PixelYCbCr y1 b1 r1) (PixelYCbCr y2 b2 r2) =
    f (f (f z y1 y2) b1 b2) r1 r2
  {-# INLINE foldlPx2 #-}


instance Functor (Pixel YCbCr) where
  fmap f (PixelYCbCr y b r) = PixelYCbCr (f y) (f b) (f r)
  {-# INLINE fmap #-}


instance Applicative (Pixel YCbCr) where
  pure !e = PixelYCbCr e e e
  {-# INLINE pure #-}
  (PixelYCbCr fy fb fr) <*> (PixelYCbCr y b r) = PixelYCbCr (fy y) (fb b) (fr r)
  {-# INLINE (<*>) #-}


instance Foldable (Pixel YCbCr) where
  foldr f !z (PixelYCbCr y b r) = f y (f b (f r z))
  {-# INLINE foldr #-}


instance Storable e => Storable (Pixel YCbCr e) where

  sizeOf _ = 3 * sizeOf (undefined :: e)
  alignment _ = alignment (undefined :: e)
  peek p = do
    q <- return $ castPtr p
    y <- peek q
    b <- peekElemOff q 1
    r <- peekElemOff q 2
    return (PixelYCbCr y b r)
  poke p (PixelYCbCr y b r) = do
    q <- return $ castPtr p
    pokeElemOff q 0 y
    pokeElemOff q 1 b
    pokeElemOff q 2 r


--------------
--- YCbCrA ---
--------------


-- | YCbCr color space with Alpha channel.
data YCbCrA = LumaYCbCrA  -- ^ Luma component (commonly denoted as __Y'__)
            | CBlueYCbCrA -- ^ Blue difference chroma component
            | CRedYCbCrA  -- ^ Red difference chroma component
            | AlphaYCbCrA -- ^ Alpha component.
            deriving (Eq, Enum, Show, Bounded, Typeable)

data instance Pixel YCbCrA e = PixelYCbCrA !e !e !e !e deriving Eq

 
instance Show e => Show (Pixel YCbCrA e) where
  show (PixelYCbCrA y b r a) = "<YCbCrA:("++show y++"|"++show b++"|"++show r++"|"++show a++")>"


instance (Elevator e, Typeable e) => ColorSpace YCbCrA e where
  type Components YCbCrA e = (e, e, e, e)

  promote !e = PixelYCbCrA e e e e
  {-# INLINE promote #-}
  fromComponents !(y, b, r, a) = PixelYCbCrA y b r a
  {-# INLINE fromComponents #-}
  toComponents (PixelYCbCrA y b r a) = (y, b, r, a)
  {-# INLINE toComponents #-}
  getPxC (PixelYCbCrA y _ _ _) LumaYCbCrA  = y
  getPxC (PixelYCbCrA _ b _ _) CBlueYCbCrA = b
  getPxC (PixelYCbCrA _ _ r _) CRedYCbCrA  = r
  getPxC (PixelYCbCrA _ _ _ a) AlphaYCbCrA = a
  {-# INLINE getPxC #-}
  setPxC (PixelYCbCrA _ b r a) LumaYCbCrA  y = PixelYCbCrA y b r a
  setPxC (PixelYCbCrA y _ r a) CBlueYCbCrA b = PixelYCbCrA y b r a
  setPxC (PixelYCbCrA y b _ a) CRedYCbCrA  r = PixelYCbCrA y b r a
  setPxC (PixelYCbCrA y b r _) AlphaYCbCrA a = PixelYCbCrA y b r a
  {-# INLINE setPxC #-}
  mapPxC f (PixelYCbCrA y b r a) =
    PixelYCbCrA (f LumaYCbCrA y) (f CBlueYCbCrA b) (f CRedYCbCrA r) (f AlphaYCbCrA a)
  {-# INLINE mapPxC #-}
  liftPx = fmap
  {-# INLINE liftPx #-}
  liftPx2 = liftA2
  {-# INLINE liftPx2 #-}
  foldlPx = foldl'
  {-# INLINE foldlPx #-}
  foldlPx2 f !z (PixelYCbCrA y1 b1 r1 a1) (PixelYCbCrA y2 b2 r2 a2) =
    f (f (f (f z y1 y2) b1 b2) r1 r2) a1 a2
  {-# INLINE foldlPx2 #-}

  
-- | Conversion to `YCbCr` color space.
class ColorSpace cs Double => ToYCbCr cs where

  -- | Convert to an `YCbCr` pixel.
  toPixelYCbCr :: Pixel cs Double -> Pixel YCbCr Double

  -- | Convert to an `YCbCr` image.
  toImageYCbCr :: (Array arr cs Double, Array arr YCbCr Double) =>
                  Image arr cs Double
               -> Image arr YCbCr Double
  toImageYCbCr = map toPixelYCbCr
  {-# INLINE toImageYCbCr #-}


-- | Conversion to `YCbCrA` from another color space with Alpha channel.
class (ToYCbCr (Opaque cs), AlphaSpace cs Double) => ToYCbCrA cs where

  -- | Convert to an `YCbCrA` pixel.
  toPixelYCbCrA :: Pixel cs Double -> Pixel YCbCrA Double
  toPixelYCbCrA px = addAlpha (getAlpha px) (toPixelYCbCr (dropAlpha px))
  {-# INLINE toPixelYCbCrA #-}

  -- | Convert to an `YCbCrA` image.
  toImageYCbCrA :: (Array arr cs Double, Array arr YCbCrA Double) =>
                   Image arr cs Double
                -> Image arr YCbCrA Double
  toImageYCbCrA = map toPixelYCbCrA
  {-# INLINE toImageYCbCrA #-}

  

instance (Elevator e, Typeable e) => AlphaSpace YCbCrA e where
  type Opaque YCbCrA = YCbCr

  getAlpha (PixelYCbCrA _ _ _ a) = a
  {-# INLINE getAlpha #-}
  addAlpha !a (PixelYCbCr y b r) = PixelYCbCrA y b r a
  {-# INLINE addAlpha #-}
  dropAlpha (PixelYCbCrA y b r _) = PixelYCbCr y b r
  {-# INLINE dropAlpha #-}


instance Functor (Pixel YCbCrA) where
  fmap f (PixelYCbCrA y b r a) = PixelYCbCrA (f y) (f b) (f r) (f a)
  {-# INLINE fmap #-}


instance Applicative (Pixel YCbCrA) where
  pure !e = PixelYCbCrA e e e e
  {-# INLINE pure #-}
  (PixelYCbCrA fy fb fr fa) <*> (PixelYCbCrA y b r a) = PixelYCbCrA (fy y) (fb b) (fr r) (fa a)
  {-# INLINE (<*>) #-}


instance Foldable (Pixel YCbCrA) where
  foldr f !z (PixelYCbCrA y b r a) = f y (f b (f r (f a z)))
  {-# INLINE foldr #-}


instance Storable e => Storable (Pixel YCbCrA e) where

  sizeOf _ = 3 * sizeOf (undefined :: e)
  alignment _ = alignment (undefined :: e)
  peek p = do
    q <- return $ castPtr p
    y <- peekElemOff q 0
    b <- peekElemOff q 1
    r <- peekElemOff q 2
    a <- peekElemOff q 3
    return (PixelYCbCrA y b r a)
  poke p (PixelYCbCrA y b r a) = do
    q <- return $ castPtr p
    poke q y
    pokeElemOff q 1 b
    pokeElemOff q 2 r
    pokeElemOff q 3 a


