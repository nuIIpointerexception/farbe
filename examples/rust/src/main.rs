use farbe_rs::{Rgba, Hsla};

fn main() {
    // Create colors using different methods
    let red = Rgba::new(255, 0, 0, 255);
    let blue = Rgba::from_hex(0x0000FFFF);
    let _green = Rgba::from_hsla(120.0/360.0, 1.0, 0.5, 1.0);  // Prefixed with _ to silence warning

    // Test color blending
    let purple = red.blend(&blue);
    println!("Purple (blended): r={}, g={}, b={}, a={}", 
             purple.r(), purple.g(), purple.b(), purple.a());

    // Test HSLA conversion
    let red_hsla = red.to_hsla();
    let red_back = Rgba::from_hsla(red_hsla.h(), red_hsla.s(), red_hsla.l(), red_hsla.a());
    println!("Red (converted): r={}, g={}, b={}, a={}", 
             red_back.r(), red_back.g(), red_back.b(), red_back.a());

    // Test HSLA operations
    let mut blue_hsla = Hsla::new(240.0/360.0, 1.0, 0.5, 1.0);
    let gray = blue_hsla.grayscale();
    let faded = blue_hsla.with_opacity(0.5);
    
    blue_hsla.fade_out(0.5);
    
    println!("Gray: h={:.3}, s={:.3}, l={:.3}, a={:.3}", 
             gray.h(), gray.s(), gray.l(), gray.a());
    println!("Faded: h={:.3}, s={:.3}, l={:.3}, a={:.3}", 
             faded.h(), faded.s(), faded.l(), faded.a());
    println!("Faded out blue: h={:.3}, s={:.3}, l={:.3}, a={:.3}", 
             blue_hsla.h(), blue_hsla.s(), blue_hsla.l(), blue_hsla.a());
}