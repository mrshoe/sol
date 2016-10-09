use camera::Camera;
use vector::Vector3;
use ray::{ Ray, HitInfo };
use std::f64;
use image::{ ImageBuffer, Rgb };
use sceneobject::SceneObject;
use light::Light;
use material::Material;

#[derive(Debug)]
pub struct Scene {
    width: u32,
    height: u32,
    pub bgcolor: Vector3<f64>,

    pub camera: Camera,
    pub objects: Vec<Box<SceneObject>>,
    pub lights: Vec<Light>,
    pub materials: Vec<Material>,
}

impl Scene {
    pub fn new(width: u32, height: u32) -> Scene {
        let cam = Camera::new(width, height);
        Scene {
            width: width,
            height: height,
            bgcolor: Vector3::init(0.0),

            camera: cam,
            objects: Vec::new(),
            lights: Vec::new(),
            materials: Vec::new(),
        }
    }

    pub fn resize(&mut self, width: u32, height: u32) {
        self.width = width;
        self.height = height;
        self.camera.resize(width as f64, height as f64);
    }

    pub fn raytrace(&self) -> ImageBuffer<Rgb<u8>, Vec<u8>> {
        ImageBuffer::from_fn(self.width, self.height, |x, y| {
            let eye_ray = self.camera.eye_ray(x, y);
            let color = if let Some(hit) = self.trace(&eye_ray, 0.0, f64::MAX) {
                self.shade(&hit, &eye_ray, 0) * 255.0
            }
            else {
                self.bgcolor * 255.0
            };
            Rgb([color.x as u8, color.y as u8, color.z as u8])
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
        let mut result = Vector3 { x: 0f64, y: 0f64, z: 0f64 };
        for light in &self.lights {
            // TODO: get color from material
            let white = Material::white();
            let material = self.get_material(hit.material).unwrap_or(&white);
            let color = material.color;
            let to_light = light.position - hit.point;
            let light_dist_sq = to_light.mag2();
            let light_dist = light_dist_sq.sqrt();
            let light_falloff = 4f64 * f64::consts::PI * light_dist_sq / light.wattage;
            let to_light_norm = to_light / light_dist;
            let diffuse = hit.normal.dot(to_light_norm);
            result = result + (color * (diffuse / light_falloff));
        }
        result.clamp(0f64, 1f64)
    }

    fn get_material(&self, name: &str) -> Option<&Material> {
        for m in &self.materials {
            if m.name == name {
                return Some(&m);
            }
        }
        return None;
    }
}
