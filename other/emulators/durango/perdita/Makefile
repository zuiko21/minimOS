
#COMPILER_FLAGS specifies the additional compilation options we're using 
COMPILER_FLAGS = -c -Wall -O2

#LINKER_FLAGS specifies the libraries we're linking against 
LINKER_FLAGS = -lstdc++ -lSDL2 -lSDL2_image -lSDL2_ttf -lSDL2_mixer -lm

perdita_exception.o: perdita_exception.cpp perdita_exception.hpp
	gcc $(COMPILER_FLAGS) perdita_exception.cpp -o perdita_exception.o

vdu.o: vdu.cpp vdu.hpp perdita_exception.hpp
	gcc $(COMPILER_FLAGS) vdu.cpp -o vdu.o

main.o: main.cpp vdu.hpp perdita_exception.hpp
	gcc $(COMPILER_FLAGS) main.cpp -o main.o
	
perdita: main.o vdu.o perdita_exception.o
	gcc $(LINKER_FLAGS) main.o vdu.o perdita_exception.o -o perdita
