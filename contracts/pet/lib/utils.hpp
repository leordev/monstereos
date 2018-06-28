#pragma once

#include <string>

using std::string;

namespace utils {
    int count_spaces(string str) {
        int spaces = 0;
        for (int i = 0; i < str.length(); i++) {
            if (isspace(str[i]))
                spaces++;
        }
        return spaces;
    }

    bool is_zero(const checksum256& a) {
        const uint64_t *p64 = reinterpret_cast<const uint64_t*>(&a);
        return p64[0] == 0 && p64[1] == 0 && p64[2] == 0 && p64[3] == 0;
    }

    uint64_t hash_str(const string &str) {
        return hash<string>{}(str);
    }
}

