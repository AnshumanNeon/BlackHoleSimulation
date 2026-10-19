#version 330 core

uniform sampler2D iChannel0;
uniform vec3 iResolution;
uniform float iTime;
uniform vec4 iMouse;

out vec4 fragColor;

float hash(float x) { return fract(sin(x)*152754.742); }
float hash(vec2 x) { return hash(x.x + hash(x.y)); }

float value(vec2 p, float f) { // value noice
  float bl = hash(floor(p*f + vec2(0.,0.)));
  float br = hash(floor(p*f + vec2(1.,0.)));
  float tl = hash(floor(p*f + vec2(0.,1.)));
  float tr = hash(floor(p*f + vec2(1.,1.)));
    
  vec2 fr = fract(p*f);    
  fr = (3. - 2.*fr)*fr*fr;	
  float b = mix(bl, br, fr.x);	
  float t = mix(tl, tr, fr.x);
  return mix(b,t, fr.y);
}

vec4 background(vec3 ray) {
  vec2 uv = ray.xy;
  
  if(abs(ray.x) > 0.5)
    uv.x = ray.z;
  else if(abs(ray.y) > 0.5)
    uv.y = ray.z;

  float brightness = value(uv*3.0, 100.0); // stars from noise
  float color = value(uv*2.0, 20.0); 
  brightness = pow(brightness, 256.);
  
  brightness = brightness*100.0;
  brightness = clamp(brightness, 0.0, 1.0);
    
  vec3 stars = brightness * mix(vec3(1.0, 0.6, 0.2), vec3(0.2, 0.6, 1.0), color);

  vec4 nebulae = texture(iChannel0, uv*1.5); // linear filter, repeat,
  nebulae.xyz += nebulae.xxx + nebulae.yyy + nebulae.zzz; //average color
  nebulae.xyz *= 0.25;
  nebulae*= nebulae;
  nebulae*= nebulae;
  nebulae*= nebulae;
  nebulae*= nebulae;

  nebulae.xyz += stars;

  return nebulae;
}

void Rotate(inout vec3 vector, vec2 angle) {
  vector.yz = cos(angle.y) * vector.yz + sin(angle.y) * vec2(-1.0, 1.0) * vector.zy;
  vector.xz = cos(angle.x) * vector.xz + sin(angle.x) * vec2(-1.0, 1.0) * vector.zx;
}

void main() {
  vec2 fragCoord = gl_FragCoord.xy;
  fragColor = vec4(0.0);
  float _Size = 0.3;
    
  vec2 fragCoordRot;
  fragCoordRot.x = fragCoord.x * 0.985 + fragCoord.y * 0.174;
  fragCoordRot.y = fragCoord.y * 0.985 - fragCoord.x * 0.174;
  fragCoordRot += vec2(-0.06, 0.12) * iResolution.xy;
    
  // Set up camera
  vec3 ray = normalize(vec3((fragCoordRot - iResolution.xy * 0.5) / iResolution.x, 1.0)); 
  vec3 pos = vec3(0.0, 0.05, -(20.0 * iMouse.xy / iResolution.y - 10.0) * (20.0 * iMouse.xy / iResolution.y - 10.0) * 0.05); 
  vec2 angle = vec2(iTime * 0.1, 0.2);      
  angle.y = (2.0 * iMouse.y / iResolution.y) * 3.141592 + 0.1 + 3.141592;
            
  float dist = length(pos);
  Rotate(pos, angle);
  angle.xy -= min(0.3 / dist, 3.141592) * vec2(1.0, 0.5);
  Rotate(ray, angle);

  vec4 col = vec4(0.0); 
  vec4 glow = vec4(0.0); 
  vec4 outCol = vec4(100.0);

  for (int disks = 0; disks < 20; disks++) { // Marching loops
    for (int h = 0; h < 6; h++) {
      float dotpos = dot(pos, pos);
      float invDist = inversesqrt(dotpos); 
      float centDist = dotpos * invDist; 	
      float stepDist = 0.92 * abs(pos.y / (ray.y));    
      float farLimit = centDist * 0.5; 
      float closeLimit = centDist * 0.1 + 0.05 * centDist * centDist * (1.0 / _Size); 
      stepDist = min(stepDist, min(farLimit, closeLimit));
                    
      float invDistSqr = invDist * invDist;
      float bendForce = stepDist * invDistSqr * _Size * 0.625;  
      ray = normalize(ray - (bendForce * invDist) * pos);  
      pos += stepDist * ray; 
                    
      glow += vec4(1.2, 1.1, 1.0, 1.0) * (0.01 * stepDist * invDistSqr * invDistSqr * clamp(centDist * 2.0 - 1.2, 0.0, 1.0)); 
    }

    float dist2 = length(pos);

    if (dist2 < _Size * 0.1) { // Sucked into Event Horizon
      outCol = vec4(0.0, 0.0, 0.0, 1.0);
      break;
    }
    else if (dist2 > _Size * 1000.0) { // Escaped system
      vec4 bg = background(ray);
      outCol = vec4(col.rgb * col.a + bg.rgb * (1.0 - col.a) + glow.rgb * (1.0 - col.a), 1.0);       
      break;
    }
    else if (abs(pos.y) <= _Size * 0.002) { // Passing equatorial plane axis (Cleaned up integer constants)
      vec4 diskCol = vec4(1.0, 1.0, 1.0, 0.0);   
      pos.y = 0.0;
      pos += abs(_Size * 0.001 / ray.y) * ray;  
      col = vec4(diskCol.rgb * (1.0 - col.a) + col.rgb, col.a + diskCol.a * (1.0 - col.a));
    }	
  }
       
  // Fallback checking for missed escape metrics
  if (outCol.r == 100.0) {
    outCol = vec4(col.rgb + glow.rgb * (col.a + glow.a), 1.0);
  }

  col = outCol;
  col.xyz = pow(col.xyz, vec3(0.6));
            
  fragColor += col;
}
