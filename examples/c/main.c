#include <farbe.h>
#include <stdio.h>
#include <assert.h>
#include <math.h>

void test_rgba_creation() {
    farbe_rgba_t red = farbe_rgba_from_components(255, 0, 0, 255);
    farbe_rgba_t green = farbe_rgba_from_components(0, 255, 0, 255);
    farbe_rgba_t blue = farbe_rgba_from_hex(0x0000FFFF);
    
    assert(red.r == 255 && red.g == 0 && red.b == 0 && red.a == 255);
    assert(green.r == 0 && green.g == 255 && green.b == 0 && green.a == 255);
    assert(blue.r == 0 && blue.g == 0 && blue.b == 255 && blue.a == 255);
}

void test_hsla_creation() {
    farbe_rgba_t red = farbe_rgba_from_hsla(0.0f, 1.0f, 0.5f, 1.0f);
    farbe_hsla_t hsla = farbe_rgba_to_hsla(red);
    assert(fabsf(hsla.s - 1.0f) < 0.01f);
}

void test_color_blending() {
    farbe_rgba_t red = farbe_rgba_from_components(255, 0, 0, 255);
    farbe_rgba_t blue = farbe_rgba_from_components(0, 0, 255, 255);
    farbe_rgba_t purple = farbe_rgba_blend(red, blue);
    
    assert(purple.r == 127 && purple.g == 0 && purple.b == 127);
}

void test_color_conversions() {
    farbe_rgba_t red = farbe_rgba_from_components(255, 0, 0, 255);
    farbe_hsla_t red_hsla = farbe_rgba_to_hsla(red);
    farbe_rgba_t back_to_red = farbe_rgba_from_hsla(red_hsla.h, red_hsla.s, red_hsla.l, red_hsla.a);
    
    assert(fabsf(red_hsla.h - 0.0f) < 0.01f);
    assert(fabsf(red_hsla.s - 1.0f) < 0.01f);
    assert(fabsf(red_hsla.l - 0.5f) < 0.01f);
    
    assert(back_to_red.r > 250 && back_to_red.g < 5 && back_to_red.b < 5);
}

void test_hsla_operations() {
    farbe_hsla_t blue = farbe_hsla_create(240.0f/360.0f, 1.0f, 0.5f, 1.0f);
    farbe_hsla_t gray = farbe_hsla_grayscale(blue);
    farbe_hsla_t faded = farbe_hsla_opacity(blue, 0.5f);
    
    assert(fabsf(gray.s) < 0.01f);
    assert(fabsf(faded.a - 0.5f) < 0.01f);
}

int main() {
    test_rgba_creation();
    test_hsla_creation();
    test_color_blending();
    test_color_conversions();
    test_hsla_operations();

    printf("All tests passed successfully!\n");
    return 0;
}