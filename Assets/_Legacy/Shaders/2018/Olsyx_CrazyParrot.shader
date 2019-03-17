
Shader "Olsyx/Legacy/Variations/Crazy Parrot" {
	Properties {

		_Tint("Tint", Color) = (1, 1, 1, 1)
		_MainTex("Albedo", 2D) = "white" {}

		_AlphaCutoff("Alpha Cutoff", Range(0, 1)) = 0.5

		[NoScaleOffset] _NormalMap("Normals", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1

		[NoScaleOffset] _MetallicMap("Metallic", 2D) = "white" {}
		[Gamma] _Metallic("Metallic", Range(0, 1)) = 0
		_Smoothness("Smoothness", Range(0, 1)) = 0.1

		_DetailTex("Detail Albedo", 2D) = "gray" {}
		[NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
		[NoScaleOffset] _DetailMask("Detail Mask", 2D) = "white" {}
		_DetailBumpScale ("Detail Bump Scale", Float) = 1

		[NoScaleOffset] _EmissionMap("Emision", 2D) = "black" {}
		_Emission ("Emission", Color) = (0, 0, 0)

		[NoScaleOffset] _OcclusionMap("Occlusion", 2D) = "white" {}
		_OcclusionStrength("OcclusionStrength", Range(0,1)) = 1

		[HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
		[HideInInspector] _ZWrite("_ZWrite", Float) = 1
			
		// This shader's properties
		_GradientVariation("Gradient Variation", Range(0.0, 1.0)) = 0
		_FinalColor("Final Color", Color) = (0.149, 0.141, 0.912, 1)
	}

	CGINCLUDE

	#define BINORMAL_PER_FRAGMENT

	ENDCG

	SubShader {
			Pass {
				Tags {
					"RenderType" = "Opaque"
					"LightMode" = "ForwardBase"
				}

				Blend [_SrcBlend] [_DstBlend]
			

				CGPROGRAM
				#pragma target 3.0

				// Unity 
				#pragma multi_compile_ _ SHADOWS_SCREEN
				#pragma multi_compile_ _ VERTEXLIGHT_ON
				#pragma multi_compile_fwdadd_fullshadows // Definir luces y cookies renderizables: DIRECTIONAL DIRECTIONAL_COOKIE POINT SPOT 
				#pragma multi_compile _ UNITY_HDR_ON

				// Olsyx
				#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
				#pragma shader_feature _METALLIC_MAP
				#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
				#pragma shader_feature _NORMAL_MAP
				#pragma shader_feature _OCCLUSION_MAP
				#pragma shader_feature _EMISSION_MAP
				#pragma shader_feature _DETAIL_MASK
				#pragma shader_feature _DETAIL_ALBEDO_MAP
				#pragma shader_feature _DETAIL_NORMAL_MAP

				// Crazy Parrot
				#pragma shader_feature _USE_STANDARD_VARIATION

				#pragma vertex OlsyxVertexShader
				#pragma fragment CrazyParrotFragmentShader

				#define FORWARD_BASE_PASS
			
				#include "OlsyxLighting.cginc"

				// Data  ------------------------------------------------------------------------------------------------------------------
				float4 _FinalColor;
				float _GradientVariation;

				// This shader's functions  -----------------------------------------------------------------------------------------------
				float3 GetCustomColor(Interpolators intp) {
					float variation = _GradientVariation;

					#if defined(_USE_STANDARD_VARIATION)
						variation = abs(sin(_Time * 5));
					#endif

					float3 albedo = lerp(_Tint, _FinalColor, variation);
					return albedo;
				}

				FragmentOutput CrazyParrotFragmentShader(Interpolators intp) : SV_TARGET{
					float3 customColor = GetCustomColor(intp);
					float3 customNormals = GetTangentSpaceNormal(intp);
					return OlsyxFragmentWithCustomAttributes(intp, customColor, GetEmission(intp), customNormals, GetSmoothness(intp), GetMetallic(intp), GetOcclusion(intp));
				}


			ENDCG
		}
		Pass {
			Tags{ "LightMode" = "ForwardAdd" }

			Blend [_SrcBlend] One
			ZWrite [_ZWrite]

			CGPROGRAM

			#pragma target 3.0

			// Unity
			#pragma multi_compile_fwdadd_fullshadows

			// Olsyx
			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC

			// Crazy Parrot
			#pragma shader_feature _USE_STANDARD_VARIATION
			
			#pragma vertex OlsyxVertexShader
			#pragma fragment CrazyParrotFragmentShader

			#include "OlsyxLighting.cginc" 

			// Data  ------------------------------------------------------------------------------------------------------------------
			float4 _FinalColor;
			float _GradientVariation;

			// This shader's functions  -----------------------------------------------------------------------------------------------
			float3 GetCustomColor(Interpolators intp) {
				float variation = _GradientVariation;

				#if defined(_USE_STANDARD_VARIATION)
					variation = abs(sin(_Time * 5));
				#endif


				float3 albedo = lerp(_Tint, _FinalColor, variation);
				return albedo;
			}

			FragmentOutput CrazyParrotFragmentShader(Interpolators intp) : SV_TARGET{
				float3 customColor = GetCustomColor(intp);
				float3 customNormals = GetTangentSpaceNormal(intp);
				return OlsyxFragmentWithCustomAttributes(intp, customColor, GetEmission(intp), customNormals, GetSmoothness(intp), GetMetallic(intp), GetOcclusion(intp));
			}
			ENDCG
		}


		Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma target 3.0

			// Unity
			#pragma multi_compile_shadowcaster
			
			// Olsyx
			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO
			#pragma shader_feature _SEMITRANSPARENT_SHADOWS

			#pragma vertex OlsyxShadowVertexShader
			#pragma fragment OlsyxShadowFragmentShader

			#include "OlsyxShadows.cginc"
			
			ENDCG
		}

		Pass {
			Tags {
				"LightMode" = "Deferred"
			}
	
			CGPROGRAM

			#pragma target 3.0
			#pragma exclude_renderers nomrt

			// Olsyx
			#pragma shader_feature _ _RENDERING_CUTOUT
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _OCCLUSION_MAP
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP

			// Crazy Parrot
			#pragma shader_feature _USE_STANDARD_VARIATION

			#pragma vertex OlsyxVertexShader
			#pragma fragment OlsyxFragmentShader

			#define DEFERRED_PASS

			#include "OlsyxLighting.cginc"

			// Data  ------------------------------------------------------------------------------------------------------------------
			float4 _FinalColor;
			float _GradientVariation;

			// This shader's functions  -----------------------------------------------------------------------------------------------
			float3 GetCustomColor(Interpolators intp) {
				float variation = _GradientVariation;

				#if defined(_USE_STANDARD_VARIATION)
					variation = abs(sin(_Time * 5));
				#endif

				float3 albedo = lerp(_Tint, _FinalColor, variation);
				return albedo;
			}

			FragmentOutput CrazyParrotFragmentShader(Interpolators intp) : SV_TARGET{
				float3 customColor = GetCustomColor(intp);
				float3 customNormals = GetTangentSpaceNormal(intp);
				return OlsyxFragmentWithCustomAttributes(intp, customColor, GetEmission(intp), customNormals, GetSmoothness(intp), GetMetallic(intp), GetOcclusion(intp));
			}

			ENDCG
		}
	}

	CustomEditor "OlsyxCrazyParrotGUI"
}
