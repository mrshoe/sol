extern crate image;

use std::fs::File;
use std::path::Path;

mod vector;
mod ray;
mod camera;
mod scene;
mod sceneobject;
mod triangle;
mod light;

use scene::Scene;

const WIDTH: u32 = 512;
const HEIGHT: u32 = 512;

fn main() {
    let scene = Scene::new(WIDTH, HEIGHT);
    println!("{:?}", scene);
    let imgbuf = scene.raytrace();

    let ref mut fout = File::create(&Path::new("sol.png")).unwrap();
    let _ = image::ImageLuma8(imgbuf).save(fout, image::PNG);
}
