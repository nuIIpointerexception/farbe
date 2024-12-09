#![allow(non_upper_case_globals)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]

#[cfg_attr(feature = "static", link(name = "farbe", kind = "static"))]
#[cfg_attr(feature = "dynamic", link(name = "farbe", kind = "dylib"))]
extern "C" {}

include!(concat!(env!("OUT_DIR"), "/bindings.rs"));

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct Rgba(farbe_rgba_t);

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct Hsla(farbe_hsla_t);

impl Rgba {
    #[inline]
    pub fn new(r: u8, g: u8, b: u8, a: u8) -> Self {
        unsafe { Self(farbe_rgba_from_components(r, g, b, a)) }
    }

    #[inline]
    pub fn from_hex(hex: u32) -> Self {
        unsafe { Self(farbe_rgba_from_hex(hex)) }
    }

    #[inline]
    pub fn from_hsla(h: f32, s: f32, l: f32, a: f32) -> Self {
        unsafe { Self(farbe_rgba_from_hsla(h, s, l, a)) }
    }

    #[inline]
    pub fn blend(&self, other: &Self) -> Self {
        unsafe { Self(farbe_rgba_blend(self.0, other.0)) }
    }

    #[inline]
    pub fn to_hsla(&self) -> Hsla {
        unsafe { Hsla(farbe_rgba_to_hsla(self.0)) }
    }

    #[inline]
    pub fn to_u32(&self) -> u32 {
        unsafe { farbe_rgba_to_u32(self.0) }
    }

    #[inline] pub fn r(&self) -> u8 { self.0.r }
    #[inline] pub fn g(&self) -> u8 { self.0.g }
    #[inline] pub fn b(&self) -> u8 { self.0.b }
    #[inline] pub fn a(&self) -> u8 { self.0.a }
}

impl Hsla {
    #[inline]
    pub fn new(h: f32, s: f32, l: f32, a: f32) -> Self {
        unsafe { Self(farbe_hsla_create(h, s, l, a)) }
    }

    #[inline]
    pub fn from_rgba(rgba: &Rgba) -> Self {
        unsafe { Self(farbe_hsla_from_rgba(rgba.0)) }
    }

    #[inline]
    pub fn blend(&self, other: &Self) -> Self {
        unsafe { Self(farbe_hsla_blend(self.0, other.0)) }
    }

    #[inline]
    pub fn grayscale(&self) -> Self {
        unsafe { Self(farbe_hsla_grayscale(self.0)) }
    }

    #[inline]
    pub fn with_opacity(&self, factor: f32) -> Self {
        unsafe { Self(farbe_hsla_opacity(self.0, factor)) }
    }

    #[inline]
    pub fn fade_out(&mut self, factor: f32) {
        unsafe { 
            let ptr = &mut self.0 as *mut farbe_hsla_t;
            farbe_hsla_fade_out(ptr, factor) 
        }
    }

    #[inline] pub fn h(&self) -> f32 { self.0.h }
    #[inline] pub fn s(&self) -> f32 { self.0.s }
    #[inline] pub fn l(&self) -> f32 { self.0.l }
    #[inline] pub fn a(&self) -> f32 { self.0.a }
}