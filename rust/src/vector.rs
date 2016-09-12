use std::ops::{Add, Sub, Mul, Div};

#[derive(Debug, Clone, Copy)]
pub struct Vector3<T> {
    pub x: T,
    pub y: T,
    pub z: T,
}

impl<T> Add<Vector3<T>> for Vector3<T> where T: Add<Output=T> {
    type Output = Vector3<T>;

    fn add(self, rhs: Vector3<T>) -> Vector3<T> {
        Vector3 {
            x: self.x + rhs.x,
            y: self.y + rhs.y,
            z: self.z + rhs.z,
        }
    }
}

impl<T> Add<T> for Vector3<T> where T: Add<Output=T> + Copy {
    type Output = Vector3<T>;

    fn add(self, rhs: T) -> Vector3<T> {
        Vector3 {
            x: self.x + rhs,
            y: self.y + rhs,
            z: self.z + rhs,
        }
    }
}

impl<T> Sub<Vector3<T>> for Vector3<T> where T: Sub<Output=T> {
    type Output = Vector3<T>;

    fn sub(self, rhs: Vector3<T>) -> Vector3<T> {
        Vector3 {
            x: self.x - rhs.x,
            y: self.y - rhs.y,
            z: self.z - rhs.z,
        }
    }
}

impl<T> Sub<T> for Vector3<T> where T: Sub<Output=T> + Copy {
    type Output = Vector3<T>;

    fn sub(self, rhs: T) -> Vector3<T> {
        Vector3 {
            x: self.x - rhs,
            y: self.y - rhs,
            z: self.z - rhs,
        }
    }
}

impl<T> Mul<Vector3<T>> for Vector3<T> where T: Mul<Output=T> {
    type Output = Vector3<T>;

    fn mul(self, rhs: Vector3<T>) -> Vector3<T> {
        Vector3 {
            x: self.x * rhs.x,
            y: self.y * rhs.y,
            z: self.z * rhs.z,
        }
    }
}

impl<T> Mul<T> for Vector3<T> where T: Mul<Output=T> + Copy {
    type Output = Vector3<T>;

    fn mul(self, rhs: T) -> Vector3<T> {
        Vector3 {
            x: self.x * rhs,
            y: self.y * rhs,
            z: self.z * rhs,
        }
    }
}

impl<T> Div<Vector3<T>> for Vector3<T> where T: Div<Output=T> {
    type Output = Vector3<T>;

    fn div(self, rhs: Vector3<T>) -> Vector3<T> {
        Vector3 {
            x: self.x / rhs.x,
            y: self.y / rhs.y,
            z: self.z / rhs.z,
        }
    }
}

impl<T> Div<T> for Vector3<T> where T: Div<Output=T> + Copy {
    type Output = Vector3<T>;

    fn div(self, rhs: T) -> Vector3<T> {
        Vector3 {
            x: self.x / rhs,
            y: self.y / rhs,
            z: self.z / rhs,
        }
    }
}

impl<T> Vector3<T> where T: Mul<Output=T> + Add<Output=T> + Copy {
    pub fn mag2(&self) -> T {
        (self.x * self.x) + (self.y * self.y) + (self.z * self.z)
    }
}

impl<T> Vector3<T> where T: Mul<Output=T> + Add<Output=T> + Copy + Into<f64> {
    pub fn mag(&self) -> f64 {
        self.mag2().into().sqrt()
    }

    pub fn dot(&self, b: Vector3<T>) -> f64 {
        ((self.x*b.x) + (self.y*b.y) + (self.z*b.z)).into()
    }
}

impl<T> Vector3<T> where T: Mul<Output=T> + Add<Output=T> + Div<Output=T> + Div<f64> + Copy + Into<f64>, Vector3<T>: Div<f64, Output=Vector3<T>> {
    pub fn normalize(&self) -> Vector3<T> {
        *self / self.mag()
    }
}

impl<T> Vector3<T> where T: Mul<Output=T> + Sub<Output=T> + Copy {
    pub fn cross(&self, b: Vector3<T>) -> Vector3<T> {
        Vector3 {
            x: (self.y * b.z) - (self.z * b.y),
            y: (self.z * b.x) - (self.x * b.z),
            z: (self.x * b.y) - (self.y * b.x),
        }
    }
}
