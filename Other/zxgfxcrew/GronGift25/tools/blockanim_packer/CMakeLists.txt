CMAKE_MINIMUM_REQUIRED(VERSION 3.5)
PROJECT(blockanim_packer)
SET(APP_NAME blockanim_packer)

SET(CMAKE_CXX_STANDARD 17)

ADD_EXECUTABLE(${APP_NAME} blockanim_packer.cpp file_util.cpp file_util.h)

