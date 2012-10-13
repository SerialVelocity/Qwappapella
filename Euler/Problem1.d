module Euler.Problem1;

import Euler.Problems;
import std.stdio;

mixin(AddProblem(1));

class Problem1 : Problem {
  this() {
    super(1);
  }

  void run() {
    writefln("Bob");
  }

  string name() {
    return "Add all the natural numbers below one thousand that are multiples of 3 or 5.";
  }
}
