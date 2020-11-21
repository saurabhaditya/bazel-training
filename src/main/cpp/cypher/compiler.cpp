
#include "cypher.h"

int main(int argc, char *argv[]) {
    if (argc < 3) {
        cerr << "Specify output directory and at least 1 source file to run\n";
        terminate();
    }

    string output { argv[1] };
    vector<string> sources(argv + 2, argv + argc);
    Cypher{ std::move(sources), std::move(output), false, CYPHER_OFFSET}.run();
    return 0;
}

