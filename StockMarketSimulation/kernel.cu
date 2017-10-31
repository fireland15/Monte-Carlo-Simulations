#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <iostream>
#include <string>
#include <fstream>

#include "DataCollection.hpp"

int main(int argc, char** argv) {
	if (argc <= 1) {
		std::cout << "Input files required in arguments" << std::endl;
		return 0;
	}

	std::string filename = argv[1];

	std::fstream f(filename);
	DataCollection data = DataCollection::LoadFromCsvFormattedStream(f);
}