
#if !defined(OLSYX_SHADOWS_INCLUDED)
#define OLSYX_SHADOWS_INCLUDED

#include "UnityCG.cginc"

#if defined (_RENDERING_FADE) || defined(_RENDERING_TRANSPARENT)
	#if defined(_SEMITRANSPARENT_SHADOWS)
		#define SHADOWS_SEMITRANSPARENT 1
	#else
		#define _RENDERING_CUTOUT
	#endif
#endif

#if SHADOWS_SEMITRANSPARENT || defined(_RENDERING_CUTOUT) 
	#if !defined(_SMOOTHNESS_ALBEDO)
		#define SHADOWS_NEED_UV 1
	#endif
#endif

#ifdef GL_ES
precision mediump float;
#endif

// Data ------------------------------------------------------------------------------------------------------------------

float4 _Tint;
sampler2D _MainTex;
float4 _MainTex_ST;
float _AlphaCutoff;

sampler3D _DitherMaskLOD; // Unity Dithering Masks

struct VertexData {
	float4 position : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};

struct InterpolatorsVertex {
	float4 position : SV_POSITION;

	#if SHADOWS_NEED_UV
		float2 uv : TEXCOORD1;
	#endif

	#if defined (SHADOWS_CUBE)
		float3 lightVector : TEXCOORD2;
	#endif
};

struct Interpolators {
	#if SHADOWS_SEMITRANSPARENT
		UNITY_VPOS_TYPE vpos : VPOS;
	#else
		float4 position : SV_POSITION;
	#endif

	#if SHADOWS_NEED_UV
		float2 uv : TEXCOORD1;
	#endif

	#if defined (SHADOWS_CUBE)
		float3 lightVector : TEXCOORD2;
	#endif
};

// Vertex  ----------------------------------------------------------------------------------------------------------------
InterpolatorsVertex OlsyxShadowVertexShader(VertexData v) {
	InterpolatorsVertex intp;
	#if defined(SHADOWS_CUBE)
		intp.position = UnityObjectToClipPos(v.position);
		intp.lightVector = mul(unity_ObjectToWorld, v.position).xyz - _LightPositionRange.xyz;
	#else
		intp.position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
		intp.position = UnityApplyLinearShadowBias(intp.position);
	#endif

	#if (SHADOWS_NEED_UV)
		intp.uv = TRANSFORM_TEX(v.uv, _MainTex);
	#endif
	return intp;
}


// Fragment  -------------------------------------------------------------------------------------------------------------

float GetAlpha(Interpolators intp) {
	float alpha = _Tint.a;
	#if SHADOWS_NEED_UV
		alpha *= tex2D(_MainTex, intp.uv.xy).a;
	#endif
	return alpha;
}

half4 OlsyxShadowFragmentShader(Interpolators intp) : SV_TARGET {
	float alpha = GetAlpha(intp);
	#if defined(_RENDERING_CUTOUT)
		clip(alpha - _AlphaCutoff);
	#endif

	#if SHADOWS_SEMITRANSPARENT
		float dither = tex3D(_DitherMaskLOD, float3(intp.vpos.xy * 0.25, alpha * 0.9375)).a;
		clip(dither - 0.01);
	#endif

	#if defined(SHADOWS_CUBE)
		float depth = length(intp.lightVector) + unity_LightShadowBias.x;
		depth *= _LightPositionRange.w;
		return UnityEncodeCubeShadowDepth(depth);
	#else
		return 0;
	#endif
}


#endif