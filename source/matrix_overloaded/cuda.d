module matrix_overloaded.cuda;

import std.stdio;
import core.stdc.stdlib;

import cuda_d.cublas_api;
import cuda_d.cublas_v2;
import cuda_d.cuda;
import cuda_d.cuda_runtime_api;

void gpu_blas_mmul(const double *A, const double *B, double *C, const int m, const int k, const int n) {
  int lda=m,ldb=k,ldc=m;
  const double alf = 1;
  const double bet = 0;
  const double *alpha = &alf;
  const double *beta = &bet;

  // Create a handle for CUBLAS
  cublasHandle_t handle;
  cublasCreate(&handle);

  // Do the actual multiplication
  cublasDgemm(handle, cublasOperation_t.CUBLAS_OP_N, cublasOperation_t.CUBLAS_OP_N, m, n, k, alpha, A, lda, B, ldb, beta, C, ldc);

  // Destroy the handle
  cublasDestroy(handle);
}

void print_matrix(const double *A, int nr_rows_A, int nr_cols_A){
  writeln(A[0]);
}

void print_matrix2(const double *A, int nr_rows_A, int nr_cols_A) {

  for(int i = 0; i < nr_rows_A; ++i){
    for(int j = 0; j < nr_cols_A; ++j){
      write(A[j * nr_rows_A + i], ",\t");
    }
    writeln();
  }
  writeln();
}

void call_gemm_routine(string display_flag, int size = 10){
  // Allocate 3 arrays on CPU
  int nr_rows_A, nr_cols_A, nr_rows_B, nr_cols_B, nr_rows_C, nr_cols_C;

  // for simplicity we are going to use square arrays
  nr_rows_A = nr_cols_A = nr_rows_B = nr_cols_B = nr_rows_C = nr_cols_C = size;

  double* h_A = cast(double*)malloc(double.sizeof * nr_rows_A * nr_cols_A);
  double* h_B = cast(double*)malloc(double.sizeof * nr_rows_B * nr_cols_B);
  double* h_C = cast(double*)malloc(double.sizeof * nr_rows_C * nr_cols_C);

  for(int i = 0; i < size * size; i++){
	h_A[i]  = 6;
	h_B[i]  = 6;
  }
  // Allocate 3 arrays on GPU
  double* d_A, d_B, d_C;
  cudaMalloc(cast(void **)&d_A,nr_rows_A * nr_cols_A * cast(int)double.sizeof);
  cudaMalloc(cast(void **)&d_B,nr_rows_B * nr_cols_B * cast(int)double.sizeof);
  cudaMalloc(cast(void **)&d_C,nr_rows_C * nr_cols_C * cast(int)double.sizeof);


  // Optionally we can copy the data back on CPU and print the arrays
  cudaMemcpy(d_A, h_A, nr_rows_A * nr_cols_A * cast(int)double.sizeof, cudaMemcpyKind.cudaMemcpyHostToDevice);
  cudaMemcpy(d_B, h_B, nr_rows_B * nr_cols_B * cast(int)double.sizeof, cudaMemcpyKind.cudaMemcpyHostToDevice);

  if(display_flag == "true"){
  	writeln( "A =");
  	print_matrix(h_A, nr_rows_A, nr_cols_A);
  	writeln( "B =");
  	print_matrix(h_B, nr_rows_B, nr_cols_B);
  }

  // Multiply A and B on GPU
  gpu_blas_mmul(d_A, d_B, d_C, nr_rows_A, nr_cols_A, nr_cols_B);

  // Copy (and print) the result on host memory
  cudaMemcpy(h_C, d_C, nr_rows_C * nr_cols_C * cast(int)double.sizeof, cudaMemcpyKind.cudaMemcpyDeviceToHost);
  if(display_flag == "true"){
  	writeln( "C =" );
  	print_matrix(h_C, nr_rows_C, nr_cols_C);
  }

  writeln("Success!");
  //Free GPU memory
  cudaFree(d_A);
  cudaFree(d_B);
  cudaFree(d_C);
}