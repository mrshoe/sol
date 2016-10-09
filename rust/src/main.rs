extern crate image;
extern crate regex;

use std::fs::File;
use std::io;
use std::io::Read;
use std::path::Path;
use std::env;

mod vector;
mod ray;
mod camera;
mod scene;
mod sceneobject;
mod triangle;
mod sphere;
mod light;
mod parser;
mod material;

use parser::parse_scene;

fn readfile(filename: String) -> Result<String, io::Error> {
    let mut file = try!(File::open(filename));
    let mut s = String::new();
    try!(file.read_to_string(&mut s));
    Ok(s)
}

fn raytrace_scene(scenedef: String) {
    match parse_scene(scenedef) {
        Ok(scene) => {
            let imgbuf = scene.raytrace();

            let ref mut fout = File::create(&Path::new("sol.png")).unwrap();
            let _ = image::ImageRgb8(imgbuf).save(fout, image::PNG);
        },
        Err(s) => println!("{}", s),
    }
}

fn main() {
    if let Some(filename) = env::args().nth(1) {
        let scenefile = readfile(filename);
        match scenefile {
            Err(e) => println!("Error reading scene file: {}", e),
            Ok(contents) => raytrace_scene(contents),
        }
    }
    else if let Some(progname) = env::args().nth(0) {
        println!("Usage: {} scenefile", progname);
    }
    else {
        println!("Usage: sol scenefile");
    }
}
