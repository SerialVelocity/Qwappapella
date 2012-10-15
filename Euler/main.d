module Euler.main;

import std.conv;
import std.stdio;
import std.string;

import Euler.Problems;

void euler() {
  string[int] options;
  void delegate()[int] cmds;

  foreach(i, ref problem; problems) {
    options[i] = problem.name();
    cmds[i] = () => problem.run();
  }

  menu(options, cmds);
}