module Utils;

import opencl.all;
import std.conv : to;
import std.stdio : write, writeln, writefln, readln;
import std.string : strip;

CLInfo info;
Menu menu;

struct CLInfo {
  CLPlatform platform;
  CLDevice device;
  CLContext context;
  CLCommandQueue queue;
  typeof(CLHost.getPlatforms()) platforms;
  typeof(platform.allDevices()) devices;
}

auto InitCL() {
  info.platforms = CLHost.getPlatforms();

  if (info.platforms.length < 1)
    throw new CLException(CL_INVALID_PLATFORM, "No platforms available.");

  debug foreach(i, platform; info.platforms)
    writefln("[%s] %s\n\t%s\n\t%s\n\t%s\n\t%s", i == 0 ? "*" : " ", platform.name, platform.vendor, platform.clversion, platform.profile, platform.extensions);

  info.platform = info.platforms[0];
  info.devices = info.platform.allDevices;

  if (info.devices.length < 1)
    throw new CLException(CL_INVALID_DEVICE, "No devices available.");

  debug foreach(i, device; info.devices)
    writefln("[%s] %s\n\t%s\n\t%s\n\t%s\n\t%s", i == 0 ? "*" : " ", device.name, device.vendor, device.driverVersion, device.clVersion, device.profile, device.extensions);

  info.context = CLContext(info.devices);
  info.device = info.devices[0];

  // Create a command queue and use the first device
  info.queue = CLCommandQueue(info.context, info.device);
}

class Menu {
  int[] args;
  this(string[] args) {
    if(args == null || args.length <= 1) {
      this.args.length = 0;
    } else {
      this.args.length = args.length - 1;
      foreach(i, ref arg; args[1..$])
	this.args[i] = to!int(arg);
    }
  }

  void opCall(string[int] options, void delegate()[int] cmds) {
    assert(options.length == cmds.length);

    if(args.length > 0) {
      if(args[0] in cmds) {
	auto arg = args[0];
	args = args[1..$];
	cmds[arg]();
	return;
      } else {
	writefln("Unknown option %d, reverting to user input", args[0]);
	args.length = 0;
      }
    }

    writefln("Please select an option:");

    foreach(i, option; options)
      writefln("%d. %s", i, option);

    write("\n=> ");

    int num = to!int(readln().strip());
    if(num in cmds) {
      cmds[num]();
    }
  }
}