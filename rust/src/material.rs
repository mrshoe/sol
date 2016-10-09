use vector::Vector3;

#[derive(Debug)]
pub struct Material {
    pub name: String,
    pub color: Vector3<f64>,
    pub diffuse: f64,
    pub specular: f64,
}

impl Material {
    pub fn white() -> Material {
        Material {
            name: "white".to_string(),
            color: Vector3::init(1.0),
            diffuse: 1.0,
            specular: 0.0,
        }
    }
}

