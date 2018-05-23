module matrix_overloaded.app;

import std.getopt;
import std.stdio;

import matrix_overloaded.cuda;

void main(string[] args){
  int option_size;
  string display_flag = "false";	
  getopt(args,
  	"size", &option_size,
  	"display", &display_flag
  	);
  writeln("Matrix Multiplication called");
  call_gemm_routine(display_flag, option_size);
}