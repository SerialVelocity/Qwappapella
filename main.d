import opencl.all;
import std.stdio;

import Utils;
import Euler.main;
import RayTracer.main;

int main(string[] args) {
  try {
    InitCL();
    menu = new Menu(args);
    auto options = [1 : "Project Euler", 2 : "Ray Tracer", 9 : "Quit"];
    void delegate() cmds[int] = [1 : () => euler(), 2 : () => rayTracer(), 9 : delegate() { return; }];
    menu(options, cmds);
  } catch(Exception e) {
    writeln(e);
    return -1;
  }
  return 0;
}