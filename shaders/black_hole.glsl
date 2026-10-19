#version 330 core

uniform sampler2D iChannel0;

out vec4 fragColor;

vec4 background(vec3 ray) {
  vec2 uv = ray.xy;
  
  if(abs(ray.x) > 0.5)
    uv.x = ray.z;
  else if(abs(ray.y) > 0.5)
    uv.y = ray.z;

  vec4 nebulae = texture(iChannel0, uv*1.5); // linear filter, repeat, Vflip false
  nebulae.xyz += nebulae.xxx + nebulae.yyy + nebulae.zzz; //average color
  nebulae.xyz *= 0.25;
  nebulae*= nebulae;
  nebulae*= nebulae;
  nebulae*= nebulae;
  nebulae*= nebulae;

  return nebulae;
}

void main() {
  vec2 fragCoord = gl_FragCoord.xy;
  float _Size = 0.3; // size of black hole

  // set up camera (move in and up and down using mouse controls)
  vec3 ray = normalize(vec3(fragCoord.xy, 1));
  vec3 pos = vec3(0., 0.05, -3.);
  // do this later

  vec4 col = vec4(0);
  vec4 glow = vec4(0);
  vec4 outCol = vec4(0);

  for(int i=0; i<20; i++) { // steps
    for(int h=0; h<6; h++) {
      float dotpos = dot(pos, pos); // |pos|^2
      float invDist = inversesqrt(dotpos); // inverse of distance to BH
      float centDist = dotpos * invDist; // dist to BH, same as sqrt(dotpos)
      float stepDist = 0.92 * abs(pos.y / ray.y); // conservative distance to disk
      float farLimit = centDist/2; // limit step size far to BH
      float closeLimit = centDist*0.1 + 0.05*centDist*centDist*(1./_Size); // limit step size close to BH
      stepDist = min(stepDist, min(farLimit, closeLimit));

      float invDistSqr = invDist*invDist;
      float bendForce = stepDist*invDistSqr*_Size*0.625; // bending force
      ray = normalize(ray - (bendForce * invDist * pos)); // bend ray towards BH
      pos += stepDist*ray;

      glow += vec4(1.2, 1.1, 1, 1) * (0.01*stepDist * invDistSqr * invDistSqr * clamp(centDist * 2 - 1.2, 0, 1)); // adds glow
    }

    float dist2 = length(pos);
    if(dist2 < _Size * 0.1) { // ray sucked in
      outCol = vec4(0, 0, 0, 1);
      break;
    }

    else if(dist2 > _Size * 1000) { // ray passed
      vec4 bg = background(ray);
      outCol = vec4(col.xyz * col.w + bg.xyz*(1.-col.w) + glow.xyz*(1. - col.w), 1);
      break;
    }
	     
    else if(dist2 <= _Size * 0.002) { // hit accretion disk but i'm not using an accretion disk
      vec4 diskCol = vec4(1, 1, 1, 0);
      pos.y = 0;
      pos += abs(_Size * 0.001/ray.y) * ray;
      col = vec4(diskCol.xyz*(1.-col.w) + col.rgb, col.w + diskCol.w*(1.-col.w));
    }

    if(outCol.x == 100) // never escaped or got sucked in
      outCol = vec4(col.xyz + glow.xyz*(col.w + glow.w), 1);

    col = outCol;
    col.xyz = pow(col.xyz, vec3(0.6));
    fragColor += col;		      
  }
}
