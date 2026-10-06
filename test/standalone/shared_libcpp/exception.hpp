#pragma once
#include <exception>

class BoundaryException : public std::exception {
public:
    const char* what() const noexcept override {
        return "exception from shared library";
    }
};

extern "C" __attribute__((visibility("default"))) void throw_exception(int kind);
