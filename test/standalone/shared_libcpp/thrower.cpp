#include "exception.hpp"
#include <stdexcept>

extern "C" void throw_exception(int kind) {
    if (kind == 0) throw std::exception{};
    if (kind == 1) throw BoundaryException{};
    if (kind == 2) throw std::runtime_error("runtime_error from shared library");
    throw 42;
}
