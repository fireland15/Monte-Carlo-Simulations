#include <iostream>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <curand_kernel.h>
#include <fstream>
#include <vector>
#include <map>
#include <iomanip>

#define ITERATIONS 125000

#define CUDA_CALL(x) do { if((x) != cudaSuccess) { \
    printf("Error at %s:%d\n",__FILE__,__LINE__); \
    return EXIT_FAILURE;}} while(0)

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort = true)
{
	if (code != cudaSuccess)
	{
		fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
		if (abort) exit(code);
	}
}

__global__ void init_cudaRandStates(unsigned long seed, curandState* state)
{
	unsigned long long i = blockDim.x * blockIdx.x + threadIdx.x;
	curand_init(i, i % 1024 + 1 % 37, 0, &state[i]);
}

__global__ void sample_cudaRand(unsigned long long* d_sampledValues, curandState* state) {
	unsigned long i = blockDim.x * blockIdx.x + threadIdx.x;
	curandState localState = state[i];

	for (int j = 0; j < ITERATIONS; j++) {
		float x = curand_uniform(&localState);
		float y = curand_uniform(&localState);
		if ((x * x + y * y) <= 1.0f) {
			d_sampledValues[i]++;
		}
	}
	state[i] = localState;
}

int main(int argc, char** argv)
{
	int blockSize = 512;
	int gridSize = 8192 * 2;
	size_t N = blockSize * gridSize;
	unsigned long long *v = new unsigned long long[N];

	unsigned long long *d_out;
	gpuErrchk(cudaMalloc((void**)&d_out, N * sizeof(unsigned long long)));
	std::cout << "Allocated " << N * sizeof(unsigned long long) << " bytes for output values" << std::endl;
	gpuErrchk(cudaMemset(d_out, 0, N));

	curandState *d_state;
	gpuErrchk(cudaMalloc((void**)&d_state, N * sizeof(curandState)));
	std::cout << "Allocated " << N * sizeof(curandState) << " bytes for curand state" << std::endl;

	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaEventRecord(start);
	// generate random numbers
	init_cudaRandStates<<<gridSize, blockSize>>>(6, d_state);
	cudaEventRecord(stop);
	gpuErrchk(cudaDeviceSynchronize());

	cudaEventSynchronize(stop);
	float milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start, stop);
	std::cout << "Random Number Generator states initialized in " << milliseconds << "ms" << std::endl;

	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaEventRecord(start);
	sample_cudaRand<<<gridSize, blockSize>>>(d_out, d_state);

	cudaEventRecord(stop);
	cudaEventSynchronize(stop);
	milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start, stop);
	std::cout << "PI Estimation Complete in " << milliseconds << "ms" << std::endl;

	gpuErrchk(cudaMemcpy(v, d_out, N * sizeof(unsigned long long), cudaMemcpyDeviceToHost));
	
	/*std::vector<float> uniformSample(v, v + (N));
	std::map<int, int> histogram;

	for (unsigned int i = 0; i < uniformSample.size(); i++) {
		float value = uniformSample[i];
		int bin = floor(value * 100.0f);
		if (histogram.count(bin) == 0) {
			histogram[bin] = 1;
		}
		else {
			histogram[bin]++;
		}
	}*/

	std::vector<unsigned long long> results(v, v + N);
	unsigned long long totalInRadius = 0;
	for (unsigned int i = 0; i < results.size(); i++) {
		totalInRadius += results[i];
	}
	unsigned long long totalPoints = N * ITERATIONS;

	std::cout << "in: " << totalInRadius << std::endl;
	std::cout << "all: " << totalPoints << std::endl;
	std::cout << "pi: " << std::setprecision(10) << 4.0 * totalInRadius / long double(totalPoints) << std::endl;

	/*std::ofstream f("results.csv", std::ios::out);
	if (f.is_open()) {
		for (auto kvp : histogram) {
			f << kvp.first / 100.0f << "," << kvp.second << ",\n";
		}

		f.close();
	}
	else {
		std::cout << "Failed to open 'results.csv'" << std::endl;
	}*/

	cudaFree(d_out);
	delete[] v;

	return 0;
}