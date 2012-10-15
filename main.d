import opencl.all;
import std.stdio;

import Utils;
import Euler.main;

int main(string[] args) {
  try {
    InitCL();
    menu = new Menu(args);
    menu([1 : "Project Euler", 9 : "Quit"], [1 : () => euler(), 9 : () { return; }]);
  } catch(Exception e) {
    writeln(e);
    return -1;
  }
  return 0;
}