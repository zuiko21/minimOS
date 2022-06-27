#include <string>
#include "perdita_exception.hpp"

PerditaException::PerditaException(string& what) {
	this->message = what;
}

string* PerditaException::what(void) {
	return &message;
}
