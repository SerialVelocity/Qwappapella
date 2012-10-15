module Euler.Problems;

import std.conv : to;

public import Utils;

import Euler.Problem1;
import Euler.Problem89;

Problem[int] problems;

abstract class Problem {
  void run();

  @property
  string name();
}

static string AddProblem(int i) {
  return "static this() { problems[" ~ to!string(i) ~ "] = new Problem" ~ to!string(i) ~ "(); }";
}