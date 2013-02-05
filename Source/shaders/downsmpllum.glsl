// Copyright 2013 The Ephenation Authors
//
// This file is part of Ephenation.
//
// Ephenation is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3.
//
// Ephenation is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Ephenation.  If not, see <http://www.gnu.org/licenses/>.

-- Vertex

layout (location=0) in vec2 vertex;
out vec2 screen;                           // Screen coordinate
void main(void)
{
	gl_Position = vec4(vertex*2-1, 0, 1); // Transform from interval 0 to 1, to interval -1 to 1.
	screen = vertex;                         // Copy position to the fragment shader. Only x and y is needed.
}

-- Fragment

uniform sampler2D diffuseTex; // The color information
uniform sampler2D posTex;     // World position
uniform sampler2D normalTex;  // Normals
uniform sampler2D blendTex;   // A bitmap with colors to blend with, afterwars.
uniform sampler2D lightTex;   // A bitmap with colors to blend with, afterwars.
uniform sampler1D poissondisk;
uniform bool Udead;            // True if the player is dead
uniform bool Uwater;           // True when head is in water
uniform bool Uteleport;        // Special mode when inside a teleport
uniform float UwhitePoint = 3.0;
in vec2 screen;               // The screen position
layout(location = 0) out float luminance;

float linearToSRGB(float linear) {
	if (linear <= 0.0031308) return linear * 12.92;
	else return 1.055 * pow(linear, 1/2.4) - 0.055;
}

void main(void)
{
	// Load data, stored in textures, from the first stage rendering.
	vec3 fragColor;
	bool skyPixel = false;
	vec4 normal = texture(normalTex, screen);
	vec4 diffuse = texture(diffuseTex, screen) * 0.95; // Downscale a little, 1.0 can't be mapped to HDR.
	vec4 blend = texture(blendTex, screen);
	vec4 worldPos = texture(posTex, screen);
	if (normal.xyz == vec3(0,0,0)) skyPixel = true;             // No normal, which means sky
	float fact = texture(lightTex, screen).r;
	if (UBODynamicshadows == 0) fact += worldPos.a;         // Add pre computed light instead of using shadow map
	if (skyPixel) { fact = 0.8; }
	vec3 step2 = fact*diffuse.xyz;

	fragColor = (1-blend.a)*step2 + blend.xyz;     // manual blending, using premultiplied alpha.
	//	Add some post processing effects
	fragColor.x = linearToSRGB(fragColor.x);       // Transform to non-linear space
	fragColor.y = linearToSRGB(fragColor.y);       // Transform to non-linear space
	fragColor.z = linearToSRGB(fragColor.z);       // Transform to non-linear space

	luminance = fragColor.r*0.3 + fragColor.g*0.6 + fragColor.b*0.1;
}
