module Euler.Problem89;

import Euler.Problems;

import opencl.all;
import std.algorithm;
import std.conv;
import std.file;
import std.stdio;
import std.string;

mixin(AddProblem(89));

class Problem89 : Problem {
  void run(CLInfo info) {
    string[] numbers = to!string(read("Euler/roman.txt")).split("\n");
    ulong numLength = reduce!((x, y) => max(x, y))(map!((x) => x.length)(numbers)) + 1;

    auto program = info.context.createProgram(mixin(CL_PROGRAM_STRING_DEBUG_INFO) ~ "\n#define NUM_LENGTH " ~ to!string(numLength) ~ "\n" ~ q{
        __kernel void problem(__global int *sum, __global char *roman) {
          int tid = get_global_id(0);
          roman += tid * NUM_LENGTH;

          int len = 0;
          int num = 0;

          while(*roman >= 'A') {
            switch(*roman++) {
            case 'M': num += 1000; break;
            case 'D': num += 500;  break;
            case 'C':
              if(*roman == 'D') {
                num += 400;
                ++roman;
                ++len;
              } else if(*roman == 'M') {
                num += 900;
                ++roman;
                ++len;
              } else {
                num += 100;
              }
              break;
            case 'L': num += 50;   break;
            case 'X':
              if(*roman == 'L') {
                num += 40;
                ++roman;
                ++len;
              } else if(*roman == 'C') {
                num += 90;
                ++roman;
                ++len;
              } else {
                num += 10;
              }
              break;
            case 'V': num += 5;    break;
            case 'I':
              if(*roman == 'X') {
                num += 9;
                ++roman;
                ++len;
              } else if(*roman == 'V') {
                num += 4;
                ++roman;
                ++len;
              } else {
                num += 1;
              }
              break;
            default:
              --len;
              break;
            }
            ++len;
          }

          while(num != 0) {
            if(num >= 1000) {
              --len;
              num -= 1000;
            } else if(num >= 900) {
              len -= 2;
              num -= 900;
            } else if(num >= 500) {
              --len;
              num -= 500;
            } else if(num >= 400) {
              len -= 2;
              num -= 400;
            } else if(num >= 100) {
              --len;
              num -= 100;
            } else if(num >= 90) {
              len -= 2;
              num -= 90;
            } else if(num >= 50) {
              --len;
              num -= 50;
            } else if(num >= 40) {
              len -= 2;
              num -= 40;
            } else if(num >= 10) {
              --len;
              num -= 10;
            } else if(num >= 9) {
              len -= 2;
              num -= 9;
            } else if(num >= 5) {
              --len;
              num -= 5;
            } else if(num >= 4) {
              len -= 2;
              num -= 4;
            } else if(num >= 1) {
              --len;
              num -= 1;
            }
          }

          sum[tid] = len;

          barrier(CLK_GLOBAL_MEM_FENCE);

          for(uint s = 1; s < get_global_size(0); s *= 2) {
            if(tid % (2 * s) == 0)
              sum[tid] += sum[tid + s];

            barrier(CLK_GLOBAL_MEM_FENCE);
          }
        }
      });

    program.build("-w -Werror");

    string log = program.buildLog(info.device).strip();
    if(log.length > 0 && log[0] != '\0')
      writefln("Build log: %s", log);

    int[] sum = new int[numbers.length];
    char[] chars = new char[numLength * numbers.length];

    foreach(i, num; numbers) {
      int j = 0;
      for(j = 0; j < num.length; ++j)
        chars[i * numLength + j] = num[j];
      for(; j < numLength; ++j)
        chars[i * numLength + j] = '\0';
    }

    auto kernel = CLKernel(program, "problem");
    auto buff = CLBuffer(info.context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, sum.length * sum[0].sizeof, sum.ptr);
    auto buff2 = CLBuffer(info.context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, chars.length * chars[0].sizeof, chars.ptr);

    kernel.setArgs(buff, buff2);

    auto global = NDRange(numbers.length);
    CLEvent execEvent = info.queue.enqueueNDRangeKernel(kernel, global);
    info.queue.flush();
    execEvent.wait();

    info.queue.enqueueReadBuffer(buff, CL_TRUE, 0, sum.length * sum[0].sizeof, sum.ptr);

    writefln("The sum is: %d", sum[0]);
  }

  string name() {
    return "Add all the natural numbers below one thousand that are multiples of 3 or 5.";
  }
}
