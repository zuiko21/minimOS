COMPILER_FLAGS = -Wall -O2
LINKER_FLAGS = -lSDL2

all:perdita

perdita: perdita.c
	gcc perdita.c $(COMPILER_FLAGS) $(LINKER_FLAGS) -o perdita
	
perdita_debug: perdita.c
	gcc -g perdita.c $(COMPILER_FLAGS) $(LINKER_FLAGS) -o perdita_debug
	
clean:
	rm -f perdita; rm -f perdita_debug

