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

mat3 rotateX(float theta) {
    float c = cos(theta*0.0174533);
    float s = sin(theta*0.0174533);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

mat3 rotateY(float theta) {
    float c = cos(theta*0.0174533);
    float s = sin(theta*0.0174533);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

mat3 rotateZ(float theta) {
    float c = cos(theta*0.0174533);
    float s = sin(theta*0.0174533);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

mat3 rotate(vec3 rot) {
    return rotateX(rot.x) * rotateY(rot.y) * rotateZ(rot.z); 
}

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
  vec3 q = (abs(p) - b);
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
        p *= rotate(uToruses[i].Rotation);

        float d = sdTorus(p, vec2(uToruses[i].OuterRadius, uToruses[i].InnerRadius));
        vec2 blend = smin(d, dist, blendSoftness);
        dist = blend.x;
        color = mix(uToruses[i].Color, color, blend.y);
    }
    for(int i = 0; i < uNumBoxes; i++) {
        vec3 p = uBoxes[i].Position-position;
        p *= rotate(uBoxes[i].Rotation);

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

#define ENVPWR 0.5
#define FRESNELPWR 2.0
#define SUNPWR 1.0
#define SUNSPECPWR 5.0
#define SSSPWR 0.25

void main() {
    vec3 viewDir = normalize(vPosition - cameraPosition);

    vec3 litPixel = vec3(0,0,0);
    vec3 color = vec3(0,0,0);
    float d = marchScene(cameraPosition, viewDir, color);
    
    if (d < maxDistance)
    {
        vec3 n = calculateNormal(cameraPosition + viewDir * d);    
        vec3 ref = reflect( viewDir, n );

        //Directional light
        {
            vec3  lightDir = normalize( vec3(0.5, 1.0, 0.5) );
            vec3  h = normalize( lightDir-viewDir );
            float diffuse = clamp(0.0, dot( n, lightDir ), 1.0);
            float specular = pow( clamp( dot( n, h ), 0.0, 1.0 ),16.0);
            specular *= diffuse;
            specular *= 0.04+0.96*pow(clamp(1.0-dot(h,lightDir),0.0,1.0),5.0);
        
            litPixel += color*SUNPWR*diffuse;
            litPixel += SUNSPECPWR*specular;
        }

        //Environment light
        {
            float diffuse = sqrt(clamp(0.0, 0.5+0.5*n.y, 1.0 ));
            float specular = smoothstep( -0.2, 0.2, ref.y );
            specular *= diffuse;
            specular *= 0.04+0.96*pow(clamp(1.0+dot(n,viewDir),0.0,1.0), 5.0 );
        
            litPixel += color*ENVPWR*diffuse*uBackgroundColor;
            litPixel += FRESNELPWR*specular*uBackgroundColor;
        }

        //Subsurface scattering
        {
            float diffuse = pow(clamp(1.0+dot(n,viewDir),0.0,1.0),2.0);
        	litPixel += color*SSSPWR*diffuse;
        }

        //Distance fog
        litPixel = mix(litPixel, uBackgroundColor, min(1.0, d / 500.0));
    }
    else 
    {
        litPixel = uBackgroundColor;
    }

    gl_FragColor = vec4(litPixel, 1.0);
}