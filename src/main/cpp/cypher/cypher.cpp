/**
 * Cypher
 *
 * "Compiles" and interprets input files, converting all alphabetical characters to numbers, and vice-versa.
 *
 * Numeric values are shifted by the specified offset (defaults to 1), hence the name "Cypher".
 */

#import "cypher.h"
#include <string>
#include <algorithm>

#include <unistd.h>
#include <stdio.h>

using namespace std;

Cypher::Cypher(vector <string> s, string outdir, bool d, int o, char de) :
        delim(de),
        offset(o),
        decipher_mode(d),
        sources(std::move(s)),
        outdir{std::move(outdir)} {}

void Cypher::run() {
    auto ext = decipher_mode ? input_ext : output_ext;
    auto verb = decipher_mode ? "Interpreting" : "Compiling";
    cout << verb << " " << sources.size() << " source files...\n";
    for (auto &s : sources) {
        auto source_contents = read(s);
        auto trimmed = s.substr(0, s.length() - ext.length() - 1);
        auto path = outdir + "/" + trimmed;
        path += "." + ext;
        ifstream file(path);
        if (file.good() && decipher_mode) {
            // don't overwrite source files
            path = trimmed += "_1." + ext;
        }

        string output;
        if(decipher_mode) {
            output = decipher(source_contents);
        } else {
            output = encipher(source_contents);
        }
        write(path, output);
    }
    cout << "\nDone.\n";
}

string Cypher::encipher(const string &contents) {
    string enciphered;
    for(auto &c : contents) {
        auto pos = get_cipher_position(c);
        enciphered.append(pos == -1 ? string {1, c} : to_string(pos) + delim);
    }
    return enciphered;
}

string Cypher::decipher(const string &contents) {
    // todo: finish, with something like so
//    string deciphered;
//    auto iter = contents.begin();
//    while(iter != contents.end()) {
//        if(*iter != delim) {
//
//        }
//
//        ++iter;
//    }
//    return deciphered;
    return contents;
}

int Cypher::get_cipher_position(char character) {
    if (character >= 'a' && character <= 'z') {
        return character - 'a' + offset;
    } else if (character >= 'A' && character <= 'Z') {
        return character - 'A' + offset;
    }
    return -1;
}

string Cypher::read(const string &path) {
    // could use a faster read here, but overkill
    ifstream file(path);
    if (!file.good()) {
        cerr << "File " << path << " doesn't exist\n";
        terminate();
    }
    if (!ends_with(path, decipher_mode ? output_ext : input_ext)) {
        cerr << "File " << path << " is unsupported.\n";
        terminate();
    }
    return string((istreambuf_iterator<char>(file)), istreambuf_iterator<char>());
}

void Cypher::write(const string &path, const string &contents) {
    ofstream out(path);
    out << contents;
    out.close();

    char cwd[1024];
    getcwd(cwd, sizeof(cwd));

    // bazel debugging:
    ifstream f(path);
    if (f.good()) {
//        cout << "file was written to " << cwd << "/" << path << ": " << contents;
    } else {
        cerr << "file wasn't written to " << path;
    }
    // end bazel debugging
}

inline bool ends_with(std::string const & value, std::string const & ending) {
    if (ending.size() > value.size()) return false;
    return std::equal(ending.rbegin(), ending.rend(), value.rbegin());
}
