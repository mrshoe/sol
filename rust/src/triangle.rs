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
        //page 157 in shirley's book explains this code
        //(see online errata for corrections)

        let a = self.v1.x - self.v2.x;
        let b = self.v1.y - self.v2.y;
        let c = self.v1.z - self.v2.z;
        let d = self.v1.x - self.v3.x;
        let e = self.v1.y - self.v3.y;
        let f = self.v1.z - self.v3.z;
        let g = ray.direction.x;
        let h = ray.direction.y;
        let i = ray.direction.z;
        let j = self.v1.x - ray.origin.x;
        let k = self.v1.y - ray.origin.y;
        let l = self.v1.z - ray.origin.z;
        let ei_hf = e*i - h*f;
        let gf_di = g*f - d*i;
        let dh_eg = d*h - e*g;
        let m = a*ei_hf + b*gf_di + c*dh_eg;

        let t = -((f*(a*k-j*b) + e*(j*c-a*l) + d*(b*l-k*c))/m);
        if t < min || t > max {
            return None;
        }
        //barycentric coords
        let beta = (j*ei_hf + k*gf_di + l*dh_eg)/m;
        if beta < -0.0001 || beta > 1.0001 {
            return None;
        }
        let gamma = (i*(a*k-j*b) + h*(j*c-a*l) + g*(b*l-k*c))/m;
        if gamma < -0.0001 || gamma > (1.0001-beta) {
            return None;
        }
        let alpha = 1.0-beta-gamma;
        let tn1 = self.n1 * alpha;
        let tn2 = self.n2 * beta;
        let tn3 = self.n3 * gamma;
        let normal = (tn1 + tn2 + tn3).normalize();

        let relative_point = ray.direction * t;
        let point = ray.origin + relative_point;
        Some(HitInfo {
            distance: t,
            point: point,
            normal: normal,
        })
    }
}
