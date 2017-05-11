
#if !defined(OLSYX_DISSOLVE_INCLUDED)
#define OLSYX_DISSOLVE_INCLUDED

#include "OlsyxLighting.cginc"

// Data  ------------------------------------------------------------------------------------------------------------------

float _TransitionValue, _TransitionSpeed;
sampler2D _ColorRamp;
float _TransitionColorAmount;

float4 _FinalTint;
sampler2D _FinalTex, _FinalNormals, _TransitionMask;
float4 _FinalTex_ST;
float _FinalBumpScale;

sampler2D _FinalMetallicMap;
float _FinalMetallic;
float _FinalSmoothness;

sampler2D _FinalOcclusionMap;
float3 _FinalOcclusionStrength;


// Overlapping functions  -------------------------------------------------------------------------------------------------
float3 OverlapAlbedos(float3 mainAlbedo, float3 customAlbedo, float4 mask, float variation) {
	float3 albedo = mainAlbedo;

	#if defined(_OVERLAP_FULL_TEXTURE)
		albedo = lerp(mainAlbedo, mainAlbedo * (1 - mask.rgb) + customAlbedo * mask.rgb, variation);
	#elif defined(_OVERLAP_MULTIPLY_TEXTURE)
		albedo = lerp(mainAlbedo, mainAlbedo + mainAlbedo * customAlbedo * unity_ColorSpaceDouble * mask.rgb, variation);
	#endif

	return albedo;
}

float3 OverlapMaps(float3 mainMap, float3 customMap, float4 mask, float variation, bool substitute) {
	// Function that will overlap two visualization textures: Albedos, Metallics, Smoothnesses, Occlusion Maps...
	float3 visualizationMap;

	if (substitute) {
		visualizationMap = lerp(mainMap, mainMap * (1 - mask.rgb) + customMap * mask.rgb, variation);
	} else {
		visualizationMap = lerp(mainMap, mainMap + customMap * mask.rgb, variation);
	}

	return visualizationMap;
}

float3 OverlapNormals(float3 mainNormal, float4 customNormals, float4 mask, float bumpiness, float variation) {		
	float overlapVariation = bumpiness * variation * mask.rgb;
	float3 overlapNormal = UnpackScaleNormal(customNormals, overlapVariation);

	float3 normals = BlendNormals(mainNormal, overlapNormal);
	return normals;
}

FragmentOutput Olsyx_OverlappingTransition_FragmentShader(Interpolators intp) : SV_TARGET {
	float variation = _TransitionValue;

	#if defined(_USE_STANDARD_VARIATION)
		variation = abs(sin(_Time * _TransitionSpeed));
	#endif

	float3 albedo = tex2D(_FinalTex, intp.uv) * _FinalTint;
	float4 mask = tex2D(_TransitionMask, intp.uv);
	float4 normals = tex2D(_FinalNormals, intp.uv.zw);

	float3 customColor = OverlapAlbedos( GetAlbedo(intp), albedo, mask, variation );
	float3 customNormals = OverlapNormals( 
		GetTangentSpaceNormal(intp), normals, mask, _FinalBumpScale, variation
	);

	return OlsyxFragmentWithCustomAttributes(intp, customColor, GetEmission(intp), customNormals, GetSmoothness(intp), GetMetallic(intp), GetOcclusion(intp));
}



// Dissolving functions   -------------------------------------------------------------------------------------------------

float3 GetDissolvingEmission(Interpolators intp, float3 mainEmission, float value, float edge, float clipping) {
	float3 emission = mainEmission;

	if (value >= clipping && value <= edge && clipping > 0 && clipping < 1) {
		emission = tex2D(_ColorRamp, float2(value * (1 / edge - clipping), 0));
	}

	return emission;
}

float3 DissolveMap(float3 mainMap, float3 finalMap, float value, float edge, float clipping) {
	float3 customMap = mainMap;

	if (value >= clipping  && value <= edge) {
		customMap = mainMap * 0.2 + finalMap * 0.8;

	} else if (value > edge) {
		customMap = finalMap;

	} else if (value <= edge) {
		customMap = mainMap;
	}

	return customMap;
}

float3 DissolveColor(Interpolators intp, float3 mainAlbedo, float3 finalAlbedo, float4 mask, float3 emission, float value, float edge, float clipping) {
	float3 albedo = mainAlbedo;
	
	#if !defined(_ADD_COLOR_TO_DISSOLVE) && !defined(_DO_DISSOLVE_CLIPPING)
		return OverlapAlbedos(mainAlbedo, finalAlbedo, mask, value);
	#endif

	#if defined(_ADD_COLOR_TO_DISSOLVE)
		if (value > edge && clipping > 0 && clipping < 1) {
			albedo *= emission;
		}
	#endif 

	#if !defined(_DO_DISSOLVE_CLIPPING)
		albedo = DissolveMap(mainAlbedo, finalAlbedo, value, edge, clipping);

		#if defined(_OVERLAP_MULTIPLY_TEXTURE)
			if (value > edge) {
				albedo = mainAlbedo * albedo * unity_ColorSpaceDouble; 
			}
		#endif
	#endif

	return albedo;
}

FragmentOutput Olsyx_Dissolve_FragmentShader(Interpolators intp) : SV_TARGET {
	float4 mask = tex2D(_TransitionMask, intp.uv);

	float dissolveAmount = _TransitionValue;
	#if defined(_USE_STANDARD_VARIATION)
		dissolveAmount = abs(sin(_Time * _TransitionSpeed));
	#endif

	half clipping = mask.rgb - dissolveAmount;
	#if defined(_DO_DISSOLVE_CLIPPING)
		clip(clipping);
	#endif

	// -- Variation Data
	float colorThreshold = clipping + _TransitionColorAmount;

	// -- Emission
	float3 customEmission = GetEmission(intp);
	#if defined(_ADD_COLOR_TO_DISSOLVE)
		customEmission = GetDissolvingEmission ( intp, customEmission, dissolveAmount, colorThreshold, clipping );
	#endif 

	// -- Color
	float3 mainAlbedo = GetAlbedo(intp);
	float3 finalAlbedo = tex2D(_FinalTex, intp.uv) * _FinalTint;

	float3 customColor = DissolveColor(intp, mainAlbedo, finalAlbedo, mask, customEmission, dissolveAmount, colorThreshold, clipping);

	// -- Normal
	float4 normals = tex2D(_FinalNormals, intp.uv.zw);
	float3 customNormals = OverlapNormals(GetTangentSpaceNormal(intp), normals, (1, 1, 1, 1), _FinalBumpScale, dissolveAmount);

	// -- Smoothness, Metallic, Occlusion
	bool useSmoothnessAlbedo = false;
	bool useMetallicAlbedo = false;
	bool useMetallicMap = false;
	bool useOcclusionMap = false;

	#if defined(_OVERLAP_SMOOTHNESS_ALBEDO)
		useSmoothnessAlbedo = true;
	#endif

	#if defined(_OVERLAP_SMOOTHNESS_METALLIC)
		useMetallicAlbedo = true;
	#endif

	#if defined(_OVERLAP_METALLIC_MAP)
		useMetallicMap = true;
	#endif

	#if defined(_OVERLAP_OCCLUSION_MAP)
		useOcclusionMap = true;
	#endif

	float3 mainSmoothnessMap = _Smoothness * GetSmoothnessMap(intp);
	float3 finalSmoothnessMap = _FinalSmoothness * GetCustomSmoothnessMap(intp, _FinalTex, _FinalMetallicMap, useSmoothnessAlbedo, useMetallicAlbedo, useMetallicMap);

	float3 mainMetallicMap = GetMetallicMap(intp);
	float3 finalMetallicMap = GetCustomMetallicMap(intp, _FinalMetallic, _FinalMetallicMap, useMetallicMap);

	float3 mainOcclusion = GetOcclusion(intp);
	float3 finalOcclusion = GetCustomOcclusion(intp, _FinalOcclusionStrength, _FinalOcclusionMap, useOcclusionMap);

	float customSmoothness, customMetallic;
	float3 customOcclusion;
	#if !defined(_DO_DISSOLVE_CLIPPING)	
		#if defined(_ADD_COLOR_TO_DISSOLVE)
			customSmoothness = DissolveMap(mainSmoothnessMap, finalSmoothnessMap, dissolveAmount, colorThreshold, clipping);
			customMetallic = DissolveMap(mainMetallicMap, finalMetallicMap, dissolveAmount, colorThreshold, clipping);
			customOcclusion = DissolveMap(mainOcclusion, finalOcclusion, dissolveAmount, colorThreshold, clipping);			
		#else
			customSmoothness = OverlapMaps(mainSmoothnessMap, finalSmoothnessMap, mask, dissolveAmount, true);
			customMetallic = OverlapMaps(mainMetallicMap, finalMetallicMap, mask, dissolveAmount, true);
			customOcclusion = OverlapMaps(mainOcclusion, finalOcclusion, mask, dissolveAmount, true);
		#endif 				
	#else
		customSmoothness = mainSmoothnessMap;
		customMetallic = mainMetallicMap;
		customOcclusion = mainOcclusion;
	#endif

	// -- Final Call
	return OlsyxFragmentWithCustomAttributes(intp, customColor, customEmission, customNormals, customSmoothness, customMetallic, GetOcclusion(intp));
}


#endif