use vector::Vector3;

#[derive(Debug, Clone, Copy)]
pub struct Ray {
    pub origin: Vector3<f64>,
    pub direction: Vector3<f64>,
}

#[derive(Debug, Clone, Copy)]
pub struct HitInfo<'a> {
    pub distance: f64,
    pub point: Vector3<f64>,
    pub normal: Vector3<f64>,
    pub material: &'a str,
}

