COMPILER_FLAGS = -Wall -O2
LINKER_FLAGS = -lSDL2

all:perdita

perdita: perdita.c
	gcc $(COMPILER_FLAGS) $(LINKER_FLAGS) perdita.c -o perdita
	
perdita_debug: perdita.c
	gcc -g $(COMPILER_FLAGS) $(LINKER_FLAGS) perdita.c -o perdita_debug
	
clean:
	rm -f perdita; rm -f perdita_debug

