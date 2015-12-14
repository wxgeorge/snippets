#define CATCH_CONFIG_MAIN  // This tells Catch to provide a main() - only do this in one cpp file
#include "catch.hpp"
#include "deferred.h"

TEST_CASE( "Factorials are computed", "[factorial]" ) {
	bool tripped=false;
	{
		DeferredTask d(
            [&tripped](){ tripped=true; },
			std::chrono::milliseconds(5000));
	}
	REQUIRE_FALSE(tripped);
	tripped = false;
	{
		DeferredTask d(
			[&tripped](){ tripped=true; },
			std::chrono::milliseconds(10));
		std::this_thread::sleep_for(std::chrono::milliseconds(50));
	}
	REQUIRE(tripped);
}
