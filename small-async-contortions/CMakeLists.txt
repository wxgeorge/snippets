cmake_minimum_required(VERSION 2.8.7)
project(bt-running)

set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} "-std=c++11")

set(TIP ${CMAKE_CURRENT_SOURCE_DIR}/..)
add_subdirectory(${TIP}/ncl/cmake ${CMAKE_CURRENT_BINARY_DIR}/ncl)
include_directories(
	${TIP}/ncl/src
	${TIP}/ncl/Source
	${TIP}/plog/include
	)

set(SRCS
	bt-on.cpp
	main.cpp
	)

if(APPLE)
	add_executable(bt-on-cb ${SRCS})
	target_link_libraries(bt-on-cb Ncl)
else()
	add_executable(bt-on-net ${SRCS})
	target_link_libraries(bt-on-net NclNet)
endif()	
