use sceneobject::SceneObject;
use vector::Vector3;
use ray::{ Ray, HitInfo };

#[derive(Debug)]
pub struct Sphere {
    pub center: Vector3<f64>,
    pub radius: f64,
    pub material: String,
}

impl SceneObject for Sphere {
    fn intersect(&self, ray: &Ray, min: f64, max: f64) -> Option<HitInfo> {
        let to_center = ray.origin - self.center;
        let dd = ray.direction.mag2();
        // B^2
        let nt = ray.direction.dot(to_center);
        let mut discriminant = nt;
        discriminant *= discriminant;
        // 4AC
        discriminant -= dd * (to_center.mag2() - (self.radius * self.radius));

        if discriminant < 0.0 {
            return None
        }

        let root = discriminant.sqrt();
        let mut t = -1.0 * nt;
        if root > t {
            t += root;
        }
        else {
            t -= root;
        }
        t /= dd;

        if t < min || t > max {
            return None
        }

        let point = ray.origin + (ray.direction * t);
        Some(HitInfo {
            distance: t,
            point: point,
            normal: (point - self.center).normalize(),
            material: self.material.as_ref(),
        })
    }
}
