module Euler.main;

import std.conv;
import std.stdio;
import std.string;

import Euler.Problems;

void euler(CLInfo info) {
  writefln("\nPlease select a problem:");

  foreach(i, problem; problems)
    writefln("%d. %s", i, problem.name);

  write("\n=> ");
  int num = to!int(readln().strip());

  if(num in problems)
    problems[num].run(info);
}