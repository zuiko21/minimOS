#include <string>

#ifndef PERDITA_EXCEPTION_HPP
#define PERDITA_EXCEPTION_HPP

using namespace std;

class PerditaException {
	private:
	protected:
		string message;
	public:
		PerditaException(string &what);
		string* what();
};

#endif
