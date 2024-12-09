#include <farbe.h>
#include <iostream>
#include <cassert>

void test_rgba_creation() {
    auto red = farbe::rgb(255, 0, 0);
    auto green = farbe::rgba(0, 255, 0, 255);
    auto blue = farbe::hex(0x0000FFFF);
    
    assert(red.r() == 255 && red.g() == 0 && red.b() == 0 && red.a() == 255);
    assert(green.r() == 0 && green.g() == 255 && green.b() == 0 && green.a() == 255);
    assert(blue.r() == 0 && blue.g() == 0 && blue.b() == 255 && blue.a() == 255);
}

void test_hsla_creation() {
    auto red = farbe::hsla(0.0f, 1.0f, 0.5f, 1.0f);
    auto rgba = red.toRGBA();
    assert(std::abs(red.s() - 1.0f) < 0.01f);
}

void test_color_blending() {
    auto red = farbe::rgb(255, 0, 0);
    auto blue = farbe::rgb(0, 0, 255);
    auto purple = red.blend(blue);
    
    assert(purple.r() == 127 && purple.g() == 0 && purple.b() == 127);
}

void test_color_conversions() {
    auto red = farbe::rgb(255, 0, 0);
    auto red_hsla = red.toHSLA();
    auto back_to_red = red_hsla.toRGBA();
    
    assert(std::abs(red_hsla.h() - 0.0f) < 0.01f);
    assert(std::abs(red_hsla.s() - 1.0f) < 0.01f);
    assert(std::abs(red_hsla.l() - 0.5f) < 0.01f);
    
    assert(back_to_red.r() > 250 && back_to_red.g() < 5 && back_to_red.b() < 5);
}

void test_hsla_operations() {
    auto blue = farbe::hsla(240.0f/360.0f, 1.0f, 0.5f);
    auto gray = blue.grayscale();
    auto faded = blue.opacity(0.5f);
    
    assert(std::abs(gray.s()) < 0.01f);
    assert(std::abs(faded.a() - 0.5f) < 0.01f);
}

int main() {
    test_rgba_creation();
    test_hsla_creation();
    test_color_blending();
    test_color_conversions();
    test_hsla_operations();
    
    std::cout << "All tests passed successfully!" << std::endl;
    return 0;
}