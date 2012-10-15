module Euler.Problem1;

import Euler.Problems;

import opencl.all;
import std.stdio;
import std.string;

mixin(AddProblem(1));

const enum SUM_SIZE = 1000;

class Problem1 : Problem {
  void run(CLInfo info) {
    auto program = info.context.createProgram(mixin(CL_PROGRAM_STRING_DEBUG_INFO) ~ q{
        __kernel void problem(__global int *sum) {
          int tid = get_global_id(0);
          if(tid % 3 == 0 || tid % 5 == 0)
            sum[tid] = tid;
          else
            sum[tid] = 0;

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

    int[SUM_SIZE] sum = void;
    auto kernel = CLKernel(program, "problem");
    auto buff = CLBuffer(info.context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, sum.sizeof, sum.ptr);

    kernel.setArgs(buff);

    auto global = NDRange(SUM_SIZE);
    CLEvent execEvent = info.queue.enqueueNDRangeKernel(kernel, global);
    info.queue.flush();
    execEvent.wait();

    info.queue.enqueueReadBuffer(buff, CL_TRUE, 0, sum.sizeof, sum.ptr);

    writefln("The sum is: %d", sum[0]);
  }

  string name() {
    return "Add all the natural numbers below one thousand that are multiples of 3 or 5.";
  }
}
