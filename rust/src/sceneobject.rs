use ray::{ Ray, HitInfo };
use std::fmt::Debug;
use std::marker::Sync;

pub trait SceneObject: Debug + Sync {
    fn intersect(&self, ray: &Ray, min: f64, max: f64) -> Option<HitInfo>;
}
