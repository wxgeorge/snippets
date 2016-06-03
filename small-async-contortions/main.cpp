#include <plog/Log.h>
#include <plog/Appenders/ConsoleAppender.h>

static plog::ConsoleAppender<plog::TxtFormatter> console;

#include "bt-on.h"

int main() {
	plog::init(plog::debug, &console);

	LOGD << "Hello from plog!";

	if(system_bluetooth_ready()) {
		std::cout << "System bluetooth is ready!\n";
		exit(0);
	} else {
		std::cout << "System bluetooth is not ready!\n";
		exit(1);
	}
}