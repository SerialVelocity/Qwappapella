module Euler.Problems;

import std.conv;

public import CLUtils;
import Euler.Problem1;

Problem[int] problems;

abstract class Problem {
  this(int i) {
    problems[i] = this;
  }

  void run(CLInfo info);

  @property
  string name();
}

static string AddProblem(int i) {
  return "static this() { problems[" ~ to!string(i) ~ "] = new Problem" ~ to!string(i) ~ "(); }";
}