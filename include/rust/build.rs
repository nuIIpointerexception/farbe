use std::{env, path::PathBuf, fs};

fn find_msvc_lib_path() -> Option<String> {
    let vs_path = std::env::var("VSINSTALLDIR")
        .or_else(|_| std::env::var("VS2022INSTALLDIR"))
        .unwrap_or_else(|_| "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community".to_string());
    
    let msvc_base = format!("{}\\VC\\Tools\\MSVC", vs_path);
    
    fs::read_dir(&msvc_base)
        .ok()?
        .filter_map(|entry| entry.ok())
        .filter(|entry| entry.path().is_dir())
        .filter_map(|entry| entry.file_name().into_string().ok())
        .max()
        .map(|version| format!("{}\\{}\\lib\\x64", msvc_base, version))
}

fn find_ucrt_lib_path() -> Option<String> {
    let kit_root = "C:\\Program Files (x86)\\Windows Kits\\10\\Lib";
    fs::read_dir(kit_root)
        .ok()?
        .filter_map(|entry| entry.ok())
        .filter(|entry| entry.path().is_dir())
        .filter_map(|entry| entry.file_name().into_string().ok())
        .max()
        .map(|version| format!("{}\\{}\\ucrt\\x64", kit_root, version))
}

fn main() {
    println!("cargo:rerun-if-changed=../../include/c/farbe.h");
    
    let lib_path = std::path::Path::new("../../zig-out/lib")
        .canonicalize()
        .expect("Failed to get absolute path");
    println!("cargo:rustc-link-search=native={}", lib_path.display());
    
    if cfg!(target_os = "windows") {
        if let Some(msvc_lib_path) = find_msvc_lib_path() {
            println!("cargo:rustc-link-search=native={}", msvc_lib_path);
        }
        if let Some(ucrt_lib_path) = find_ucrt_lib_path() {
            println!("cargo:rustc-link-search=native={}", ucrt_lib_path);
        }

        // Link against MSVC runtime libraries
        println!("cargo:rustc-link-lib=static=libvcruntime");
        println!("cargo:rustc-link-lib=static=libucrt");
        println!("cargo:rustc-link-lib=static=libcmt");

        // Link against chkstk.obj for stack probing
        println!("cargo:rustc-link-search=native={}\\chkstk.obj", lib_path.display());

        // Prevent conflicts with other runtime libraries
        println!("cargo:rustc-link-arg=/NODEFAULTLIB:msvcrt.lib");
        println!("cargo:rustc-link-arg=/NODEFAULTLIB:msvcrtd.lib");
        println!("cargo:rustc-link-arg=/NODEFAULTLIB:libcmtd.lib");
        println!("cargo:rustc-link-arg=/NODEFAULTLIB:vcruntimed.lib");
        println!("cargo:rustc-link-arg=/NODEFAULTLIB:ucrtd.lib");

        // Add stack probing function
        println!("cargo:rustc-link-arg=/INCLUDE:___chkstk_ms");
    }
    
    let is_static = cfg!(feature = "static");
    println!("cargo:rustc-link-lib={}=farbe", if is_static { "static" } else { "dylib" });

    let header_path = std::path::Path::new("../../include/c/farbe.h")
        .canonicalize()
        .expect("Failed to get absolute path");

    let bindings = bindgen::Builder::default()
        .header(header_path.to_str().unwrap())
        .clang_arg(format!("-I{}", header_path.parent().unwrap().display()))
        .parse_callbacks(Box::new(bindgen::CargoCallbacks::new()))
        .generate()
        .expect("Unable to generate bindings");

    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");
}