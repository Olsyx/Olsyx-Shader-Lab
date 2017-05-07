
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

float _Reflection;
float _Smoothness;

float _Granularity;
sampler2D _ShadingRamp;
float4 _ShadingRamp_ST;
uniform float4 _SpecularTint, _DiffuseColor, _UnlitColor;
uniform float _DiffuseThreshold, _UnlitThreshold;

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
	float4 lightDirection : TEXCOORD2;
	float3 viewDirection : TEXCOORD3;
		
	float4 tangent : TEXCOORD4;
	#if !defined (BINORMAL_PER_FRAGMENT)
		float4 binormal  : TEXCOORD5;
	#endif

	float3 worldPosition : TEXCOORD6;

	SHADOW_COORDS(7)
		
	#if defined(VERTEXLIGHT_ON)
		float3 vertexLightColor : TEXCOORD8;
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
#if !defined(_SMOOTHNESS_ALBEDO)
	alpha *= tex2D(_MainTex, intp.uv.xy).a;
#endif
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

float  GetSmoothness(Interpolators intp) {
	float smoothness = 1;
	#if defined (_SMOOTHNESS_ALBEDO)
		smoothness = tex2D(_MainTex, intp.uv.xy).a;
	#elif defined (_SMOOTHNESS_METALLIC) && defined (_METALLIC_MAP)
		smoothness = tex2D(_MetallicMap, intp.uv.xy).a;
	#endif

	return smoothness * _Smoothness;
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
	intp.viewDirection = normalize(_WorldSpaceCameraPos.xyz - intp.worldPosition.xyz);

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

float3 LightCalculations(Interpolators intp, out float oneMinusReflectivity) {
	float nDotL = DotClamped(intp.normal, intp.lightDirection.xyz);
	float3 combinedLight;

	float attenuation;
	#if defined(SHADOWS_SCREEN)
		attenuation = SHADOW_ATTENUATION(intp);
	#else
		attenuation = 1 / (1 + dot(intp.lightDirection, intp.lightDirection));
	#endif


	#if defined(_USE_SHADING_RAMP)
		half diff = nDotL * 0.5 + 0.5;
		half3 ramp = tex2D(_ShadingRamp, float2(diff,1)).rgb;
		
		combinedLight.rgb = (_LightColor0.rgb * ramp) * (attenuation * _Granularity);
		oneMinusReflectivity = 1 - attenuation;
	#else
		float shininess = _Smoothness;

		// Diffuse threshold calculation
		float diffuseCutoff = saturate((max(_DiffuseThreshold, nDotL) - _DiffuseThreshold) * _Granularity * attenuation);

		// Specular threshold calculation
		float specularCutoff = saturate(max(shininess, dot(reflect(-intp.lightDirection.xyz, intp.normal), intp.viewDirection)) - shininess) * _Granularity * attenuation;

		// Calculate unlit threshold
		float unlitStrength = saturate((dot(intp.normal, intp.viewDirection) - _UnlitThreshold) * _Granularity * attenuation);
		 
		float3 ambientLight = (1 - diffuseCutoff) * unlitStrength * _UnlitColor.xyz; //adds general ambient illumination
		float3 diffuseReflection = (1 - specularCutoff) * _DiffuseColor.xyz * diffuseCutoff;
		float3 specularReflection = _SpecularTint.xyz * specularCutoff;

		combinedLight = (ambientLight + _LightColor0.rgb + diffuseReflection) + specularReflection;
		oneMinusReflectivity = 1 - specularReflection;
	
	#endif
	
	return combinedLight;
}


// ----------------------------------------------------------------------------------------------------------------------

Interpolators OlsyxToonVertex(VertexData v) {
	Interpolators intp;

	intp.pos = UnityObjectToClipPos(v.vertex);
	intp.worldPosition = mul(unity_ObjectToWorld, v.vertex);
	intp.viewDirection = normalize(_WorldSpaceCameraPos.xyz - intp.worldPosition.xyz);

	intp.normal = UnityObjectToWorldNormal(v.normal);
		
	#if defined(BINORMAL_PER_FRAGMENT)
		intp.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	#else
		intp.tangent = UnityObjectToWorldDir(v.tangent.xyz);
		intp.binormal = CreateBinormal(intp.normal, intp.tangent, v.tangent.w);
	#endif

	float3 fragmentToLightSource = (_WorldSpaceCameraPos.xyz - intp.worldPosition.xyz);
	intp.lightDirection = float4(
			normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),		
			lerp(1.0, 1.0 / length(fragmentToLightSource), _WorldSpaceLightPos0.w)
		);


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
	float3 lightReflection = LightCalculations(intp, oneMinusReflectivity);

	#if defined(_RENDERING_TRANSPARENT)
		albedo *= alpha;
		alpha = 1 - oneMinusReflectivity + alpha * oneMinusReflectivity;
	#endif

	float4 color;
	color.rgb = albedo.rgb * lightReflection;

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