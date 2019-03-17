

#if !defined(OLSYX_GLITCH_SHADER_INCLUDED)
#define OLSYX_GLITCH_SHADER_INCLUDED

#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

#ifdef GL_ES
precision mediump float;
#endif


// Data ------------------------------------------------------------------------------------------------------------------

struct VertexData {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};

struct Interpolators {
	float4 pos : SV_POSITION;	// Screen Position
	float4 uv : TEXCOORD0;	// Main UV in XY, Detail UV in WZ
	float3 normal : TEXCOORD1;
	float4 lightDirection : TEXCOORD2;
	float3 viewDirection : TEXCOORD3;

	float3 worldPosition : TEXCOORD6;
};

struct FragmentOutput {
	#if defined(DEFERRED_PASS)
		float4 gBuffer0 : SV_Target0;
		float4 gBuffer1 : SV_Target1;
		float4 gBuffer2 : SV_Target2;
		float4 gBuffer3 : SV_Target3;
	#else
		float4 color : SV_Target;
	#endif
};

// VERTEX  ----------------------------------------------------------------------------------------------------------------

Interpolators OlsyxToonVertex(VertexData v) {
	Interpolators intp;

	intp.pos = UnityObjectToClipPos(v.vertex);
	intp.worldPosition = mul(unity_ObjectToWorld, v.vertex);
	intp.normal = UnityObjectToWorldNormal(v.normal);

	TRANSFER_SHADOW(intp);

//	ComputeVertexLightColor(intp);
	return intp;
}


// FRAGMENT  -------------------------------------------------------------------------------------------------------------

// -- Main

half OlsyxToonFragment(Interpolators intp) : SV_TARGET {
	return 0;
}

#endif