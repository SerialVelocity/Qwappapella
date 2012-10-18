module RayTracer.main;

import Utils;

import opencl.all;
import std.file : read;

struct TracerInfo {
  int width;
  int height;
  float scale;
  int objectCount;
  int materialCount;
}

enum ObjectType {
  None = 0,
  Sphere = 1
}

struct Material {
  float colour[3];
  float padding0[1];
  bool light;
  float padding[3];

  this(float colour[3], bool light) {
    this.colour = colour;
    this.light = light;
  }
}

struct RayObject {
  ObjectType type;
  float padding0[3];
  float centre[3];
  float padding1[1];
  float radius;
  int material;
  float padding2[1];
  float padding3[1];

  this(ObjectType type, float centre[3], float radius, int material) {
    this.type = type;
    this.centre = centre;
    this.radius = radius;
    this.material = material;
  }
}

void rayTracer() {
  auto program = info.context.createProgram(mixin(CL_PROGRAM_STRING_DEBUG_INFO) ~ "\n" ~ to!string(read("RayTracer/main.cl")));

  program.build("-w -Werror");

  string log = program.buildLog(info.device).strip();
  if(log.length > 0 && log[0] != '\0')
    writefln("Build log: %s", log);

  auto tracerInfo = TracerInfo(640, 480, 480 / 6.0, 8, 3);
  auto tbuff = CLBuffer(info.context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, tracerInfo.sizeof, &tracerInfo);

  auto materials = new Material[tracerInfo.materialCount];
  materials[0] = Material([1.0, 1.0, 1.0], true);
  materials[1] = Material([1.0, 0.0, 0.0], false);
  materials[2] = Material([0.8, 0.8, 0.8], false);

  auto objects = new RayObject[tracerInfo.objectCount];

  /*
  objects[0] = RayObject(ObjectType.Sphere, [ 1.0, -0.8, 3.0], 2.5, false);
  objects[1] = RayObject(ObjectType.Sphere, [-5.5, -0.5, 7.0], 2.0, false);
  objects[2] = RayObject(ObjectType.Sphere, [ 0.0,  5.0, 5.0], 0.1, true);
  objects[3] = RayObject(ObjectType.Sphere, [ 2.0,  5.0, 1.0], 0.1, true);
  */

  objects[0] = RayObject(ObjectType.Sphere, [10030, 0, 41.6], 10000, 2);
  objects[1] = RayObject(ObjectType.Sphere, [-10030, 0, 41.6], 10000, 2);
  objects[2] = RayObject(ObjectType.Sphere, [0, 0, 10200], 10000, 2);
  objects[3] = RayObject(ObjectType.Sphere, [0, 10025, 41.6], 10000, 2);
  objects[4] = RayObject(ObjectType.Sphere, [0, -10025, 41.6], 10000, 2);
  objects[5] = RayObject(ObjectType.Sphere, [15, -13.5, 110], 8.5, 1);
  objects[6] = RayObject(ObjectType.Sphere, [-15, -13.5, 130], 8.5, 1);
  objects[7] = RayObject(ObjectType.Sphere, [0, 14, 120], 4, 0);

  auto mbuff = CLBuffer(info.context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, materials.length * materials[0].sizeof, materials.ptr);
  auto obuff = CLBuffer(info.context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, objects.length * objects[0].sizeof, objects.ptr);

  auto pixels = new float[3 * tracerInfo.width * tracerInfo.height];
  foreach(ref pixel; pixels)
    pixel = 0.0;

  auto pbuff = CLBuffer(info.context, CL_MEM_WRITE_ONLY | CL_MEM_COPY_HOST_PTR, pixels.length * pixels[0].sizeof, pixels.ptr);

  auto kernel = CLKernel(program, "traceRays");
  auto global = NDRange(tracerInfo.width * tracerInfo.height);

  kernel.setArgs(pbuff, mbuff, obuff, tbuff);

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