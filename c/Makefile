#SOL = Sol.app/Contents/MacOS/sol
SOL = sol
CC = @gcc
ECHO = @echo
RM = @rm -f
LEX = @lex
YACC = @yacc -d
# profiling mode
#CFLAGS = -Wall -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_GNU_SOURCE -g -pg
# debug mode
#CFLAGS = -Wall -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_GNU_SOURCE -g
# release mode
CFLAGS = -Wall -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_GNU_SOURCE -fomit-frame-pointer -O3 -fast
# profiling mode
#LFLAGS = -lobjc -framework OpenGL -framework Cocoa -framework GLUT -pg
# non-profiling modes
LFLAGS = -lobjc -framework OpenGL -framework Cocoa -framework GLUT -framework Accelerate

PARSE_INPUT = \
	Lexer.lex \
	Parser.y

PARSE_FILES = \
	lex.yy.c \
	y.tab.c \
	y.tab.h

C_FILES = \
	$(PARSE_FILES) \
	Array.c \
	Box.c \
	BSP.c \
	Camera.c \
	Image.c \
	Lights.c \
	OpenGL.c \
	PhotonMap.c \
	Scene.c \
	SceneObjects.c \
	Sol.c \
	Sphere.c \
	Triangle.c \
	Vector3.c

O_FILES = $(patsubst %.c, %.o, $(C_FILES))

all: $(SOL)

clean:
	$(RM) $(O_FILES) $(PARSE_FILES) $(SOL)
	$(ECHO) "Sol is clean."

%.o: %.c
	$(ECHO) "Compiling $<..."
	$(CC) $(CFLAGS) -c -o $@ $<

$(PARSE_FILES): $(PARSE_INPUT)
	$(ECHO) "Lex'ing..."
	$(LEX) Lexer.lex
	$(ECHO) "Yacc'ing..."
	$(YACC) Parser.y

$(SOL): $(O_FILES)
	$(ECHO) "Linking..."
	$(CC) $(LFLAGS) -o $@ $(O_FILES)
	$(ECHO) "Sol is ready."
