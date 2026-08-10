#version 330 core
in vec3 vWorldPos;
in vec3 vNormal;
in vec2 vUV;

uniform vec3 uColor;
uniform vec3 uLightDir;
uniform vec3 uLightColor;
uniform vec3 uAmbient;
uniform float uFogDensity;
uniform vec3 uFogColor;
uniform float uUseTexture;
uniform sampler2D uTexture;
uniform float uTime;
uniform vec3 uCamPos;

out vec4 FragColor;

void main() {
    vec3 norm = normalize(vNormal);
    vec3 lightD = normalize(-uLightDir);
    float diff = max(dot(norm, lightD), 0.0);

    vec3 baseColor = uColor;
    if (uUseTexture > 0.5) {
        vec4 texColor = texture(uTexture, vUV);
        baseColor = texColor.rgb * uColor;
    }

    vec3 lighting = uAmbient + uLightColor * diff;
    vec3 result = baseColor * lighting;

    float dist = length(vWorldPos - uCamPos);
    float fogFactor = exp(-uFogDensity * dist);
    fogFactor = clamp(fogFactor, 0.0, 1.0);
    result = mix(uFogColor, result, fogFactor);

    FragColor = vec4(result, 1.0);
}
