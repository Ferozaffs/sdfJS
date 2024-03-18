//Functions from https://iquilezles.org/

#define MAX_SDF 5

struct Sphere 
{
	vec3 Position;
	vec3 Color;
    float Radius;
};

//struct Torus
//{
//    vec3 Position;
//    vec3 Rotation;
//    vec3 Color;
//    //Outer, Inner
//    vec2 Data;
//};

uniform int uNumSpheres;
uniform Sphere uSpheres[3];

//uniform int uNumToruses;
//uniform Torus uToruses[MAX_SDF];

uniform vec3 uBackgroundColor;

varying vec3 vPosition;
varying vec2 vUvs;

const float epsM = 0.001;
const float epsN = 0.00001;
const int maxSteps = 100;
const float maxDistance = 10000.0;
const float blendSoftness = 0.15;

vec2 smin( float a, float b, float k )
{
    k *= 6.0;
    float h = max( k-abs(a-b), 0.0 )/k;
    float m = h*h*h*0.5;
    float s = m*k*(1.0/3.0); 
    return (a<b) ? vec2(a-s,m) : vec2(b-s,1.0-m);
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sampleScene(vec3 position, out vec3 color)
{
    color = vec3(0,0,0);
    float dist = maxDistance;
    for(int i = 0; i < uNumSpheres; i++) {
        vec3 p = uSpheres[i].Position-position;

        float s = 4.0;
        vec3 rPos = p;
        rPos.xy = p.xy - s*round(p.xy/s);

        float d = sdSphere(rPos, uSpheres[i].Radius);
        vec2 blend = smin(d, dist, blendSoftness);
        dist = blend.x;
        color = mix(uSpheres[i].Color, color, blend.y);
    }
    //for(int i = 0; i < uNumToruses; i++) {
    //    d = softMin(d, sdTorus(uToruses[i].Position-position, uToruses[i].Data), blendSoftness);
    //    color = mix(uToruses[i].Color, color, min(1.0, d-epsM));
    //}
   
   return dist;
}

float marchScene(vec3 cameraPosition, vec3 viewDir, inout vec3 color)
{
    float dist = 0.0;
    for (int i = 0; i < maxSteps; ++i) {
        vec3 p = cameraPosition + viewDir * dist;
        vec3 c;
        float d = sampleScene(p, c);
        color = mix(c, color, min(1.0, ceil(d-epsM)));
        dist += d*0.9;
        if (d < epsM || dist > maxDistance) {
            return dist;
        }
    }

    return maxDistance;
}

vec3 calculateNormal(vec3 position) {
   //Standard normal calculation
   //return normalize(vec3(
   //     sampleScene(position + vec3(epsN, 0.0, 0.0)) - sampleScene(position - vec3(epsN, 0.0, 0.0)),
   //     sampleScene(position + vec3(0.0, epsN, 0.0)) - sampleScene(position - vec3(0.0, epsN, 0.0)),
   //     sampleScene(position + vec3(0.0, 0.0, epsN)) - sampleScene(position - vec3(0.0, 0.0, epsN))
   // ));

    //Tetrahedon sampling for 2 less samples
    const vec2 k = vec2(1,-1);
    vec3 padding;
    return normalize( k.xyy*sampleScene( position + k.xyy*epsN, padding) + 
                      k.yyx*sampleScene( position + k.yyx*epsN, padding) + 
                      k.yxy*sampleScene( position + k.yxy*epsN, padding) + 
                      k.xxx*sampleScene( position + k.xxx*epsN, padding));
}

void main() {
    vec3 viewDir = normalize(vPosition - cameraPosition);

    vec3 color = uBackgroundColor;
    float d = marchScene(cameraPosition, viewDir, color);

    vec3 normal = calculateNormal(cameraPosition + viewDir * d);

    vec3 lightDir = normalize(vec3(0.5, 0.5, -1.0));
    float diffuse = max(dot(normal, lightDir), 0.0);

    color += diffuse; 
    gl_FragColor = vec4(color, 1.0);
}