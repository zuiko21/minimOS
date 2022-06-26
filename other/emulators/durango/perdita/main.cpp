#include <iostream>
#include <string>
#include "perdita_exception.hpp"
#include "vdu.hpp"

using namespace std;

int main(int argc, char* argv[])
{
	try {
        Vdu *vdu = new Vdu();
        vdu->run();
                    
        delete vdu;
    } catch (PerditaException &e) {
		cout << "Error! " << *e.what() << endl;
        flush(cout);        
	}
    
    return 0;
}
