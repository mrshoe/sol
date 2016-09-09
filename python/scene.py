import math
from PIL import Image, ImageDraw
import copy
import pdb
#import psyco
#psyco.full()

WIDTH = 800
HEIGHT = 800
TMAX = 9999.0

class Color:
	def __init__(self, r=0.0, g=0.0, b=0.0):
		self.r=r
		self.g=g
		self.b=b
	
	def tuple(self):
		return int(255*self.r),int(255*self.g),int(255*self.b)

class Vector3:
	def __init__(self, x=0.0, y=0.0, z=0.0):
		self.x=x
		self.y=y
		self.z=z
	def set(self, x=0.0, y=0.0, z=0.0):
		self.x=x
		self.y=y
		self.z=z
	def normalize(self):
		mag = math.sqrt(self.x*self.x + self.y*self.y + self.z*self.z)
		self.x /= mag
		self.y /= mag
		self.z /= mag
	def dot(self, v):
		return self.x*v.x + self.y*v.y + self.z*v.z
	def mag2(self):
		return self.x*self.x + self.y*self.y + self.z*self.z
	def __repr__(self):
		return "x: %f, y: %f, z: %f" % (self.x,self.y,self.z)

class Ray:
	def __init__(self, o=Vector3(), d=Vector3()):
		self.o = o
		self.d = d

bgColor= Color()

class HitInfo:
	def __init__(self):
		self.t = 0.0
		self.n = Vector3()
		self.p = Vector3()
		self.color = Color(1.0,1.0,1.0)

class Light:
	def __init__(self, pos=Vector3(), color=Color()):
		self.pos = pos
		self.color = color

class Camera:
	def __init__(self):
		self.eye = Vector3(0.0,0.0,25.0)
		self.up = Vector3(0.0,1.0,0.0)
		self.dir = Vector3(0.0,0.0,-1.0)

	def eyerays(self):
		fov = math.pi / 8.0
		u = Vector3(-1.0,0.0,0.0)
		v = self.up
		w = self.dir
		b = Vector3(z=0.0001)
		t = Vector3(y=b.z*math.tan(fov),z=b.z+1.0)
		t.x = t.y
		b.x = -(t.x)
		b.y = -(t.y)
		for y in xrange(0,HEIGHT):
			for x in xrange(0,WIDTH):
				r = Ray()
				r.d.set(b.x + (t.x-b.x) * (float(x) + 0.5) / float(WIDTH),
						b.y + (t.y-b.y) * (float(y) + 0.5) / float(HEIGHT),
						b.z)
				r.d.set(u.x*r.d.x + v.x*r.d.x + w.x*r.d.x,
						u.y*r.d.y + v.y*r.d.y + w.y*r.d.y,
						u.z*r.d.z + v.z*r.d.z + w.z*r.d.z)
				r.d.normalize()
				r.o = self.eye
				yield x,HEIGHT-y,r

class Sphere:
	def __init__(self, center=Vector3(), radius=0.0, color=Color(1.0,1.0,1.0)):
		self.center = center
		self.radius = radius
		self.color = color
	def intersect(self, ray, tmin=0.0, tmax=TMAX):
		toCenter = Vector3(ray.o.x-self.center.x,ray.o.y-self.center.y,ray.o.z-self.center.z)
		dd = ray.d.mag2()
		discriminant = ray.d.dot(toCenter)
		t = -(discriminant)
		discriminant *= discriminant
		discriminant -= dd*(toCenter.mag2()-(self.radius*self.radius))
		if discriminant < 0.0:
			return None
		root = math.sqrt(discriminant)
		if root > t:
			t+=root
		else:
			t-=root
		t/=dd
		if t<tmin or t>tmax:
			return None
		hit = HitInfo()
		hit.t = t
		hit.p.set(ray.o.x+(ray.d.x*t),
				  ray.o.y+(ray.d.y*t),
				  ray.o.z+(ray.d.z*t))
		hit.n.set(hit.p.x-self.center.x,
				  hit.p.y-self.center.y,
				  hit.p.z-self.center.z)
		hit.n.normalize()
		hit.color = self.color
		return hit

class Scene:
	def __init__(self):
		self.objects = [
					Sphere(Vector3(0.0,-3.0,0.0),3.0),
					Sphere(Vector3(0.0,1.3,0.0),2.2),
					Sphere(Vector3(0.0,4.25,0.0),1.6),
					Sphere(Vector3(4.0,-3.0,0.0),3.0),
					Sphere(Vector3(4.0,1.3,0.0),2.2),
					Sphere(Vector3(4.0,4.25,0.0),1.6),
					Sphere(Vector3(-4.0,-3.0,0.0),3.0),
					Sphere(Vector3(-4.0,1.3,0.0),2.2),
					Sphere(Vector3(-4.0,4.25,0.0),1.6),
				]
		self.lights = [
				  Light(Vector3(0.0, 3.0, 1000.0), Color(0.2,0.2,0.2)),
				  Light(Vector3(0.0, 60.0, 10.0), Color(1.0,1.0,1.0)),
				  Light(Vector3(2.0, 20.0, 15.0), Color(0.0,0.0,0.3)),
				  ]
	def trace(self, ray, tmin=0.0, tmax=TMAX):
		tmpHit = None
		result = None
		for obj in self.objects:
			tmpHit = obj.intersect(ray,tmin,tmax)
			if tmpHit is not None and (result is None or tmpHit.t < result.t):
				result = tmpHit
		return result

	def shade(self, ray, hitInfo):
		result = Color()
		for light in self.lights:
			lightPos = light.pos
			toLight = Vector3(lightPos.x-hitInfo.p.x,lightPos.y-hitInfo.p.y,lightPos.z-hitInfo.p.z)
			shadowRay = Ray(hitInfo.p, toLight)
			if self.trace(shadowRay, 0.000001, 1.0):
				continue
			toLight.normalize()
			diffuse = hitInfo.n.dot(toLight)
			if diffuse < 0.0: diffuse = 0.0
			result.r += diffuse*hitInfo.color.r*light.color.r
			result.g += diffuse*hitInfo.color.g*light.color.g
			result.b += diffuse*hitInfo.color.b*light.color.b
		return result

	def raytrace(self):
		cam = Camera()
		img = Image.new("RGB",(WIDTH,HEIGHT))
		draw = ImageDraw.Draw(img)
		for x,y,eyeray in cam.eyerays():
			hit = self.trace(eyeray)
			if hit:
				draw.point((x,y),self.shade(eyeray,hit).tuple())

#		pixels = [self.trace(eyeray, hit) and self.shade(eyeray,hit).tuple() or bgColor.tuple() for eyeray in cam.eyerays()]
#		img.putdata(pixels)
#		img=img.resize((WIDTH/3,HEIGHT/3),Image.ANTIALIAS)
		img.save("sol.png","")

if __name__=="__main__":
	s = Scene()
	s.raytrace()
