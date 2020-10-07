# The following lines of boilerplate have to be in your project's CMakeLists
# in this exact order for cmake to work correctly
cmake_minimum_required(VERSION 3.5)

# set(ENV{EXTRA_CFLAGS} "-mtext-section-literals")
# set(ENV{EXTRA_CXXFLAGS} "-mtext-section-literals")
# set(ENV{EXTRA_CPPFLAGS} "-mtext-section-literals")
# # if(${ESP_PLATFORM})
# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mlongcalls -mtext-section-literals")
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mlongcalls -mtext-section-literals")
# set(CMAKE_CPP_FLAGS "${CMAKE_CPP_FLAGS} -mlongcalls -mtext-section-literals")
# # endif()
#LDFLAGS += "-mtext-section-literals"

#set(LDFLAGS "${LDFLAGS} -mtext-section-literals")
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(punyforth)


