
#if !defined(OLSYX_TOON_SHADER_INCLUDED)
#define OLSYX_TOON_SHADER_INCLUDED

#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
#include "OlsyxToolBag.cginc"

#ifdef GL_ES
precision mediump float;
#endif


// -- DATA ------------------------------------------------------------------------------------------------------------------

float _OutlineThickness;
float4 _OutlineColor; 

float4 _Tint;
sampler2D _MainTex, _DetailTex, _DetailMask;
float4 _MainTex_ST, _DetailTex_ST;

sampler2D _NormalMap, _DetailNormalMap;
float _BumpScale, _DetailBumpScale;

float _SpecularValue, _SpecularSteps, _DiffuseSteps;

sampler2D _ShadingRamp;
float4 _ShadingRamp_ST;

sampler2D _OcclusionMap;
float3 _OcclusionStrength;

sampler2D _EmissionMap;
float3 _Emission;

float _AlphaCutoff;



struct VertexData {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 uv : TEXCOORD0;
};

struct Interpolators {
	float4 pos : SV_POSITION;	// Screen Position
	float4 uv : TEXCOORD0;	// Main UV in XY, Detail UV in WZ
	float3 normal : TEXCOORD1;
		
	float4 tangent : TEXCOORD2;
	#if !defined (BINORMAL_PER_FRAGMENT)
		float4 binormal  : TEXCOORD3;
	#endif

	float3 worldPosition : TEXCOORD4;

	SHADOW_COORDS(5)
		
	#if defined(VERTEXLIGHT_ON)
		float3 vertexLightColor : TEXCOORD6;
	#endif
	
	float4 color : COLOR;	
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


// -- OUTLINER ----------------------------------------------------------------------------------------------------------------

Interpolators OlsyxOutlineVertex(VertexData v)
{
	Interpolators intp;
	#if !defined (_RENDERING_CUTOUT) && !defined (_RENDERING_FADE) 
		intp.pos =  UnityObjectToClipPos(v.vertex + v.normal * _OutlineThickness);
	#else
		intp.pos = UnityObjectToClipPos(v.vertex);
	#endif

	intp.worldPosition = mul(unity_ObjectToWorld, v.vertex);

	intp.normal = UnityObjectToWorldNormal(v.normal);

	intp.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

	intp.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	intp.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
	//intp.uvDetail = v.uv;
	
	TRANSFER_SHADOW(intp);

	intp.color = _OutlineColor;
	return intp;
}

float4 OlsyxOutlineFragment(Interpolators intp) : SV_TARGET{
	
	bool useSmoothnessAlbedo = false;
	#if defined(_SMOOTHNESS_ALBEDO)
		useSmoothnessAlbedo = true;
	#endif

	float alpha = GetAlpha(intp.uv, _MainTex, _Tint, useSmoothnessAlbedo);
	
	#if defined (_RENDERING_CUTOUT)
		clip(alpha - _AlphaCutoff);
	#endif

	float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - intp.worldPosition.xyz);

	#if defined(_RENDERING_TRANSPARENT)
		//intp.color *= alpha;
		alpha = 1 - 1 + alpha * 1;
	#endif

	#if defined(_RENDERING_FADE) || defined(_RENDERING_TRANSPARENT)
		if (dot(intp.normal, viewDirection) < -0.3) {
			intp.color.a = alpha;
		}
	#endif

	return intp.color;
}


// -- TOON SHADING ----------------------------------------------------------------------------------------------------------------

float3 LightCalculations(Interpolators intp, float3 albedo, out float oneMinusReflectivity) {

	float3 lightDirection = GetLightDirection(intp.worldPosition);
	float nDotL = DotClamped(intp.normal, lightDirection.xyz);	

	float attenuation;
	#if defined(SHADOWS_SCREEN)
		attenuation = SHADOW_ATTENUATION(intp);
	#else
		attenuation = GetAttenuation(lightDirection);
	#endif

	oneMinusReflectivity = 1 - attenuation;	
	
	float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - intp.worldPosition.xyz);

	// Ambient Calculations
	float3 ambient = albedo * ShadeSH9(half4(intp.normal, 1.0));

	// Specular Calculations
	float3 specularColor = (1, 1, 1);
	float3 specularContribution = SpecularContribution (
		intp.normal, specularColor, lightDirection, attenuation, 
		viewDirection, _SpecularValue, 1, _SpecularSteps
	);

	float3 lightColor = _LightColor0.rgb  * attenuation; 

	float3 color;
	#if defined(_USE_SHADING_RAMP)
		// Ramp doesn't need diffuse
		half value = nDotL * 0.5 + 0.5;

		value = StepValue(value, 1, _DiffuseSteps);
		float3 ramp = tex2D(_ShadingRamp, float2(value, 0.5)).rgb;

		color = (ramp + specularContribution) * albedo * lightColor + ambient;

	#else
		// Diffuse Calculations
		float3 diffuseColor = (1, 1, 1) * nDotL;
		float3 diffuseContribution = DiffuseContribution(intp.normal, diffuseColor, lightDirection, attenuation, _DiffuseSteps);

		float3 lightCombination = diffuseContribution + specularContribution;

		color = lightCombination * albedo  * lightColor + ambient;
	#endif

	return color;
}


// ----------------------------------------------------------------------------------------------------------------------

Interpolators OlsyxToonVertex(VertexData v) {
	Interpolators intp;

	intp.pos = UnityObjectToClipPos(v.vertex);
	intp.worldPosition = mul(unity_ObjectToWorld, v.vertex);

	intp.normal = UnityObjectToWorldNormal(v.normal);
		
	#if defined(BINORMAL_PER_FRAGMENT)
		intp.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	#else
		intp.tangent = UnityObjectToWorldDir(v.tangent.xyz);
		intp.binormal = CreateBinormal(intp.normal, intp.tangent, v.tangent.w);
	#endif

	//intp.uv.xy = v.uv;
	intp.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	intp.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
	//intp.uvDetail = v.uv;

	TRANSFER_SHADOW(intp);

	#if defined(VERTEXLIGHT_ON)
		ComputeVertexLightColor(in out intp.vertexLightColor, intp.worldPosition, intp.normal);
	#endif
	return intp;
}

FragmentOutput OlsyxToonFragment(Interpolators intp) : SV_TARGET{

	// Clipping Alpha
	float alpha;

	bool useSmoothnessAlbedo = false;
	#if defined(_SMOOTHNESS_ALBEDO)
		useSmoothnessAlbedo = true;
	#endif
	alpha = GetAlpha(intp.uv, _MainTex, _Tint, useSmoothnessAlbedo);
	
	#if defined (_RENDERING_CUTOUT)
		clip(alpha - _AlphaCutoff);
	#endif	
		

	// Normal Maps
	bool useNormalMap = false;
	#if defined(_NORMAL_MAP)
		useNormalMap = true;
	#endif

	bool useDetailNormalMap = false;
	#if defined(_DETAIL_NORMAL_MAP)
		useDetailNormalMap = true;
	#endif

	float detailMask = GetDetailMask(intp.uv, _DetailMask);
	float3 tangentSpaceNormal = GetTangentSpaceNormal(
		intp.uv, _NormalMap, _BumpScale, 
		_DetailNormalMap, detailMask, _DetailBumpScale,
		useNormalMap, useDetailNormalMap
	);

	// Binormals
	float binormal;
	#if defined(BINORMAL_PER_FRAGMENT)
		binormal = CreateBinormal(intp.normal, intp.tangent.xyz, intp.tangent.w);
	#else
		binormal = intp.binormal;
	#endif
	
	intp.normal = CalculateFragmentNormals(intp.normal, binormal, intp.tangent, tangentSpaceNormal);


	// Albedo
	bool useDetailTexture = false;
	#if defined(_DETAIL_ALBEDO_MAP)
		useDetailTexture = true;
	#endif

	float3 albedo = GetAlbedo(intp.uv, _MainTex, _DetailTex, _DetailMask, _Tint, useDetailTexture);
	float oneMinusReflectivity;

	albedo = LightCalculations(intp, albedo, oneMinusReflectivity);;

	#if defined(_RENDERING_TRANSPARENT)
		albedo *= alpha;
		alpha = 1 - oneMinusReflectivity + alpha * oneMinusReflectivity;
	#endif

	float4 color;
	color.rgb = albedo;
	

	// Emission
	#if defined(_EMISSION_MAP)
		color.rgb += GetEmission(intp.uv, _EmissionMap, _Emission);
	#else
		color.rgb += _Emission;
	#endif


	// Alpha - Transparent & Cutouts
	#if defined(_RENDERING_FADE) || defined(_RENDERING_TRANSPARENT)
		color.a = alpha;
	#endif


	// Output
	FragmentOutput output;
	#if defined(DEFERRED_PASS)
		#if !defined(UNITY_HDR_ON)
			color.rgb = exp2(-color.rgb);
		#endif

		output.gBuffer0.rgb = albedo;
		output.gBuffer0.a = GetOcclusion(intp);
		output.gBuffer1.rgb = _SpecularColor;
		output.gBuffer1.a = GetOcclusion(intp);
		output.gBuffer2 = float4(intp.normal * 0.5 + 0.5, 1);
		output.gBuffer3 = color;
	#else
		output.color = color;
	#endif

	return output;
}

#endif