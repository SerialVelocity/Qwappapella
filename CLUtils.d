module CLUtils;

import opencl.all;
import std.stdio : writeln, writefln;

struct CLInfo {
  CLPlatform platform;
  CLDevice device;
  CLContext context;
  CLCommandQueue queue;
  typeof(CLHost.getPlatforms()) platforms;
  typeof(platform.allDevices()) devices;
}

auto InitCL() {
  CLInfo info;
  info.platforms = CLHost.getPlatforms();

  if (info.platforms.length < 1)
    throw new CLException(CL_INVALID_PLATFORM, "No platforms available.");

  debug foreach(i, platform; info.platforms)
    writefln("[%s] %s\n\t%s\n\t%s\n\t%s\n\t%s", i == 0 ? "*" : " ", platform.name, platform.vendor, platform.clversion, platform.profile, platform.extensions);

  info.platform = info.platforms[0];
  info.devices = info.platform.allDevices;

  if (info.devices.length < 1)
    throw new CLException(CL_INVALID_DEVICE, "No devices available.");

  debug foreach(i, device; devices)
    writefln("[%s] %s\n\t%s\n\t%s\n\t%s\n\t%s", i == 0 ? "*" : " ", device.name, device.vendor, device.driverVersion, device.clVersion, device.profile, device.extensions);

  info.context = CLContext(info.devices);
  info.device = info.devices[0];

  // Create a command queue and use the first device
  info.queue = CLCommandQueue(info.context, info.device);
  return info;
}