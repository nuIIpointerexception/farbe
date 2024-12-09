#ifndef FARBE_H
#define FARBE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#pragma pack(push, 4)
typedef struct {
    uint8_t r, g, b, a;
} farbe_rgba_t;

typedef struct {
    float h, s, l, a;
} farbe_hsla_t;
#pragma pack(pop)

farbe_rgba_t farbe_rgba_from_components(uint8_t r, uint8_t g, uint8_t b, uint8_t a);
farbe_rgba_t farbe_rgba_from_hex(uint32_t hex);
farbe_rgba_t farbe_rgba_from_hsla(float h, float s, float l, float a);
farbe_rgba_t farbe_rgba_blend(farbe_rgba_t a, farbe_rgba_t b);
farbe_hsla_t farbe_rgba_to_hsla(farbe_rgba_t color);
uint32_t farbe_rgba_to_u32(farbe_rgba_t color);

farbe_hsla_t farbe_hsla_create(float h, float s, float l, float a);
farbe_hsla_t farbe_hsla_from_rgba(farbe_rgba_t color);
farbe_hsla_t farbe_hsla_blend(farbe_hsla_t a, farbe_hsla_t b);
farbe_hsla_t farbe_hsla_grayscale(farbe_hsla_t color);
farbe_hsla_t farbe_hsla_opacity(farbe_hsla_t color, float factor);
void farbe_hsla_fade_out(farbe_hsla_t* color, float factor);

#ifdef __cplusplus
}

namespace farbe {
    class HSLA;

    class RGBA {
    private:
        farbe_rgba_t color;

    public:
        RGBA(uint8_t r, uint8_t g, uint8_t b, uint8_t a = 255) 
            : color(farbe_rgba_from_components(r, g, b, a)) {}
        explicit RGBA(uint32_t hex) 
            : color(farbe_rgba_from_hex(hex)) {}
        explicit RGBA(const farbe_rgba_t& c) 
            : color(c) {}

        uint8_t r() const { return color.r; }
        uint8_t g() const { return color.g; }
        uint8_t b() const { return color.b; }
        uint8_t a() const { return color.a; }

        RGBA blend(const RGBA& other) const {
            return RGBA(farbe_rgba_blend(color, other.color));
        }

        HSLA toHSLA() const;
        uint32_t toU32() const { return farbe_rgba_to_u32(color); }

        operator farbe_rgba_t() const { return color; }
    };

    class HSLA {
    private:
        farbe_hsla_t color;

    public:
        HSLA(float h, float s, float l, float a = 1.0f) 
            : color(farbe_hsla_create(h, s, l, a)) {}
        explicit HSLA(const farbe_hsla_t& c) 
            : color(c) {}

        float h() const { return color.h; }
        float s() const { return color.s; }
        float l() const { return color.l; }
        float a() const { return color.a; }

        RGBA toRGBA() const { 
            return RGBA(farbe_rgba_from_hsla(color.h, color.s, color.l, color.a)); 
        }
        
        HSLA blend(const HSLA& other) const {
            return HSLA(farbe_hsla_blend(color, other.color));
        }

        HSLA grayscale() const {
            return HSLA(farbe_hsla_grayscale(color));
        }

        HSLA opacity(float factor) const {
            return HSLA(farbe_hsla_opacity(color, factor));
        }

        void fadeOut(float factor) {
            farbe_hsla_fade_out(&color, factor);
        }

        operator farbe_hsla_t() const { return color; }
    };

    inline RGBA rgb(uint8_t r, uint8_t g, uint8_t b) {
        return RGBA(r, g, b);
    }

    inline RGBA rgba(uint8_t r, uint8_t g, uint8_t b, uint8_t a = 255) {
        return RGBA(r, g, b, a);
    }

    inline RGBA hex(uint32_t hex) {
        return RGBA(hex);
    }

    inline HSLA hsla(float h, float s, float l, float a = 1.0f) {
        return HSLA(h, s, l, a);
    }

    // Implementation of cross-dependent methods
    inline HSLA RGBA::toHSLA() const {
        return HSLA(farbe_rgba_to_hsla(color));
    }
}
#endif

#endif // FARBE_H