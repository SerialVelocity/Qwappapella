module RayTracer.main;

import Utils;

import opencl.all;
import std.file : read;

struct TracerInfo {
  int width;
  int height;
  float scale;
  int objectCount;
}

enum ObjectType {
  None = 0,
  Sphere = 1
}

struct RayObject {
  ObjectType type;
  float padding0[3];
  float centre[3];
  float padding1[1];
  float radius;
  bool light;
  float padding2[2];

  this(ObjectType type, float centre[3], float radius, bool light) {
    this.type = type;
    this.centre = centre;
    this.radius = radius;
    this.light = light;
  }
}

void rayTracer() {
  auto program = info.context.createProgram(mixin(CL_PROGRAM_STRING_DEBUG_INFO) ~ "\n" ~ to!string(read("RayTracer/main.cl")));

  program.build("-w -Werror");

  string log = program.buildLog(info.device).strip();
  if(log.length > 0 && log[0] != '\0')
    writefln("Build log: %s", log);

  auto tracerInfo = TracerInfo(640, 480, 480 / 6.0, 4);
  auto tbuff = CLBuffer(info.context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, tracerInfo.sizeof, &tracerInfo);

  auto objects = new RayObject[tracerInfo.objectCount];
  objects[0] = RayObject(ObjectType.Sphere, [ 1.0, -0.8, 3.0], 2.5, false);
  objects[1] = RayObject(ObjectType.Sphere, [-5.5, -0.5, 7.0], 2.0, false);
  objects[2] = RayObject(ObjectType.Sphere, [ 0.0,  5.0, 5.0], 0.1, true);
  objects[3] = RayObject(ObjectType.Sphere, [ 2.0,  5.0, 1.0], 0.1, true);

  auto obuff = CLBuffer(info.context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, objects.length * objects[0].sizeof, objects.ptr);

  auto pixels = new float[3 * tracerInfo.width * tracerInfo.height];
  foreach(ref pixel; pixels)
    pixel = 0.0;

  auto pbuff = CLBuffer(info.context, CL_MEM_WRITE_ONLY | CL_MEM_COPY_HOST_PTR, pixels.length * pixels[0].sizeof, pixels.ptr);

  auto kernel = CLKernel(program, "traceRays");
  auto global = NDRange(tracerInfo.width * tracerInfo.height);

  kernel.setArgs(pbuff, obuff, tbuff);

  CLEvent execEvent = info.queue.enqueueNDRangeKernel(kernel, global);
  info.queue.flush();
  execEvent.wait();

  info.queue.enqueueReadBuffer(pbuff, CL_TRUE, 0, pixels.length * pixels[0].sizeof, pixels.ptr);

  import std.array;
  auto imageFile = appender!(ubyte[])();
  imageFile.put(cast(ubyte)0);
  imageFile.put(cast(ubyte)0);
  imageFile.put(cast(ubyte)2);        /* RGB not compressed */

  imageFile.put(cast(ubyte)0);
  imageFile.put(cast(ubyte)0);
  imageFile.put(cast(ubyte)0);
  imageFile.put(cast(ubyte)0);
  imageFile.put(cast(ubyte)0);

  imageFile.put(cast(ubyte)0);
  imageFile.put(cast(ubyte)0); /* origin X */
  imageFile.put(cast(ubyte)0);
  imageFile.put(cast(ubyte)0); /* origin Y */

  imageFile.put(cast(ubyte)(tracerInfo.width & 0x00FF));
  imageFile.put(cast(ubyte)((tracerInfo.width & 0xFF00) / 256));
  imageFile.put(cast(ubyte)(tracerInfo.height & 0x00FF));
  imageFile.put(cast(ubyte)((tracerInfo.height & 0xFF00) / 256));
  imageFile.put(cast(ubyte)24);       /* 24 bit bitmap */
  imageFile.put(cast(ubyte)0);

  foreach(y; 0..tracerInfo.height) {
    foreach(x; 0..tracerInfo.width) {
      imageFile.put(cast(ubyte)(pixels[(y * tracerInfo.width + x) * 3 + 2]*255));
      imageFile.put(cast(ubyte)(pixels[(y * tracerInfo.width + x) * 3 + 1]*255));
      imageFile.put(cast(ubyte)(pixels[(y * tracerInfo.width + x) * 3 + 0]*255));
    }
  }
  std.file.write("test.tga", imageFile.data);
}