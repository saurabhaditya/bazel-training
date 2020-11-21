/**
 * Cypher
 *
 * "Compiles" and interprets input files, converting all alphabetical characters to numbers, and vice-versa.
 *
 * Numeric values are shifted by the specified offset (defaults to 1), hence the name "Cypher".
 */

#ifndef CPP_CYPHER_H
#define CPP_CYPHER_H

#include <iostream>
#include <string>
#include <utility>
#include <vector>

#include <fstream>
#include <exception>

using namespace std;

class Cypher {
    const string input_ext {"cy"};
    const string output_ext {"cb"};
    const char delim;
    const int offset;
    const bool decipher_mode;
    const vector<string> sources;
    const string outdir;
public:
    explicit Cypher(vector<string> s, string outdir, bool d, int o = 1, char de = '.');
    void run();
private:
    string read(const string& path);
    static void write(const string& path, const string& contents);
    string encipher(const string& contents);
    string decipher(const string& str);
    int get_cipher_position(char c);
};

inline bool ends_with(std::string const & value, std::string const & ending);

#endif //CPP_CYPHER_H
