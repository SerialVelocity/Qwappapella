import opencl.all;
import std.stdio;

import CLUtils;

int main(string[] args) {
  try {
    InitCL();
  } catch(Exception e) {
    writeln(e);
    return -1;
  }
  return 0;
}