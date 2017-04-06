
#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

#ifdef GL_ES
precision mediump float;
#endif


// Data ------------------------------------------------------------------------------------------------------------------
float4 _Tint;
sampler2D _MainTex, _DetailTex, _DetailMask;
float4 _MainTex_ST, _DetailTex_ST;

sampler2D _NormalMap, _DetailNormalMap;
float _BumpScale, _DetailBumpScale;

float _Reflection;
sampler2D _MetallicMap;
float _Metallic;
float _Smoothness;

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
	float4 uv : TEXCOORD0;	// Main UV in XY, Detal UV in WZ
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
void ComputeVertexLightColor(inout Interpolators intp) {
	#if defined(VERTEXLIGHT_ON)
		/* float3 lightPosition = float3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);

		float3 lightVector = lightPosition - intp.worldPosition;
		float3 lightDirection = normalize(lightVector);
		float ndotl = DotClamped(intp.normal, lightDirection);
		float attenuation = 1 / (1 + dot(lightDirection, lightDirection) * unity_4LightAtten0.x);

		intp.vertexLightColor = unity_LightColor[0].rgb * ndotl * attenuation;*/

		intp.vertexLightColor = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, intp.worldPos, intp.normal
		);
	#endif
}

float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
}

Interpolators OlsyxVertexShader(VertexData v) {
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

	intp.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	intp.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
	//intp.uvDetail = v.uv;

	TRANSFER_SHADOW(intp);

	ComputeVertexLightColor(intp);
	return intp;
}


// FRAGMENT  -------------------------------------------------------------------------------------------------------------

// -- Properties
float  GetSmoothness(Interpolators intp) {
	float smoothness = 1;
	#if defined (_SMOOTHNESS_ALBEDO)
		smoothness = tex2D(_MainTex, intp.uv.xy).a;
	#elif defined (_SMOOTHNESS_METALLIC) && defined (_METALLIC_MAP)
		smoothness = tex2D(_MetallicMap, intp.uv.xy).a;
	#endif

	return smoothness * _Smoothness;
}

float GetMetallic(Interpolators intp) {
	#if defined(_METALLIC_MAP)
		return tex2D(_MetallicMap, intp.uv.xy).r;
	#else
		return _Metallic;
	#endif
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

float3 CalculateBasicAlbedo(Interpolators intp) {
	float3 mainTex = tex2D(_MainTex, intp.uv.xy).rgb;
	float3 detailTex = tex2D(_DetailTex, intp.uv.zw).rgb;
	return mainTex * detailTex * unity_ColorSpaceDouble;
}

float3 GetAlbedo(Interpolators intp) {
	float3 albedo = tex2D(_MainTex, intp.uv.xy).rgb * _Tint.rgb;
	#if defined (_DETAIL_ALBEDO_MAP)
		float3 details = tex2D(_DetailTex, intp.uv.zw) * unity_ColorSpaceDouble;
		albedo = lerp(albedo, albedo * details, GetDetailMask(intp));
	#endif
		
	return albedo;
}

float GetAlpha(Interpolators intp) {
	float alpha = _Tint.a;
	#if !defined(_SMOOTHNESS_ALBEDO)
		alpha *= tex2D(_MainTex, intp.uv.xy).a;
	#endif
	return alpha;
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


// -- Lights

UnityLight CreateLight(Interpolators intp) {
	UnityLight light;
	#if defined(DEFERRED_PASS)
		light.dir = float3(0, 1, 0);
		light.color = 0;
	#else
		#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
			light.dir = normalize(_WorldSpaceLightPos0.xyz - intp.worldPosition);
		#else
			light.dir = _WorldSpaceLightPos0.xyz;
		#endif

		float3 lightVec = _WorldSpaceLightPos0.xyz - intp.worldPosition;
		UNITY_LIGHT_ATTENUATION(attenuation, intp, intp.worldPosition);

		light.color = _LightColor0.rgb * attenuation;
	#endif
	light.ndotl = DotClamped(intp.normal, light.dir);
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

UnityIndirect CreateIndirectLight(Interpolators intp, float3 viewDirection) {
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	#if defined(VERTEXLIGHT_ON)
		indirectLight.diffuse = intp.vertexLightColor;
	#endif

	#if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
		indirectLight.diffuse += max(0, ShadeSH9(float4(intp.normal, 1)));
		float3 reflectionDirection = reflect(-viewDirection, intp.normal);
		Unity_GlossyEnvironmentData environmentData;
		environmentData.roughness = 1 - GetSmoothness(intp);
		environmentData.reflUVW = BoxProjection(
			reflectionDirection, intp.worldPosition,
			unity_SpecCube0_ProbePosition,
			unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
		);

		float3 probe0 = Unity_GlossyEnvironment(
			UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, environmentData
		);
		
		environmentData.reflUVW = BoxProjection(
			reflectionDirection, intp.worldPosition,
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

		float occlusion = GetOcclusion(intp);
		indirectLight.diffuse *= occlusion;
		indirectLight.specular *= occlusion;

		#if defined(DEFERRED_PASS) && UNITY_ENABLE_REFLECTION_BUFFERS
			indirectLight.specular = 0;
		#endif
	#endif

	return indirectLight;
}


// -- Main

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

FragmentOutput OlsyxFragmentShader(Interpolators intp) : SV_TARGET {
	float alpha = GetAlpha(intp);
	#if defined (_RENDERING_CUTOUT)
		clip(alpha - _AlphaCutoff);
	#endif

	CalculateFragmentNormals(intp);

	float3 viewDirection = normalize(_WorldSpaceCameraPos - intp.worldPosition);

	float3 specularTint;
	float oneMinusReflectivity;
	
	float3 albedo = DiffuseAndSpecularFromMetallic (
		GetAlbedo(intp), GetMetallic(intp), specularTint, oneMinusReflectivity
	);

	#if defined(_RENDERING_TRANSPARENT)
		albedo *= alpha;
		alpha = 1 - oneMinusReflectivity + alpha * oneMinusReflectivity;
	#endif

	float4 color = UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, GetSmoothness(intp),
		intp.normal, viewDirection,
		CreateLight(intp), CreateIndirectLight(intp, viewDirection)
	);

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
		output.gBuffer1.rgb = specularTint;
		output.gBuffer1.a = GetOcclusion(intp);
		output.gBuffer2 = float4(intp.normal * 0.5 + 0.5, 1);
		output.gBuffer3 = color;
	#else
		output.color = color;
	#endif
	return output;
}



// -- For Custom Extensions

void CalculateFragmentNormals_AddCustomNormals(inout Interpolators intp, float3 customNormals) {
	float3 tangentSpaceNormal = customNormals;

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


FragmentOutput OlsyxFragmentWithCustomAttributes(Interpolators intp, float3 customColor, float3 customEmission, float3 customNormals) {
	
	float alpha = GetAlpha(intp);
	#if defined (_RENDERING_CUTOUT)
		clip(alpha - _AlphaCutoff);
	#endif

	CalculateFragmentNormals_AddCustomNormals(intp, customNormals);

	float3 viewDirection = normalize(_WorldSpaceCameraPos - intp.worldPosition);

	float3 specularTint;
	float oneMinusReflectivity;
	
	float3 albedo = DiffuseAndSpecularFromMetallic (
		customColor, GetMetallic(intp), specularTint, oneMinusReflectivity
	);

	#if defined(_RENDERING_TRANSPARENT)
		albedo *= alpha;
		alpha = 1 - oneMinusReflectivity + alpha * oneMinusReflectivity;
	#endif

	float4 color = UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, GetSmoothness(intp),
		intp.normal, viewDirection,
		CreateLight(intp), CreateIndirectLight(intp, viewDirection)
	);

	color.rgb += customEmission;
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
		output.gBuffer1.rgb = specularTint;
		output.gBuffer1.a = GetOcclusion(intp);
		output.gBuffer2 = float4(intp.normal * 0.5 + 0.5, 1);
		output.gBuffer3 = color;
	#else
		output.color = color;
	#endif
	return output;
}


#endif