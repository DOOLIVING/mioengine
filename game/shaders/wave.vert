#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec2 aUV;

uniform mat4 uMVP;
uniform mat4 uModel;
uniform float uTime;

out vec3 vWorldPos;
out vec3 vNormal;
out vec2 vUV;

void main() {
    vec3 pos = aPos;
    pos.y += sin(uTime * 2.0 + pos.x * 3.0) * 0.1;

    vec4 worldPos = uModel * vec4(pos, 1.0);
    gl_Position = uMVP * vec4(pos, 1.0);
    vWorldPos = worldPos.xyz;
    vNormal = mat3(uModel) * aNormal;
    vUV = aUV;
}
