# Farbe

A optimized color module and library for high performance applications.

## Features

Various different color formats are supported:
- RGBA
- HSLA
- HSV

also we can:
- Blending between colors
- Hexadecimal color parsing
- Comptime checks (Zig only)

## Build

### Zig

```sh
zig build [-Dtype=(static|dynamic] [-Dbinding=(c|cpp|zig]
```

Defaults:

- `type` = `static`
- `binding` = `zig`

### Examples

```sh
// zig
zig build run -Dname=ansi

// c
zig build run -Dname=c

// cpp
zig build run -Dname=cpp
```

## Usage

### Zig

```zig
const farbe = @import("farbe");

// Create a new RGBA color
const red = farbe.rgba(0xFF0000FF);

// Blend two colors together
const blue = farbe.rgba(0x0000FFFF);
const purple = red.blend(blue);

// Convert a color to a u32 value
const u32_value = red.toU32();

// Create a new HSLA color
const hsla = farbe.hsla(0.0, 1.0, 0.5, 1.0);

// Convert a color to an HSLA color
const hsla = red.toHsla();

// Blend two colors together
const blue = farbe.hsla(240.0 / 360.0, 1.0, 0.5, 1.0);
const purple = red.blend(blue);

// Convert a color to an RGBA color
const rgba = hsla.toRgba();

// Create a new HSLA color with opacity adjusted
const faded = hsla.opacity(0.5);

// Create a new HSLA color with opacity adjusted
const gray = hsla.grayscale();

// Fade out a color
hsla.fadeOut(0.5);
```

### C / C++

Use the [farbe.h](include/c/farbe.h) header file provided in the include directory.
```c++
#include "farbe.h"

// C
 farbe_hsla_t blue = farbe_hsla_create(240.0f/360.0f, 1.0f, 0.5f, 1.0f);

// C++
farbe::Hsla blue = farbe::Hsla(240.0f/360.0f, 1.0f, 0.5f, 1.0f);
```

### Rust

Use the [farbe-rs](include/rust/src/lib.rs) crate provided in the include directory.

```rust
use farbe_rs::{Hsla, Rgba};

let blue = Hsla::new(240.0f/360.0f, 1.0f, 0.5f, 1.0f);
```

## License

This project is licensed under the GLPLv3 license - see the [LICENSE](LICENSE) file for details.