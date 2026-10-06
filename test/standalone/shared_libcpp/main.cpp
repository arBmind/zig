#include "exception.hpp"
#include <cstdio>

int main() {
    // Flush before every throw so an unwinder crash remains diagnosable.
    std::setbuf(stdout, nullptr);
    int failures = 0;
    for (int kind = 0; kind != 4; ++kind) {
        std::printf("throwing case %d\n", kind);
        try {
            throw_exception(kind);
            std::puts("ERROR: function returned without throwing");
            ++failures;
        } catch (const std::exception& e) {
            std::printf("caught std::exception: %s\n", e.what());
            if (kind == 3) ++failures;
        } catch (...) {
            std::puts("caught ...");
            if (kind != 3) ++failures;
        }
    }
    return failures == 0 ? 0 : 1;
}
