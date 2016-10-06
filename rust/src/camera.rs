use vector::Vector3;
use ray::Ray;
use std::f64;

#[derive(Debug)]
pub struct Camera {
    width: f64,
    height: f64,

    pub eye: Vector3<f64>,
    pub up: Vector3<f64>,
    pub dir: Vector3<f64>,
    pub lookat: Vector3<f64>,
    pub fov: f64,
    u: Vector3<f64>,
    v: Vector3<f64>,
    w: Vector3<f64>,
    b: Vector3<f64>,
    t: Vector3<f64>,
}

impl Camera {
    pub fn new(width: u32, height: u32) -> Camera {
        let w = width as f64;
        let h = height as f64;
        let mut result = Camera {
            width: w,
            height: h,

            eye: Vector3::new(0.0, 0.0, 1.0),
            lookat: Vector3::init(0.0),
            up: Vector3::new(0.0, 1.0, 1.0),
            dir: Vector3::new(0.0, 0.0, -1.0),
            fov: f64::consts::PI / 4.0,

            // u, v, w are set by update()
            u: Vector3::new(0.0, 0.0, 0.0),
            v: Vector3::new(0.0, 0.0, 0.0),
            w: Vector3::new(0.0, 0.0, 0.0),

            // b and t are set by resize()
            b: Vector3::new(0.0, 0.0, 0.0),
            t: Vector3::new(0.0, 0.0, 0.0),
        };
        result.resize(w, h);
        result.update();
        result
    }

    pub fn resize(&mut self, width: f64, height: f64) {
        let bz = 0.0001;
        let tz = bz + 1.0;
        let fov = f64::consts::PI / 4.0;
        //tan(fov) = t.y / b.z
        let ty = bz * fov.tan();
        //t.x / t.y = nx / ny
        let tx = ((width as f64) / (height as f64)) * ty;
        let bx = -(tx);
        let by = -(ty);
        self.b = Vector3 { x: bx, y: by, z: bz };
        self.t = Vector3 { x: tx, y: ty, z: tz };
        self.width = width;
        self.height = height;
    }

    pub fn update(&mut self) {
        self.dir = (self.lookat - self.eye).normalize();
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
