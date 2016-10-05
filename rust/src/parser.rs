use scene::Scene;
use regex::Regex;
use std::result;
use std::num::ParseIntError;
use std::str::FromStr;
use vector::Vector3;

struct ParsedScene<'a> {
    tokens: Vec<&'a str>,
    scene: &'a mut Scene,
}

pub fn parse_scene(scenedef: String) -> result::Result<Scene, String> {
    // cleanup: ditch all comments and commas
    let comment_re = Regex::new(r"(,|#[^\n]*\n)").unwrap();
    let scenedef_sans_comments = comment_re.replace_all(&scenedef, "");
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
    fn from(err: ParseIntError) -> ParseSceneError {
        ParseSceneError::GenericError
    }
}

impl From<ParseSceneError> for String {
    fn from(err: ParseSceneError) -> String {
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
            self.next_token()
                .and_then(|section| {
                    match section.as_ref() {
                        "options" => self.parse_options(),
                        "camera" => self.parse_camera(),
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

    fn parse_section<F>(&mut self, mut directive_parser: F) -> ParseResult
            where F : FnMut(&mut ParsedScene, String) -> ParseResult {
        self.require("{")
            .and_then(|_| {
                loop {
                    match self.next_token() {
                        Ok(t) => {
                            if t == "}".to_string() {
                                return Ok(())
                            }
                            match directive_parser(self, t) {
                                Ok(_) => continue,
                                e @ Err(_) => return e,
                            }
                        },
                        _ => return Err(ParseSceneError::GenericError),
                    }
                }
            })
    }

    fn parse_options(&mut self) -> ParseResult {
        let mut width = 0u32;
        let mut height = 0u32;
        self.parse_section(|p, t| {
            println!("options directive: {}", t);
            match t.as_ref() {
                "width" => p.parse_num().map(|i| width = i),
                "height" => p.parse_num().map(|i| height = i),
                "bgcolor" => p.parse_vector3().map(|v| ()),
                "bspdepth" => p.parse_num::<i32>().map(|i| ()),
                "bspleafobjs" => p.parse_num::<i32>().map(|i| ()),
                _ => return Err(ParseSceneError::GenericError),
            }
        }).map(|_| self.scene.resize(width, height))
    }

    fn parse_camera(&mut self) -> ParseResult {
        self.parse_section(|p, t| {
            println!("camera directive: {}", t);
            match t.as_ref() {
//                "lookat" => p.parse_vector3().map(|v| ()),
//                "pos" => p.parse_vector3().map(|v| ()),
//                "up" => p.parse_vector3().map(|v| ()),
                "fov" => p.parse_num().map(|f| p.scene.camera.fov = f),
                _ => return Err(ParseSceneError::GenericError),
            }
        })
    }
}
