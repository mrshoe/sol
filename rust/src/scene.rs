use camera::Camera;
use vector::Vector3;
use ray::{ Ray, HitInfo };
use std::f64;
use image::{ ImageBuffer, Luma };
use sceneobject::SceneObject;
use triangle::Triangle;

#[derive(Debug)]
pub struct Scene {
    width: u32,
    height: u32,

    camera: Camera,
    objects: Vec<Box<SceneObject>>,
}

impl Scene {
    pub fn new(width: u32, height: u32) -> Scene {
        let cam = Camera::new(width, height);
        let t = Triangle {
            v1: Vector3 { x: 0.0, y: 0.0, z: 0.0 },
            v2: Vector3 { x: 1.0, y: 0.0, z: 0.0 },
            v3: Vector3 { x: 0.0, y: 1.0, z: 0.0 },

            n1: Vector3 { x: 0.0, y: 0.0, z: 0.0 },
            n2: Vector3 { x: 0.0, y: 0.0, z: 0.0 },
            n3: Vector3 { x: 0.0, y: 0.0, z: 0.0 },
        };
        let mut objects: Vec<Box<SceneObject>> = Vec::new();
        objects.push(Box::new(t));
        Scene {
            width: width,
            height: height,

            camera: cam,
            objects: objects,
        }
    }

    pub fn raytrace(&self) -> ImageBuffer<Luma<u8>, Vec<u8>> {
        let z = Vector3 { x: 0.0, y: 0.0, z: 1.0 };
        ImageBuffer::from_fn(self.width, self.height, |x, y| {
            let eye_ray = self.camera.eye_ray(x, y);
            if let Some(hit) = self.trace(&eye_ray, 0.0, f64::MAX) {
                let color = self.shade(&hit, &eye_ray, 0);
                Luma([(color.x*255.0) as u8])
            }
            else {
                Luma([0u8])
            }
        })
    }

    fn trace(&self, eye_ray: &Ray, min: f64, max: f64) -> Option<HitInfo> {
        let mut minhit: Option<HitInfo> = None;
        for box_obj in &self.objects {
            let sh = box_obj.intersect(eye_ray, min, max);
            if let Some(hit) = sh {
                if let Some(mh) = minhit {
                    if hit.distance < mh.distance {
                        minhit = sh;
                    }
                }
                else {
                    minhit = sh;
                }
            }
        }
        minhit
    }

    fn shade(&self, hit: &HitInfo, eye_ray: &Ray, depth: u32) -> Vector3<f64> {
        Vector3 { x: 1.0, y: 1.0, z: 1.0, }
    }
}
