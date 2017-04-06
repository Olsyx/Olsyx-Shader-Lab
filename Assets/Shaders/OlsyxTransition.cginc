
#if !defined(OLSYX_DISSOLVE_INCLUDED)
#define OLSYX_DISSOLVE_INCLUDED

#include "OlsyxLighting.cginc"

// Data  ------------------------------------------------------------------------------------------------------------------

float4 _FinalTint;
sampler2D _FinalTex, _ColorRamp, _FinalNormals, _TransitionMask;
float4 _FinalTex_ST;
float _TransitionSpeed, _FinalBumpScale, _TransitionColorAmount, _TransitionValue, _TransitionThreshold;


// Overlapping functions  -------------------------------------------------------------------------------------------------

float3 OverlapAlbedos(float3 mainAlbedo, float3 customAlbedo, float4 mask, float variation) {
	float3 albedo = mainAlbedo;

	#if defined(_OVERLAP_FULL_TEXTURE)
		albedo = lerp(albedo, albedo * (1 - mask.rgb) + customAlbedo * mask.rgb, variation);
	#elif defined(_OVERLAP_MULTIPLY_TEXTURE)
		albedo = lerp(albedo, albedo + customAlbedo * mask.rgb, variation);
		//albedo = albedo + overlapTex * overlapMask.r * timeVariation;
	#endif

	return albedo;
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

	return OlsyxFragmentWithCustomAttributes(intp, customColor, GetEmission(intp), customNormals);
}



// Dissolving functions   -------------------------------------------------------------------------------------------------

float3 GetDissolvingEmission(Interpolators intp, float3 mainEmission, half edgeThreshold, float dissolvedThreshold, float colorThreshold, float dissolveAmount) {
	float3 emission = mainEmission;

	#if defined(_ADD_COLOR_TO_DISSOLVE)
		if (edgeThreshold >= dissolvedThreshold && edgeThreshold < colorThreshold && dissolveAmount > 0 && dissolveAmount < 1) {
			emission = tex2D(_ColorRamp, float2(edgeThreshold * (1 / colorThreshold), 0));
		}
	#endif 

	return emission;
}

float3 DissolveColor(Interpolators intp, float3 mainAlbedo, float3 dissolvedAlbedo, float3 emission, half edgeThreshold, float dissolvedThreshold, float colorThreshold, float dissolveAmount) {
	float3 albedo = mainAlbedo;

	#if defined(_ADD_COLOR_TO_DISSOLVE)
		#if defined(_DO_DISSOLVE_CLIPPING)
			if (edgeThreshold < colorThreshold && dissolveAmount > 0 && dissolveAmount < 1) {
				albedo *= emission;
			}
		#else
			if (edgeThreshold > dissolvedThreshold && edgeThreshold < colorThreshold && dissolveAmount > 0 && dissolveAmount < 1) {
				albedo *= emission;
			} else if (edgeThreshold < dissolvedThreshold && dissolveAmount > 0) {
				albedo = dissolvedAlbedo;
			}
		#endif 
	#else
		if (edgeThreshold < dissolvedThreshold && dissolveAmount > 0) {
			albedo = dissolvedAlbedo;
		}
	#endif 

	return albedo;
}

FragmentOutput Olsyx_Dissolve_FragmentShader(Interpolators intp) : SV_TARGET {

	float4 mask = tex2D(_TransitionMask, intp.uv);

	float dissolveAmount = _TransitionValue;
	#if defined(_USE_STANDARD_VARIATION)
		dissolveAmount = abs(sin(_Time * _TransitionSpeed));
	#endif

	half edgeThreshold = mask.rgb - dissolveAmount;
	#if defined(_DO_DISSOLVE_CLIPPING)
		clip(edgeThreshold);
	#endif

	// -- Variation Data
	float dissolvedThreshold = _TransitionThreshold;
	float colorThreshold = _TransitionColorAmount;

	// -- Emission
	float3 customEmission = GetDissolvingEmission(
		intp, GetEmission(intp),
		edgeThreshold, dissolvedThreshold, colorThreshold, dissolveAmount
	);

	// -- Color
	float3 mainAlbedo = GetAlbedo(intp);
	float3 customAlbedo = tex2D(_FinalTex, intp.uv) * _FinalTint;
	float3 finalAlbedo = customAlbedo;// OverlapAlbedos(mainAlbedo, customAlbedo, (0.5, 0.5, 0.5, 0.5), dissolveAmount);

	float3 customColor = DissolveColor (
		intp, 
		mainAlbedo, finalAlbedo, customEmission,
		edgeThreshold, dissolvedThreshold, colorThreshold, dissolveAmount
	);

	// -- Normal
	float4 normals = tex2D(_FinalNormals, intp.uv.zw);
	float3 customNormals = OverlapNormals( GetTangentSpaceNormal(intp), normals, (1,1,1,1), _FinalBumpScale, dissolveAmount );


	// -- Final Call
	return OlsyxFragmentWithCustomAttributes(intp, customColor, customEmission, customNormals);
}


#endif