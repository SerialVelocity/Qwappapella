typedef struct {
  int width;
  int height;
  float scale;
  int objectCount;
} TracerInfo;

typedef struct {
  float r, g, b;
} Colour;

typedef enum {
  None = 0,
  Sphere = 1
} ObjectType;

typedef struct {
  ObjectType type;
  float3 centre;
  float radius;
  bool light;
} RayObject;

bool object_intersect(__global RayObject *object, float3 camerapos, float3 cameradir, float *t) {
  if(object->type == Sphere) {
    float3 dist = object->centre - camerapos;
    float b = dot(cameradir, dist);
    float d = b * b - dot(dist, dist) + object->radius * object->radius;

    if(d <= 0.0)
      return false;

    float sd = sqrt(d);
    float t0 = b - sd;
    float t1 = b + sd;

    bool ret = false;

    if(t0 >= 0.0001 && t0 < *t) {
      *t = t0;
      ret = true;
    }

    if(t1 >= 0.0001 && t1 < *t) {
      *t = t1;
      ret = true;
    }

    return ret;
  }
  return false;
}

float3 object_normal(__global RayObject *object, float3 hit) {
  if(object->type == Sphere) {
    return normalize(hit - object->centre);
  }
  return (float3)(0.0, 0.0, 0.0);
}

__kernel void main(__global Colour *pixels, __global RayObject *objects, __global TracerInfo *info) {
  float3 colour = (float3)(0.0, 0.0, 0.0);

  //pixels[0].r = sizeof(RayObject);
  //pixels[0].g = sizeof(TracerInfo);

  int tid = get_global_id(0);
  float y = (tid / info->width - info->height / 2) / info->scale;
  float x = (tid % info->width - info->width  / 2) / info->scale;

  //TODO: Take in camera location

  float3 camerapos = (float3)(0.0, 0.0, -5.0);
  float3 screenpos = (float3)(x, y, 0.0);

  float3 cameradir = normalize(screenpos - camerapos);

  float t = 10000000.0;
  __global RayObject *obj = 0;
  for(int i = 0; i < info->objectCount; ++i)
    if(object_intersect(&objects[i], camerapos, cameradir, &t))
      obj = &objects[i];

  if(obj != 0) {
    if(obj->light) {
      colour = (float3)(1.0, 1.0, 1.0);
    } else {
      float3 hit  = camerapos + t * cameradir;
      float3 norm = object_normal(obj, hit);
      float normdot = dot(norm, norm);

      if(normdot != 0) {
	norm *= rsqrt(normdot);

	for(int i = 0; i < info->objectCount; ++i) {
	  if(!objects[i].light)
	    continue;

	  float3 dist = objects[i].centre - hit;
	  float3 distnorm = normalize(dist);

	  if(dot(norm, dist) <= 0.0)
	    continue;

	  float3 raypos = hit;
	  float3 raydir = distnorm;

	  bool inShadow = false;

	  if(!inShadow) {
	    float lambert = dot(raydir, norm);
	    colour += lambert * (float3)(1.0, 1.0, 1.0);
	  }
	}
      }
    }
  }

  pixels[tid].r = min(colour.x, 1.0);
  pixels[tid].g = min(colour.y, 1.0);
  pixels[tid].b = min(colour.z, 1.0);
}
