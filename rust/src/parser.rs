use scene::Scene;
use regex::Regex;
use std::result;
use std::num::ParseIntError;
use std::str::FromStr;
use vector::Vector3;
use light::Light;
use triangle::Triangle;
use sphere::Sphere;
use material::Material;

struct ParsedScene<'a> {
    tokens: Vec<&'a str>,
    scene: &'a mut Scene,
}

pub fn parse_scene(scenedef: String) -> result::Result<Scene, String> {
    // cleanup: ditch all comments and commas
    let comment_re = Regex::new(r"(,|#[^\n]*\n)").unwrap();
    let scenedef_sans_comments = comment_re.replace_all(&scenedef, " ");
    let mut scene = Scene::new(128, 128);
    {
        let mut parsed_scene = ParsedScene {
            tokens: scenedef_sans_comments.split_whitespace().collect(),
            scene: &mut scene,
        };

        parsed_scene.parse();
    }
    Ok(scene)
}

#[derive(Debug)]
enum ParseSceneError {
    GenericError,
}

impl From<ParseIntError> for ParseSceneError {
    fn from(_: ParseIntError) -> ParseSceneError {
        ParseSceneError::GenericError
    }
}

impl From<ParseSceneError> for String {
    fn from(_: ParseSceneError) -> String {
        "Parse error".to_string()
    }
}

fn _parse<T>(v: &str) -> result::Result<T, ParseSceneError> where T : FromStr {
    v.parse().map_err(|_| ParseSceneError::GenericError)
}

type ParseResult = result::Result<(), ParseSceneError>;

impl<'a> ParsedScene<'a> {
    fn parse(&'a mut self) {
        self.tokens.reverse();
        while self.tokens.len() > 0 {
            let _ = self.next_token()
                .and_then(|section| {
                    match section.as_ref() {
                        "options" => self.parse_options(),
                        "camera" => self.parse_camera(),
                        "pointlight" => self.parse_pointlight(),
                        "triangle" => self.parse_triangle(),
                        "sphere" => self.parse_sphere(),
                        "material" => self.parse_material(),
                        _ => Err(ParseSceneError::GenericError),
                    }
                });
        }
    }

    fn next_token(&mut self) -> result::Result<String, ParseSceneError> {
        self.tokens.pop().ok_or(ParseSceneError::GenericError).map(|s| s.to_string())
    }

    fn require(&mut self, token: &str) -> ParseResult {
        self.next_token().and_then(|nt| {
            if nt == token  {
                Ok(())
            } else {
                Err(ParseSceneError::GenericError)
            }
        })
    }

    fn parse_string(&mut self) -> result::Result<String, ParseSceneError> {
        self.tokens.last()
            .ok_or(ParseSceneError::GenericError)
            .and_then(|s| {
                let q = '"';
                if s.chars().count() > 2 && s.chars().nth(0).unwrap() == q && s.chars().last().unwrap() == q {
                    let chars_to_trim: &[char] = &[q];
                    Ok(s.trim_matches(chars_to_trim).to_string())
                }
                else {
                    Err(ParseSceneError::GenericError)
                }
            // only if the above succeeds should we consume the token
            }).map(|s| { let _ = self.next_token(); s })
    }

    fn parse_num<T>(&mut self) -> result::Result<T, ParseSceneError> where T : FromStr {
        self.next_token().and_then(|t| _parse::<T>(&t))
    }

    fn parse_vector3(&mut self) -> result::Result<Vector3<f64>, ParseSceneError> {
        let mut result = Vector3::init(0f64);
        self.next_token()
            .and_then(|t| _parse::<f64>(&t)).and_then(|x| { result.x = x; self.next_token() })
            .and_then(|t| _parse::<f64>(&t)).and_then(|y| { result.y = y; self.next_token() })
            .and_then(|t| _parse::<f64>(&t)).map(|z| { result.z = z; result })
    }

    fn parse_section<F>(&mut self, mut directive_parser: F) -> result::Result<String, ParseSceneError>
            where F : FnMut(&mut ParsedScene, String) -> ParseResult {
        self.parse_string()
            .or(Ok("".to_string()))
            .and_then(|s| {
                self.require("{")
                    .and_then(|_| {
                        loop {
                            match self.next_token() {
                                Ok(t) => {
                                    if t == "}".to_string() {
                                        return Ok(s)
                                    }
                                    let _ = match directive_parser(self, t) {
                                        Ok(_) => continue,
                                        Err(_) => return Err(ParseSceneError::GenericError),
                                    };
                                },
                                _ => return Err(ParseSceneError::GenericError),
                            }
                        }
                    })
            })
    }

    fn parse_options(&mut self) -> ParseResult {
        let mut width = 0u32;
        let mut height = 0u32;
        self.parse_section(|p, t| {
            //println!("options directive: {}", t);
            match t.as_ref() {
                "width" => p.parse_num().map(|i| width = i),
                "height" => p.parse_num().map(|i| height = i),
                "bgcolor" => p.parse_vector3().map(|v| p.scene.bgcolor = v),
                "bspdepth" => p.parse_num::<i32>().map(|_| ()),
                "bspleafobjs" => p.parse_num::<i32>().map(|_| ()),
                _ => Err(ParseSceneError::GenericError),
            }
        }).map(|_| self.scene.resize(width, height))
    }

    fn parse_camera(&mut self) -> ParseResult {
        self.parse_section(|p, t| {
            //println!("camera directive: {}", t);
            match t.as_ref() {
                "lookat" => p.parse_vector3().map(|v| p.scene.camera.lookat = v),
                "pos" => p.parse_vector3().map(|v| p.scene.camera.eye = v),
                "up" => p.parse_vector3().map(|v| p.scene.camera.up = v),
                "fov" => p.parse_num::<f64>().map(|f| p.scene.camera.fov = f.to_radians()/2f64),
                _ => Err(ParseSceneError::GenericError),
            }
        }).map(|_| self.scene.camera.setup_viewport())
    }

    fn parse_pointlight(&mut self) -> ParseResult {
        let mut light = Light {
            position: Vector3::init(0.0),
            color: Vector3::init(1.0),
            wattage: 100f64,
        };
        self.parse_section(|p, t| {
            //println!("pointlight directive: {}", t);
            match t.as_ref() {
                "pos" => p.parse_vector3().map(|v| light.position = v),
                "color" => p.parse_vector3().map(|v| light.color = v),
                "wattage" => p.parse_num().map(|f| light.wattage = f),
                _ => Err(ParseSceneError::GenericError),
            }
        }).map(|_| self.scene.lights.push(light))
    }

    fn parse_triangle(&mut self) -> ParseResult {
        let mut tri = Triangle {
            v1: Vector3::init(0.0),
            v2: Vector3::new(1.0, 0.0, 0.0),
            v3: Vector3::new(0.0, 1.0, 0.0),

            n1: Vector3::new(0.0, 0.0, 1.0),
            n2: Vector3::new(0.0, 0.0, 1.0),
            n3: Vector3::new(0.0, 0.0, 1.0),

            material: "white".to_string(),
        };
        self.parse_section(|p, t| {
            //println!("triangle directive: {}", t);
            match t.as_ref() {
                "v1" => p.parse_vector3().map(|v| tri.v1 = v),
                "v2" => p.parse_vector3().map(|v| tri.v2 = v),
                "v3" => p.parse_vector3().map(|v| tri.v3 = v),
                "n1" => p.parse_vector3().map(|v| tri.n1 = v),
                "n2" => p.parse_vector3().map(|v| tri.n2 = v),
                "n3" => p.parse_vector3().map(|v| tri.n3 = v),
                "material" => p.parse_string().map(|s| tri.material = s),
                _ => Err(ParseSceneError::GenericError),
            }
        }).map(|_| self.scene.objects.push(Box::new(tri)))
    }

    fn parse_sphere(&mut self) -> ParseResult {
        let mut sphere = Sphere {
            center: Vector3::init(0.0),
            radius: 0.0,
            material: "white".to_string(),
        };
        self.parse_section(|p, t| {
            //println!("triangle directive: {}", t);
            match t.as_ref() {
                "center" => p.parse_vector3().map(|v| sphere.center = v),
                "radius" => p.parse_num().map(|f| sphere.radius = f),
                "material" => p.parse_string().map(|s| sphere.material = s),
                _ => Err(ParseSceneError::GenericError),
            }
        }).map(|_| self.scene.objects.push(Box::new(sphere)))
    }

    fn parse_material(&mut self) -> ParseResult {
        let mut mat = Material::white();
        self.parse_section(|p, t| {
            //println!("material directive: {}", t);
            match t.as_ref() {
                "color" => p.parse_vector3().map(|v| mat.color = v),
                "diffuse" => p.parse_num().map(|f| mat.diffuse = f),
                "specular" => p.parse_num().map(|f| mat.specular = f),
                _ => Err(ParseSceneError::GenericError),
            }
        }).map(|n| {
            //println!("material name: {}", n);
            mat.name = n;
            self.scene.materials.push(mat)
        })
    }
}
