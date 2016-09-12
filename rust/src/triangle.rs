use sceneobject::SceneObject;
use vector::Vector3;
use ray::{ Ray, HitInfo };

#[derive(Debug)]
pub struct Triangle {
    pub v1: Vector3<f64>,
    pub v2: Vector3<f64>,
    pub v3: Vector3<f64>,
    pub n1: Vector3<f64>,
    pub n2: Vector3<f64>,
    pub n3: Vector3<f64>,
}

impl SceneObject for Triangle {
    fn intersect(&self, ray: &Ray, min: f64, max: f64) -> Option<HitInfo> {
        None
    }
}
