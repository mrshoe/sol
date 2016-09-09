include Makedefs.mac

D_FILES = \
	AccelStructure.d \
	Box.d \
	BSP.d \
	Camera.d \
	Image.d \
	Lights.d \
	Main.d \
	OpenGL.d \
	Parser.d \
	PhotonMap.d \
	Scene.d \
	Sol.d \
	Sphere.d \
	Triangle.d \
	TriangleMesh.d \
	Vector3.d

O_FILES = $(patsubst %.d, %.o, $(D_FILES))

all: $(SOL)

clean:
	$(RM) $(O_FILES) $(SOL)
	$(ECHO) "Sol is clean."

%.o: %.d
	$(ECHO) "Compiling $<..."
	$(DC) $(DFLAGS) -c $(OUTFILE) $<

$(SOL): $(O_FILES)
	$(ECHO) "Linking..."
	$(DC) $(LFLAGS) $(OUTFILE) $(O_FILES)
	$(ECHO) "Sol is ready."
