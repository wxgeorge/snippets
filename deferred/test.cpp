#define CATCH_CONFIG_MAIN  // This tells Catch to provide a main() - only do this in one cpp file
#include "catch.hpp"
#include "deferred.h"

TEST_CASE( "Task is not executed if object is destructed before the time bound is reached", "[DeferredTask]" ) {
	bool tripped=false;
	{
		DeferredTask d(
            [&tripped](){ tripped=true; },
			std::chrono::milliseconds(5000));
	}
	// d's destructor has been called at this point. 
	REQUIRE_FALSE(tripped);
}

TEST_CASE( "Task IS executed if object persist beyond the time bound", "[DeferredTask]" ) {
	bool tripped = false;
	{
		DeferredTask d(
			[&tripped](){ tripped=true; },
			std::chrono::milliseconds(10));
		std::this_thread::sleep_for(std::chrono::milliseconds(50));
		// sleeps are generally bad, as they make tests slow, but we given the module,
		// the positive test requires some delay.
		// We've set this parameter as small as we can to keep the tests running fast.
	}
	REQUIRE(tripped);
}
