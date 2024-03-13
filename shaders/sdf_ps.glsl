varying vec3 vPosition;
varying vec2 vUvs;

const float espM = 0.001;
const float epsN = 0.00001;
const int maxSteps = 100;
const float maxDistance = 10000.0;

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sampleScene(vec3 position)
{
    float s = 10.0;
    vec3 r = position - s*round(position/s);
    //return sdSphere(position, 2.0);
    return sdTorus(r, vec2(2.0, 0.5));
}

float marchScene(vec3 cameraPosition, vec3 viewDir)
{
    float dist = 0.0;
    for (int i = 0; i < maxSteps; ++i) {
        vec3 p = cameraPosition + viewDir * dist;
        float d = sampleScene(p);
        dist += d;
        if (d < espM || dist > maxDistance) {
            return dist;
        }
    }

    return maxDistance;
}

vec3 calculateNormal(vec3 position) {
   //return normalize(vec3(
   //     sampleScene(position + vec3(epsN, 0.0, 0.0)) - sampleScene(position - vec3(epsN, 0.0, 0.0)),
   //     sampleScene(position + vec3(0.0, epsN, 0.0)) - sampleScene(position - vec3(0.0, epsN, 0.0)),
   //     sampleScene(position + vec3(0.0, 0.0, epsN)) - sampleScene(position - vec3(0.0, 0.0, epsN))
   // ));

    //Tetrahedon sampling for 2 less samples
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*sampleScene( position + k.xyy*epsN ) + 
                      k.yyx*sampleScene( position + k.yyx*epsN ) + 
                      k.yxy*sampleScene( position + k.yxy*epsN ) + 
                      k.xxx*sampleScene( position + k.xxx*epsN ) );
}

void main() {
    vec3 viewDir = normalize(vPosition - cameraPosition);

    float d = marchScene(cameraPosition, viewDir);

    vec3 normal = calculateNormal(cameraPosition + viewDir * d);

    vec3 lightDir = normalize(vec3(0.5, 0.5, -1.0));
    float diffuse = max(dot(normal, lightDir), 0.0);

    vec3 color = vec3(0.25);
    color += diffuse; 
    gl_FragColor = vec4(color, step(0.0, min(1.0,maxDistance-d-espM)*length(normal)));
}