import opencl.all;
import std.conv;
import std.stdio;
import std.string;

import CLUtils;
import Euler.main;

int main(string[] args) {
  try {
    auto cl = InitCL();
    writefln("Please select an option:");

    writeln("1. Project Euler");
    writeln("9. Quit");
    write("\n=> ");
    switch(to!int(readln().strip())) {
    case 1:
      euler(cl);
      break;
    default:
      writeln("UNKNOWN");
      break;
    }

  } catch(Exception e) {
    writeln(e);
    return -1;
  }
  return 0;
}