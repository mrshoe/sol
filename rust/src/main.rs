extern crate image;

use std::fs::File;
use std::path::Path;

mod vector;
mod ray;
mod camera;
mod scene;
mod sceneobject;
mod triangle;

use scene::Scene;

const width: u32 = 512;
const height: u32 = 512;

fn main() {
    let vf = vector::Vector3 { x: 0.5, y: 2.5, z: 4.5 };
    let vf2 = vector::Vector3 { x: 2.5, y: 4.5, z: 6.5 };
    let vi = vector::Vector3 { x: 1, y: 2, z: 3 };
    let vi1 = vector::Vector3 { x: 1, y: 1, z: 1 };
    let vi2 = vector::Vector3 { x: 2, y: 2, z: 2 };
    println!("{:?}", vf);
    println!("{:?}", vi);
    println!("{:?}", vi+vi2);
    println!("{:?}", vi1*vi2);
    println!("{:?}", vi2*vi2);
    println!("{:?}", vi1/vi2);
    println!("{:?}", vi2-vi1);
    println!("{:?}", vf+5.0);
    println!("{:?}", vf-3.0);
    println!("{:?}", vf*3.0);
    println!("{:?}", vf/4.0);
    println!("{:?}", vf.normalize());
    println!("{:?}", vi.mag());
    println!("{:?}", vi.mag2());
    println!("{:?}", vf.mag2());
    println!("{:?}", vf.cross(vf2));
    println!("{:?}", vf.cross(vf2).mag());
    println!("{:?}", vf.cross(vf2).normalize());


    let scene = Scene::new(width, height);
    println!("{:?}", scene);
    let imgbuf = scene.raytrace();

    let ref mut fout = File::create(&Path::new("sol.png")).unwrap();
    let _ = image::ImageLuma8(imgbuf).save(fout, image::PNG);
}
