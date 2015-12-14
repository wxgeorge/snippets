#pragma once

#include <functional>
#include <chrono>
#include <thread>
#include <future>

class DeferredTask {
public:
	DeferredTask(std::function<void()> task, std::chrono::milliseconds deferral_time) : 
		task(task),
		deferral_time(deferral_time)
	{
		cancelled_future = cancelled_promise.get_future();
		runner = new std::thread(&DeferredTask::main, this);
	}
	~DeferredTask() {
		cancelled_promise.set_value(); // wake the run thread, cancelling the task.
		if(runner->joinable()) { runner->join(); }
		delete runner;
	}

private:
	void main() {
		std::future_status status = cancelled_future.wait_for(this->deferral_time);
		if(status == std::future_status::timeout) {
			// we weren't cancelled. Do it.
			this->task();
		}
	}

	std::function<void()> task;
	std::chrono::milliseconds deferral_time;

	std::promise<void> cancelled_promise;
	std::future<void>  cancelled_future;

	std::thread *runner;
};
