
#if !defined(OLSYX_TOON_SHADER_INCLUDED)
#define OLSYX_TOON_SHADER_INCLUDED

#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

#ifdef GL_ES
precision mediump float;
#endif

// Data ------------------------------------------------------------------------------------------------------------------
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

// PROPERTIES --------------------------------------------------------------------------------------------------------------

float GetAlpha(Interpolators intp) {
	float alpha = _Tint.a;
	alpha *= tex2D(_MainTex, intp.uv.xy).a;
	return alpha;
}

float3 GetAlbedo(Interpolators intp) {
	float3 albedo = tex2D(_MainTex, intp.uv.xy).rgb * _Tint.rgb;
	#if defined (_DETAIL_ALBEDO_MAP)
		float3 details = tex2D(_DetailTex, intp.uv.zw) * unity_ColorSpaceDouble;
		albedo = lerp(albedo, albedo * details, GetDetailMask(intp));
	#endif
		
	return albedo;
}

float3 GetOcclusion(Interpolators intp) {
	#if defined (_OCCLUSION_MAP)
		return lerp(1, tex2D(_OcclusionMap, intp.uv.xy).g, _OcclusionStrength);
	#else
		return 1;
	#endif
}

float3 GetEmission(Interpolators intp) {
	#if defined (FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
		#if defined (_EMISSION_MAP)
			return tex2D(_EmissionMap, intp.uv.xy) * _Emission;
		#else
			return _Emission;
		#endif
	#else
		return 0;
	#endif
}

float GetDetailMask(Interpolators intp) {
	#if defined (_DETAIL_MASK)
		return tex2D(_DetailMask, intp.uv.xy).a;
	#else
		return 1;
	#endif
}


float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
}

float3 GetTangentSpaceNormal(Interpolators intp) {
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
#if defined(_NORMAL_MAP)
	mainNormal = UnpackScaleNormal(tex2D(_NormalMap, intp.uv.xy), _BumpScale);
#endif

#if defined(_DETAIL_NORMAL_MAP)
	float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, intp.uv.zw), _DetailBumpScale);
	detailNormal = lerp(float3(0, 0, 1), detailNormal, GetDetailMask(intp));
	mainNormal = BlendNormals(mainNormal, detailNormal);
#endif

	return mainNormal;
}

void CalculateFragmentNormals(inout Interpolators intp) {
	float3 tangentSpaceNormal = GetTangentSpaceNormal(intp);

	#if defined(BINORMAL_PER_FRAGMENT)
		float3 binormal = CreateBinormal(intp.normal, intp.tangent.xyz, intp.tangent.w);
	#else
		float3 binormal = intp.binormal;
	#endif

	intp.normal = normalize(tangentSpaceNormal.x * intp.tangent +
		tangentSpaceNormal.y * binormal +
		tangentSpaceNormal.z * intp.normal
	);
}


// OUTLINER ----------------------------------------------------------------------------------------------------------------

Interpolators OlsyxOutlineVertex(VertexData v)
{
	Interpolators intp;

	intp.pos = UnityObjectToClipPos(v.vertex);
	//intp.pos = mul(UNITY_MATRIX_MVP, v.vertex);

	intp.worldPosition = mul(unity_ObjectToWorld, v.vertex);

	intp.normal = UnityObjectToWorldNormal(v.normal);
	intp.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);

	intp.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

	intp.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	intp.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
	//intp.uvDetail = v.uv;

	float widthVariation = 1;
	#if defined(_USE_WIDTH_VARIATION) 
		widthVariation = abs(sin(_Time * 15));
	#endif

	#if !defined (_RENDERING_CUTOUT) && !defined (_RENDERING_FADE) && !defined (_RENDERING_TRANSPARENT)
		float2 offset = TransformViewToProjection(intp.normal.xy);
		intp.pos.xy += offset * _OutlineThickness * widthVariation;
	#endif

	TRANSFER_SHADOW(intp);

	intp.color = _OutlineColor;
	return intp;
}

float4 OlsyxOutlineFragment(Interpolators intp) : SV_TARGET{
	float alpha = GetAlpha(intp);
	#if defined (_RENDERING_CUTOUT)
		clip(alpha - _AlphaCutoff);
	#endif

	#if defined(_RENDERING_TRANSPARENT)
		intp.color *= alpha;
		alpha = 1 - 1 + alpha * 1;
	#endif

	#if defined(_RENDERING_FADE) || defined(_RENDERING_TRANSPARENT)
		intp.color.a = alpha;
	#endif

	return intp.color;
}


// TOON  ----------------------------------------------------------------------------------------------------------------
Interpolators ComputeVertexLightColor(Interpolators intp) {
	#if defined(VERTEXLIGHT_ON)
		intp.vertexLightColor = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, intp.worldPosition, intp.normal
		);
	#endif
	return intp;
}

float3 GetLightDirection(Interpolators intp) {	
	float3 lightDirection = float3(0, 1, 0);	// Deferred pass
	#if !defined(DEFERRED_PASS)
		#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
			lightDirection.xyz = normalize(_WorldSpaceLightPos0.xyz - intp.worldPosition);
		#else
			lightDirection.xyz = _WorldSpaceLightPos0.xyz;
		#endif
	#endif

	return lightDirection;
}

float GetAttenuation(Interpolators intp, float lightDirection) {
	float attenuation;
	#if defined(SHADOWS_SCREEN)
		attenuation = SHADOW_ATTENUATION(intp);
	#else
		attenuation = 1 / (1 + dot(lightDirection, lightDirection));
	#endif
	return attenuation;
}

float DiffuseLight(float3 normal, float3 lightDirection) {	// Lambertian Reflection
	float product = clamp(dot(normal, lightDirection), 0.0, 1.0);
	return product;
}

float SpecularLight(float3 normal, float3 lightDirection, float3 viewDirection, float specularPower, float specularQuantity) {
	float reflection = dot(reflect(-lightDirection, normal), viewDirection);
	float specularReflection = pow(max(0.0, reflection), exp2(specularPower));
	//return specularReflection * specularQuantity;

	//float3 reflected = reflect(viewDirection, normal);
	//float3 halfwayVector = normalize(lightDirection + reflected);
	//float specularReflection = pow(dot(normal, halfwayVector), specularPower);
	return specularReflection * specularQuantity;

}

float StepLight(float light, float attenuation, float steppingFactor) {
	return floor((light * attenuation) * steppingFactor) / steppingFactor;
}

float3 SpecularContribution(float3 normal, float3 specularColor, float3 lightDirection, float attenuation, float3 viewDirection, float specularPower, float specularQuantity, float steps) { // _SpecularValue, 1
	float specularAmount = SpecularLight(normal, lightDirection, viewDirection, specularPower, specularQuantity);
	float specular = StepLight(specularAmount, attenuation, steps);

	float3 specularContribution = specularColor * specular;
	return specularContribution;
}


float3 DiffuseContribution(float3 normal, float3 diffuseColor, float3 lightDirection, float attenuation, float steps) {
	float diffuseAmount = DiffuseLight(normal, lightDirection);
	float diffuse = StepLight(diffuseAmount, attenuation, steps);

	float3 diffuseContribution = diffuseColor * diffuse;
	return diffuseContribution;
}

float3 LightCalculations(Interpolators intp, float3 albedo, out float oneMinusReflectivity) {

	float3 lightDirection = GetLightDirection(intp);
	float nDotL = DotClamped(intp.normal, lightDirection.xyz);	
	float attenuation = GetAttenuation(intp, lightDirection);
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

	float3 color;
	#if defined(_USE_SHADING_RAMP)
		// Ramp doesn't need diffuse
		half value = nDotL * 0.5 + 0.5;

		value = StepLight(value, 1, _DiffuseSteps);
		float3 ramp = tex2D(_ShadingRamp, float2(value, 0.5)).rgb;

		color = (ramp + specularContribution) * albedo * _LightColor0.rgb + ambient;

	#else
		// Diffuse Calculations
		float3 diffuseColor = (1, 1, 1) * nDotL;
		float3 diffuseContribution = DiffuseContribution(intp.normal, diffuseColor, lightDirection, attenuation, _DiffuseSteps);

		float3 lightCombination = diffuseContribution + specularContribution;

		color = lightCombination * albedo  * _LightColor0.rgb + ambient;
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


	ComputeVertexLightColor(intp);
	return intp;
}

FragmentOutput OlsyxToonFragment(Interpolators intp) : SV_TARGET{
	float alpha = GetAlpha(intp);
	#if defined (_RENDERING_CUTOUT)
		clip(alpha - _AlphaCutoff);
	#endif
		
	CalculateFragmentNormals(intp);

	float3 albedo = GetAlbedo(intp);
	float oneMinusReflectivity;

	albedo = LightCalculations(intp, albedo, oneMinusReflectivity);;

	#if defined(_RENDERING_TRANSPARENT)
		albedo *= alpha;
		alpha = 1 - oneMinusReflectivity + alpha * oneMinusReflectivity;
	#endif

	float4 color;
	color.rgb = albedo;
	color.rgb += GetEmission(intp);
	#if defined(_RENDERING_FADE) || defined(_RENDERING_TRANSPARENT)
		color.a = alpha;
	#endif

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