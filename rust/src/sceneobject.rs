use ray::{ Ray, HitInfo };
use std::fmt::Debug;

pub trait SceneObject: Debug {
    fn intersect(&self, ray: &Ray, min: f64, max: f64) -> Option<HitInfo>;
}
