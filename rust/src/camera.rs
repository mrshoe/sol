use vector::Vector3;
use ray::Ray;
use std::f64;

#[derive(Debug)]
pub struct Camera {
    width: f64,
    height: f64,

    eye: Vector3<f64>,
    up: Vector3<f64>,
    dir: Vector3<f64>,
//    lookat: Vector3<f64>,
    fov: f64,
    u: Vector3<f64>,
    v: Vector3<f64>,
    w: Vector3<f64>,
    b: Vector3<f64>,
    t: Vector3<f64>,
}

impl Camera {
    pub fn new(width: u32, height: u32) -> Camera {
        let bz = 0.0001;
        let tz = bz + 1.0;
        let fov = f64::consts::PI / 4.0;
        //tan(fov) = t.y / b.z
        let ty = bz * fov.tan();
        //t.x / t.y = nx / ny
        let tx = ((width as f64) / (height as f64)) * ty;
        let bx = -(tx);
        let by = -(ty);
        let mut result = Camera {
            width: width as f64,
            height: height as f64,

            eye: Vector3 { x: 0.0, y: 0.0, z: 1.0 },
            up: Vector3 { x: 0.0, y: 1.0, z: 1.0 },
            dir: Vector3 { x: 0.0, y: 0.0, z: -1.0 },
            fov: f64::consts::PI / 4.0,

            // u, v, w are set by update()
            u: Vector3 { x: 0.0, y: 0.0, z: 0.0 },
            v: Vector3 { x: 0.0, y: 0.0, z: 0.0 },
            w: Vector3 { x: 0.0, y: 0.0, z: 0.0 },

            b: Vector3 { x: bx, y: by, z: bz },
            t: Vector3 { x: tx, y: ty, z: tz },
        };
        result.update();
        result
    }

    fn update(&mut self) {
        self.w = self.dir;
        self.u = self.up.cross(self.w).normalize();
        self.v = self.w.cross(self.u).normalize();
    }

    pub fn eye_ray(&self, x: u32, y: u32) -> Ray {
        // x-flip ?
        let x = self.width as u32 - x;
        // y-flip ?
        let y = self.height as u32 - y;
        let nx = ((x as f64) + 0.5) / self.width;
        let ny = ((y as f64) + 0.5) / self.height;
        let sx = self.b.x + (self.t.x - self.b.x) * nx;
        let sy = self.b.y + (self.t.y - self.b.y) * ny;
        let sz = self.b.z;
        let uprime = self.u * sx;
        let vprime = self.v * sy;
        let wprime = self.w * sz;
        //with respect to the eye
        let rd = Vector3 {
            x: uprime.x + vprime.x + wprime.x,
            y: uprime.y + vprime.y + wprime.y,
            z: uprime.z + vprime.z + wprime.z,
        };
        Ray {
            origin: self.eye,
            direction: rd.normalize(),
        }
    }
}
