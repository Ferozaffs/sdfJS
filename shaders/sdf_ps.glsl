//Functions from https://iquilezles.org/

#define MAX_SDF 50

struct Plane 
{
	vec3 Normal;
	vec3 Color;
    float Height;
};

struct Sphere 
{
	vec3 Position;
	vec3 Color;
    float Radius;
};

struct Torus
{
    vec3 Position;
    vec3 Rotation;
    vec3 Color;
    float InnerRadius;
    float OuterRadius;
};

struct Box
{
    vec3 Position;
    vec3 Rotation;
    vec3 Scale;
    vec3 Color;
};


uniform int uNumSpheres;
uniform Sphere uSpheres[MAX_SDF];

uniform int uNumToruses;
uniform Torus uToruses[MAX_SDF];

uniform int uNumBoxes;
uniform Box uBoxes[MAX_SDF];

uniform vec3 uBackgroundColor;

varying vec3 vPosition;
varying vec2 vUvs;

const float epsM = 0.0001;
const float epsN = 0.00001;
const int maxSteps = 512;
const float maxDistance = 10000.0;
const float blendSoftness = 0.15;

vec2 smin( float a, float b, float k )
{
    float h = 1.0 - min( abs(a-b)/(6.0*k), 1.0 );
    float w = h*h*h;
    float m = w*0.5;
    float s = w*k; 
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

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sampleScene(vec3 position, out vec3 color)
{
    color = vec3(0,0,0);
    float dist = maxDistance;
    
    for(int i = 0; i < uNumSpheres; i++) {
        vec3 p = uSpheres[i].Position-position;

        //Repeats
        //float s = 4.0;
        //vec3 rPos = p;
        //rPos.xy = p.xy - s*round(p.xy/s);

        float d = sdSphere(p, uSpheres[i].Radius);
        vec2 blend = smin(d, dist, blendSoftness);
        dist = blend.x;
        color = mix(uSpheres[i].Color, color, blend.y);
    }
    for(int i = 0; i < uNumToruses; i++) {
        vec3 p = uToruses[i].Position-position;

        float d = sdTorus(p, vec2(uToruses[i].OuterRadius, uToruses[i].InnerRadius));
        vec2 blend = smin(d, dist, blendSoftness);
        dist = blend.x;
        color = mix(uToruses[i].Color, color, blend.y);
    }
    for(int i = 0; i < uNumBoxes; i++) {
        vec3 p = uBoxes[i].Position-position;

        float d = sdBox(p, uBoxes[i].Scale);
        vec2 blend = smin(d, dist, blendSoftness);
        dist = blend.x;
        color = mix(uBoxes[i].Color, color, blend.y);
    }
   
   return dist;
}

float marchScene(vec3 cameraPosition, vec3 viewDir, out vec3 color)
{
    float dist = 0.0;
    for (int i = 0; i < maxSteps; ++i) {
        vec3 p = cameraPosition + viewDir * dist;
        float d = sampleScene(p, color);
        dist += d;
        if (d < epsM ) {
            return dist;
        }
        if ( dist >= maxDistance ) {
            return dist;
        }
    }

    return dist;
}

vec3 calculateNormal(vec3 position) {
    //Standard normal calculation
    //vec3 padding;
    //return normalize(vec3(
    //     sampleScene(position + vec3(epsN, 0.0, 0.0), padding) - sampleScene(position - vec3(epsN, 0.0, 0.0), padding),
    //     sampleScene(position + vec3(0.0, epsN, 0.0), padding) - sampleScene(position - vec3(0.0, epsN, 0.0), padding),
    //     sampleScene(position + vec3(0.0, 0.0, epsN), padding) - sampleScene(position - vec3(0.0, 0.0, epsN), padding)
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

    vec3 color = vec3(0,0,0);
    float d = marchScene(cameraPosition, viewDir, color);

    if (d < maxDistance)
    {
        vec3 normal = calculateNormal(cameraPosition + viewDir * d);
        vec3 lightDir = normalize(vec3(0.5, 0.5, -1.0));
        float diffuse = max(dot(normal, lightDir), 0.0);

        color += diffuse; 

        //Distance fog
        color = mix(color, uBackgroundColor, min(1.0, d / 1000.0));

        gl_FragColor = vec4(color, 1.0);
    }
    else 
    {
        gl_FragColor = vec4(uBackgroundColor, 1.0);
    }
}