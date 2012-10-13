Bmodule CLUtils;

import opencl.all;
import std.stdio : writeln, writefln;

struct CLInfo {
  CLPlatform platform;
  CLDevice device;
  CLContext context;
  CLCommandQueue queue;
}

auto InitCL() {
  CLInfo info;
  auto platforms = CLHost.getPlatforms();

  if (platforms.length < 1)
    throw new CLException(CL_INVALID_PLATFORM, "No platforms available.");

  debug foreach(i, platform; platforms)
      writefln("[%s] %s\n\t%s\n\t%s\n\t%s\n\t%s", i == 0 ? "*" : " ", platform.name, platform.vendor, platform.clversion, platform.profile, platform.extensions);

  info.platform = platforms[0];
  auto devices = info.platform.allDevices;

  if (devices.length < 1)
    throw new CLException(CL_INVALID_DEVICE, "No devices available.");

  debug foreach(i, device; devices)
    writefln("[%s] %s\n\t%s\n\t%s\n\t%s\n\t%s", i == 0 ? "*" : " ", device.name, device.vendor, device.driverVersion, device.clVersion, device.profile, device.extensions);

  info.context = CLContext(devices);
  info.device = devices[0];

  // Create a command queue and use the first device
  info.queue = CLCommandQueue(info.context, info.device);
  return info;
}