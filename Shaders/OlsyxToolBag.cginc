
#if !defined(OLSYX_TOOLBAG_INCLUDED)
#define OLSYX_TOOLBAG_INCLUDED

#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

#ifdef GL_ES
precision mediump float;
#endif


// -- USEFUL FUNCTIONS ---------------------------------------------------------------------------------------------------------------------------------------

float StepValue(float originalValue, float attenuation, float steppingFactor) {
	return floor((originalValue * attenuation) * steppingFactor) / steppingFactor;
}


// -- VERTEX ---------------------------------------------------------------------------------------------------------------------------------------------------

void ComputeVertexLightColor(in out float3 vertexLightColor, float3 worldPosition, float3 normal) {
	// #if defined(VERTEXLIGHT_ON)
		vertexLightColor = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, worldPosition, normal
		);
	// #endif
}

float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
}


// -- TEXTURES & MAPS ------------------------------------------------------------------------------------------------------------------------------------------

float GetSmoothness(float4 UV, float smoothnessValue, sampler2D albedoTex, sampler2D metallicMap, bool useSmoothnessAlbedo, bool useMetallicAlbedo, bool useMetallicMap) {
	float texSmoothness = 1;

	if (useSmoothnessAlbedo) {
		texSmoothness = tex2D(albedoTex, UV.xy).a;
	} else if (useMetallicAlbedo && useMetallicMap) {
		texSmoothness = tex2D(metallicMap, UV.xy).a;
	}

	return texSmoothness * smoothnessValue;
}

float3 GetSmoothnessMap(float4 UV, sampler2D albedoTex, sampler2D metallicMap, bool useSmoothnessAlbedo, bool useMetallicAlbedo, bool useMetallicMap) {
	float3 texSmoothness = (1, 1, 1);

	if (useSmoothnessAlbedo) {
		texSmoothness = tex2D(albedoTex, UV.xy);
	} else if (useMetallicAlbedo && useMetallicMap) {
		texSmoothness = tex2D(metallicMap, UV.xy);
	}

	return texSmoothness;
}

float GetMetallic(float4 UV, float metallicValue, sampler2D metallicMap, bool useMetallicMap) {
	if (useMetallicMap) {
		return tex2D(metallicMap, UV.xy).r;
	}
	else {
		return (metallicValue, metallicValue, metallicValue);
	}
}

float3 GetOcclusion(float4 UV, float occlusionStrength, sampler2D occlusionMap) {
	return lerp(1, tex2D(occlusionMap, UV.xy).g, occlusionStrength);
}

float3 GetEmission(float4 UV, sampler2D emissionMap, float emissionValue) {
	return tex2D(emissionMap, UV.xy) * emissionValue;
}

float GetDetailMask(float4 UV, sampler2D detailMask) {
	return tex2D(detailMask, UV.xy).a;
}

float3 CalculateBasicAlbedo(float4 UV, sampler2D mainTexture, sampler2D detailTexture) {
	float3 mainTex = tex2D(mainTexture, UV.xy).rgb;
	float3 detailTex = tex2D(detailTexture, UV.zw).rgb;
	return mainTex * detailTex * unity_ColorSpaceDouble;
}

float3 GetAlbedo(float4 UV, sampler2D mainTexture, sampler2D detailTexture, sampler2D detailMask, float4 tint,  bool useDetailTexture) {
	float3 albedo = tex2D(mainTexture, UV.xy).rgb * tint.rgb;

	if (useDetailTexture) {
		float3 details = tex2D(detailTexture, UV.zw) * unity_ColorSpaceDouble;
		albedo = lerp(albedo, albedo * details, GetDetailMask(UV, detailMask));
	}
		
	return albedo;
}

float GetAlpha(float4 UV, sampler2D mainTexture, float4 tint, bool useSmoothnessAlbedo) {
	float alpha = tint.a;

	if (useSmoothnessAlbedo) {
		alpha *= tex2D(mainTexture, UV.xy).a;
	}

	return alpha;
}


// -- NORMAL MAPS ---------------------------------------------------------------------------------------------------------------------------------------

float3 GetTangentSpaceNormal(float4 UV, sampler2D normalMap, float bumpScale, sampler2D detailNormalMap, float detailMask, float detailBumpScale, bool useNormalMap, bool useDetailNormalMap) {
	/* --- Calculating Bumpiness ---
	float2 deltaU = float2(_HeightMap_TexelSize.x * 0.5, 0);
	float u1 = tex2D(_HeightMap, intp.uv - deltaU);
	float u2 = tex2D(_HeightMap, intp.uv + deltaU);

	float2 deltaV = float2(0, _HeightMap_TexelSize.y * 0.5);
	float v1 = tex2D(_HeightMap, intp.uv - deltaV);
	float v2 = tex2D(_HeightMap, intp.uv + deltaV);
	intp.normal = float3(u1 - u2, 1, v1 - v2);
	*/

	// Normals' map, instead of bump map
	float3 mainNormal = float3(0, 0, 1);
	if (useNormalMap) {	//#if defined(_NORMAL_MAP)
		mainNormal = UnpackScaleNormal(tex2D(normalMap, UV.xy), bumpScale);
	}

	if (useDetailNormalMap) { //#if defined(_DETAIL_NORMAL_MAP)
		float3 detailNormal = UnpackScaleNormal(tex2D(detailNormalMap, UV.zw), detailBumpScale);
		detailNormal = lerp(float3(0, 0, 1), detailNormal, detailMask);
		mainNormal = BlendNormals(mainNormal, detailNormal);
	}

	return mainNormal;
}

float3 CalculateFragmentNormals(float3 normal, float binormal, float4 tangent, float3 tangentSpaceNormal) {
	return normalize(tangentSpaceNormal.x * tangent +
		tangentSpaceNormal.y * binormal +
		tangentSpaceNormal.z * normal
	);
}


// -- LIGHT CALCULATIONS ---------------------------------------------------------------------------------------------------------------------------------------
// --> Unity Lights <--

UnityLight CreateLight(float3 worldPosition, float attenuation, float3 normal) {
	UnityLight light;
	#if defined(DEFERRED_PASS)
		light.dir = float3(0, 1, 0);
		light.color = 0;
	#else
		#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
			light.dir = normalize(_WorldSpaceLightPos0.xyz - worldPosition);
		#else
			light.dir = _WorldSpaceLightPos0.xyz;
		#endif

		float3 lightVec = _WorldSpaceLightPos0.xyz - worldPosition;

		light.color = _LightColor0.rgb * attenuation;
	#endif
	light.ndotl = DotClamped(normal, light.dir);
	return light;
}

float3 BoxProjection(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax) {
	#if UNITY_SPECCUBE_BOX_PROJECTION
		UNITY_BRANCH
		if (cubemapPosition.w > 0) {
			float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
			float scalar = min(min(factors.x, factors.y), factors.z);
			direction = direction * scalar + (position - cubemapPosition);
		}
	#endif
	return direction;
}

UnityIndirect CreateIndirectLight(float3 vertexLightColor, float3 worldPosition, float3 viewDirection, float3 normal, float smoothness, float3 occlusion) {
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	#if defined(VERTEXLIGHT_ON)
		indirectLight.diffuse = vertexLightColor;
	#endif

	#if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
		indirectLight.diffuse += max(0, ShadeSH9(float4(normal, 1)));
		float3 reflectionDirection = reflect(-viewDirection, normal);
		Unity_GlossyEnvironmentData environmentData;

		environmentData.roughness = 1 - smoothness;

		environmentData.reflUVW = BoxProjection(
			reflectionDirection, worldPosition,
			unity_SpecCube0_ProbePosition,
			unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
		);

		float3 probe0 = Unity_GlossyEnvironment(
			UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, environmentData
		);
		
		environmentData.reflUVW = BoxProjection(
			reflectionDirection, worldPosition,
			unity_SpecCube1_ProbePosition,
			unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
		);

		#if UNITY_SPECCUBE_BLENDING
			float interpolator = unity_SpecCube0_BoxMin.w;		
			UNITY_BRANCH
			if (interpolator < 0.99999) {
				float3 probe1 = Unity_GlossyEnvironment(
					UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube0_HDR, environmentData
				);

				indirectLight.specular = lerp(probe1, probe0, interpolator);
			} else {
				indirectLight.specular = probe0;
			}
		#else
			indirectLight.specular = probe0;
		#endif

		indirectLight.diffuse *= occlusion;
		indirectLight.specular *= occlusion;

		#if defined(DEFERRED_PASS) && UNITY_ENABLE_REFLECTION_BUFFERS
			indirectLight.specular = 0;
		#endif
	#endif

	return indirectLight;
}


// --> Hand Calculations <..

float3 GetLightDirection(float3 worldPosition) {
	float3 lightDirection = float3(0, 1, 0);	// Deferred pass
	#if !defined(DEFERRED_PASS)
		#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
			lightDirection.xyz = normalize(_WorldSpaceLightPos0.xyz - worldPosition);
		#else
			lightDirection.xyz = _WorldSpaceLightPos0.xyz;
		#endif
	#endif

	return lightDirection;
}

float GetAttenuation(float3 lightDirection) { 
	// #if defined(SHADOWS_SCREEN)
	//		attenuation = SHADOW_ATTENUATION(intp);
	// #else ...

	float attenuation = 1 / (1 + dot(lightDirection, lightDirection));
	return attenuation;
}

float DiffuseLight(float3 normal, float3 lightDirection) {	// Lambertian Reflection
	float product = clamp(dot(normal, lightDirection), 0.0, 1.0);
	return product;
}

float SpecularLight(float3 normal, float3 lightDirection, float3 viewDirection, float specularPower, float specularQuantity) {
	float reflection = dot(reflect(-lightDirection, normal), viewDirection);
	float specularReflection = pow(max(0.0, reflection), exp2(specularPower));

	return specularReflection * specularQuantity;

}

float3 SpecularContribution(float3 normal, float3 specularColor, float3 lightDirection, float attenuation, float3 viewDirection, float specularPower, float specularQuantity, float steps) { // _SpecularValue, 1
	float specularAmount = SpecularLight(normal, lightDirection, viewDirection, specularPower, specularQuantity);
	float specular = StepValue(specularAmount, attenuation, steps);

	float3 specularContribution = specularColor * specular;
	return specularContribution;
}

float3 DiffuseContribution(float3 normal, float3 diffuseColor, float3 lightDirection, float attenuation, float steps) {
	float diffuseAmount = DiffuseLight(normal, lightDirection);
	float diffuse = StepValue(diffuseAmount, attenuation, steps);

	float3 diffuseContribution = diffuseColor * diffuse;
	return diffuseContribution;
}

float3 BlinnPhongLightModel(float3 worldPosition, float attenuation, float3 specularColor, float3 specularValue, float3 diffuseColor, float3 albedo, float3 normal, out float oneMinusReflectivity) {
	float3 lightDirection = GetLightDirection(worldPosition);
	float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - worldPosition.xyz);
	float nDotL = DotClamped(normal, lightDirection.xyz);	

	oneMinusReflectivity = 1 - attenuation;	
	
	// Ambient Calculations
	float3 ambient = albedo * ShadeSH9(half4(normal, 1.0));

	// Specular Calculations
	float3 specularContribution = SpecularContribution (
		normal, specularColor, lightDirection, attenuation, 
		viewDirection, specularValue, 1, 1000
	);

	float3 lightColor = _LightColor0.rgb  * attenuation; 
		
	// Diffuse Calculations
	float3 diffuseContribution = DiffuseContribution(normal, diffuseColor, lightDirection, attenuation, 1000);

	float3 lightCombination = diffuseContribution + specularContribution;

	float3 color = lightCombination * albedo * lightColor + ambient;
	return color;
}


#endif