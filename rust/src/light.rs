use vector::Vector3;

#[derive(Debug)]
pub struct Light {
    pub position: Vector3<f64>,
    pub color: Vector3<f64>,
    pub wattage: f64,
}
