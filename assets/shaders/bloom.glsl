#ifdef GL_ES
precision highp float;
#endif

uniform vec2 uResolution;
uniform float uTime;
uniform sampler2D uImage0;
uniform float strength;

void main()
{
   vec4 sum = vec4(0);
   vec2 q = gl_FragCoord.xy / uResolution.xy;
   vec2 uv = 0.5 + (q - 0.5) * (0.9 + 0.1 * sin(0.2 * uTime));
   vec4 oricol = texture2D(uImage0, q);

   for(int i =- 4; i < 4; i++) {
        for (int j=- 3; j < 3; j++) {
            sum += texture2D(uImage0, vec2(j,i) * 0.004 + q) * 0.25;
        }
   }
   gl_FragColor = sum * sum * ((1.0 - oricol.r) / 50.0) * strength + oricol;
   // if (oricol.r < 0.3) {
   //     gl_FragColor = sum * sum * 0.012 + oricol;
   // } else {
   //     if (oricol.r < 0.5) { 
   //        gl_FragColor = sum * sum * 0.009 + oricol; 
   //     } else { 
   //        gl_FragColor = sum * sum * 0.0075 + oricol; 
   //     }
   // }
}
