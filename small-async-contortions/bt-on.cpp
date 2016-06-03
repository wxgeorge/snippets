#include "bt-on.h"
#include "plog/Log.h"
#include <ncl.h>
#include <condition_variable>
#include <mutex>
#include <functional>

typedef std::function< void( NclEvent ) > SimpleCallback;
void my_ncl_callback(NclEvent e, void* user_data);

bool system_bluetooth_ready() {
	NclState state = nclState();

	switch(state) {
		case NCL_STATES: // had better never be returned
			LOGE << "Fatal error";
			exit(0);
		case NCL_STATE_FRESH:
			break;
		case NCL_STATE_INITING:
			return true; // this might be wrong.
		case NCL_STATE_INITED:
			return true;
		case NCL_STATE_STOPPED:
		case NCL_STATE_FAILED:
		case NCL_STATE_DEAD:
			return false;
	}

	// alright, so ncl was never inited.
	// Let's init for ourselves and check for health.
	bool inited=false;
	bool erred =false;
	std::condition_variable init_complete;

	SimpleCallback cb = 
		[&inited, &erred, &init_complete](NclEvent e) {
			switch(e.type) {
				case NCL_EVENT_INIT: {
					inited=true;
					init_complete.notify_all();
					break;
				}
				case NCL_EVENT_ERROR: {
					LOGW << "NCL_EVENT_ERROR=" << e.error.code
							 << " handle=" << e.error.handle;
					erred=true;
					init_complete.notify_all();
				}
				default: {
					// never get here
					break;
				}
			}
		};
	nclInit(my_ncl_callback, &cb, "bt-checker", NCL_MODE_DEFAULT, NULL);

	std::mutex m;
	std::unique_lock<std::mutex> lk(m);
	auto cv_status = init_complete.wait_for(lk, std::chrono::milliseconds(2000));
	if(cv_status == std::cv_status::timeout) {
		LOGE << "Timeout awaiting NCL_EVENT_INIT.";
	}
	nclFinish();
	return (inited && !erred);
}

void my_ncl_callback(NclEvent e, void* user_data) {
	SimpleCallback *cb = (SimpleCallback*)user_data;
	(*cb)(e);
}