//
// Created by Zachary Gray on 8/2/20.
//

#include "interpreter.h"
#include "cypher.h"

int main(int argc, char *argv[]) {
    if (argc < 2) {
        cerr << "Input at least 1 source file to interpret\n";
        terminate();
    }

    vector<string> sources;
    for (int i = 1; i < argc; ++i) {
        sources.emplace_back(argv[i]);
    }

    Cypher{sources, true}.run();

    return 0;
}

