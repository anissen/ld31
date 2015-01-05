
uniform sampler2D tex0;

varying vec2 tcoord;
varying vec4 color;

uniform float time;

void main() {

    vec2 aux = tcoord;
    aux.x = aux.x + (sin(aux.y * time) * 0.1);

    gl_FragColor = texture2D(tex0, aux);

}
