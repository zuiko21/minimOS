#include <iostream>
#include <string>
#include "perdita_exception.hpp"
#include "vdu.hpp"

using namespace std;

int main(int argc, char* argv[])
{
    unsigned long i;
	try {
	    unsigned char *memory = new unsigned char[0x10000L];
	    for(i=0x0; i<0x10000L; i++) {
		memory[i]=0x00;
	    }
	    memory[0xdf80]=0x3f;
	    memory[0x6000]=0x23;
	    
	    Vdu *vdu = new Vdu();
	    vdu->setMemory(memory);
	    vdu->run();
                    
	    delete vdu;
	    delete memory;
    } catch (PerditaException &e) {
		cout << "Error! " << *e.what() << endl;
        flush(cout);        
	}
    
    return 0;
}
