use scene::Scene;
use regex::Regex;
use std::result;
use std::num::ParseIntError;
use std::str::FromStr;
use vector::Vector3;

struct ParsedScene<'a> {
    tokens: Vec<&'a str>,
    width: i32,
    height: i32,
    bgcolor: Vector3<f64>,
}

pub fn parse_scene(scenedef: String) -> result::Result<Scene, String> {
    // cleanup: ditch all comments and commas
    let comment_re = Regex::new(r"(,|#[^\n]*\n)").unwrap();
    let scenedef_sans_comments = comment_re.replace_all(&scenedef, "");
    let mut parsed_scene = ParsedScene {
        tokens: scenedef_sans_comments.split_whitespace().collect(),
        width: 0,
        height: 0,
        bgcolor: Vector3 { x: 0f64, y: 0f64, z: 0f64 },
    };

    parsed_scene.parse()
}

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
    fn parse(&'a mut self) -> result::Result<Scene, String> {
        self.tokens.reverse();
        while self.tokens.len() > 0 {
            self.next_token()
                .map(|section| {
                    match section.as_ref() {
                        "options" => self.parse_options(),
                        _ => Err(ParseSceneError::GenericError),
                    }
                });
        }
        Ok(Scene::new(50, 50))
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

    fn parse_int(&mut self) -> result::Result<i32, ParseSceneError> {
        self.next_token().and_then(|t| _parse::<i32>(&t))
    }

    fn parse_vector3(&mut self) -> result::Result<Vector3<f64>, ParseSceneError> {
        let mut result = Vector3 { x: 0f64, y: 0f64, z: 0f64 };
        self.next_token()
            .and_then(|t| _parse::<f64>(&t)).and_then(|x| { result.x = x; self.next_token() })
            .and_then(|t| _parse::<f64>(&t)).and_then(|y| { result.y = y; self.next_token() })
            .and_then(|t| _parse::<f64>(&t)).and_then(|z| { result.z = z; Ok(result) })
    }

    fn parse_section<F>(&mut self, directive_parser: F) -> ParseResult
            where F : Fn(&mut ParsedScene, String) -> ParseResult {
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
        self.parse_section(|p, t| {
            println!("options directive: {}", t);
            match t.as_ref() {
                "width" => p.parse_int().map(|i| p.width = i),
                "height" => p.parse_int().map(|i| p.height = i),
                "bgcolor" => p.parse_vector3().map(|v| p.bgcolor = v),
                "bspdepth" => p.parse_int().map(|i| ()),
                "bspleafobjs" => p.parse_int().map(|i| ()),
                _ => return Err(ParseSceneError::GenericError),
            }
        })
    }
}
