Shader "Olsyx/Texture Overlap (5.4.x)" {
	Properties{
		// Olsyx Standard Lighting's needed properties		
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
		_OverlapTint("Overlap Tint", Color) = (1, 1, 1, 1)
		[NoScaleOffset] _OverlapTex("Overlap Texture", 2D) = "white" {}
		_OverlapBumpScale("Overlap Bump Scale", Float) = 1
		[NoScaleOffset] _OverlapNormals("Overlap Normals", 2D) = "bump" {}
		[NoScaleOffset] _OverlapMask("Overlap Mask", 2D) = "white" {}
		_OverlapValue("Overlap Value", Range(0.0, 1.0)) = 0
	}

		CGINCLUDE

		#define ENABLE_DETAILS
		#define BINORMAL_PER_FRAGMENT

			ENDCG

	SubShader{
		Pass {
			Tags {
				"RenderType" = "Opaque"
				"LightMode" = "ForwardBase"
			}

			Blend[_SrcBlend][_DstBlend]


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

			// Texture Overlap
			#pragma shader_feature _USE_STANDARD_VARIATION
			#pragma shader_feature _OVERLAP_FULL_TEXTURE
			#pragma shader_feature _OVERLAP_FULL_NORMALS

			#pragma vertex OlsyxVertexShader
			#pragma fragment TextureOverlapFragmentShader

			#define FORWARD_BASE_PASS

			#include "OlsyxLighting.cginc"


			// Data  ------------------------------------------------------------------------------------------------------------------
			float4 _OverlapTint;
			sampler2D _OverlapTex, _OverlapNormals, _OverlapMask;
			float _OverlapBumpScale, _OverlapValue;


			// This shader's functions  -----------------------------------------------------------------------------------------------

			float3 GetCustomNormals(Interpolators intp) {
				float timeVariation = _OverlapValue;
				
				#if defined(_USE_STANDARD_VARIATION)
					timeVariation = abs(sin(_Time * 5));
				#endif

				float3 mainNormal = GetTangentSpaceNormal(intp);

				float4 overlapMask = tex2D(_OverlapMask, intp.uv);
				float overlapVariation = _OverlapBumpScale * timeVariation * overlapMask.r;
				float3 overlapNormal = UnpackScaleNormal(tex2D(_OverlapNormals, intp.uv.zw), overlapVariation);
				
				float3 customNormal = BlendNormals(mainNormal, overlapNormal);

				return customNormal;
			}

			float3 GetCustomColor(Interpolators intp) {
				float timeVariation = _OverlapValue;
				
				#if defined(_USE_STANDARD_VARIATION)
					timeVariation = abs(sin(_Time * 5));
				#endif
				
				float4 mainTex = tex2D(_MainTex, intp.uv);

				float4 overlapTex = tex2D(_OverlapTex, intp.uv) * _OverlapTint;
				float4 overlapMask = tex2D(_OverlapMask, intp.uv);

				float3 albedo = GetAlbedo(intp);

				#if defined(_OVERLAP_FULL_TEXTURE)
					albedo = lerp(albedo, albedo * (1 - overlapMask.r) + overlapTex * overlapMask.r, timeVariation);
				#elif defined(_OVERLAP_MULTIPLY_TEXTURE)
					// albedo = lerp(albedo, albedo + overlapTex * overlapMask.r, timeVariation);
					albedo = albedo + overlapTex * overlapMask.r * timeVariation;
				#endif

				return albedo; 
			}

			FragmentOutput TextureOverlapFragmentShader(Interpolators intp) : SV_TARGET {
				float3 customColor = GetCustomColor(intp);
				float3 customNormals = GetCustomNormals(intp);
				return OlsyxFragmentWithCustomAttributes(intp, customColor, GetEmission(intp), customNormals);
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
			
			// Texture Overlap
			#pragma shader_feature _USE_STANDARD_VARIATION
			#pragma shader_feature _OVERLAP_FULL_TEXTURE
			#pragma shader_feature _OVERLAP_FULL_NORMALS
			
			#pragma vertex OlsyxVertexShader
			#pragma fragment TextureOverlapFragmentShader

			#include "OlsyxLighting.cginc"
			
			// Data  ------------------------------------------------------------------------------------------------------------------
			float4 _OverlapTint;
			sampler2D _OverlapTex, _OverlapNormals, _OverlapMask;
			float _OverlapBumpScale, _OverlapValue;


			// This shader's functions  -----------------------------------------------------------------------------------------------

			float3 GetCustomNormals(Interpolators intp) {
				float timeVariation = _OverlapValue;
				
				#if defined(_USE_STANDARD_VARIATION)
					timeVariation = abs(sin(_Time * 5));
				#endif

				float3 mainNormal = GetTangentSpaceNormal(intp);

				float4 overlapMask = tex2D(_OverlapMask, intp.uv);
				float overlapVariation = _OverlapBumpScale * timeVariation * overlapMask.r;
				float3 overlapNormal = UnpackScaleNormal(tex2D(_OverlapNormals, intp.uv.zw), overlapVariation);
				
				float3 customNormal = BlendNormals(mainNormal, overlapNormal);

				return customNormal;
			}

			float3 GetCustomColor(Interpolators intp) {
				float timeVariation = _OverlapValue;
				
				#if defined(_USE_STANDARD_VARIATION)
					timeVariation = abs(sin(_Time * 5));
				#endif
				
				float4 mainTex = tex2D(_MainTex, intp.uv);

				float4 overlapTex = tex2D(_OverlapTex, intp.uv) * _OverlapTint;
				float4 overlapMask = tex2D(_OverlapMask, intp.uv);

				float3 albedo = GetAlbedo(intp);

				#if defined(_OVERLAP_FULL_TEXTURE)
					albedo = lerp(albedo, albedo * (1 - overlapMask.r) + overlapTex * overlapMask.r, timeVariation);
				#elif defined(_OVERLAP_MULTIPLY_TEXTURE)
					// albedo = lerp(albedo, albedo + overlapTex * overlapMask.r, timeVariation);
					albedo = albedo + overlapTex * overlapMask.r * timeVariation;
				#endif

				albedo = lerp(albedo, albedo * (1-overlapMask.r) + overlapTex * overlapMask.r, timeVariation);
				return albedo; 
			}

			FragmentOutput TextureOverlapFragmentShader(Interpolators intp) : SV_TARGET {
				float3 customColor = GetCustomColor(intp);
				float3 customNormals = GetCustomNormals(intp);
				return OlsyxFragmentWithCustomAttributes(intp, customColor, GetEmission(intp), customNormals);
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

			// Texture Overlap
			#pragma shader_feature _USE_STANDARD_VARIATION
			#pragma shader_feature _OVERLAP_FULL_TEXTURE
			#pragma shader_feature _OVERLAP_FULL_NORMALS

			#pragma vertex OlsyxVertexShader
			#pragma fragment TextureOverlapFragmentShader

			#define DEFERRED_PASS

			#include "OlsyxLighting.cginc"

			
			// Data  ------------------------------------------------------------------------------------------------------------------
			float4 _OverlapTint;
			sampler2D _OverlapTex, _OverlapNormals, _OverlapMask;
			float _OverlapBumpScale, _OverlapValue;


			// This shader's functions  -----------------------------------------------------------------------------------------------

			float3 GetCustomNormals(Interpolators intp) {
				float timeVariation = _OverlapValue;
				
				#if defined(_USE_STANDARD_VARIATION)
					timeVariation = abs(sin(_Time * 5));
				#endif

				float3 mainNormal = GetTangentSpaceNormal(intp);

				float4 overlapMask = tex2D(_OverlapMask, intp.uv);
				float overlapVariation = _OverlapBumpScale * timeVariation * overlapMask.r;
				float3 overlapNormal = UnpackScaleNormal(tex2D(_OverlapNormals, intp.uv.zw), overlapVariation);

				float3 customNormal = BlendNormals(mainNormal, overlapNormal);

				return customNormal;
			}

			float3 GetCustomColor(Interpolators intp) {
				float timeVariation = _OverlapValue;
				
				#if defined(_USE_STANDARD_VARIATION)
					timeVariation = abs(sin(_Time * 5));
				#endif
				
				float4 mainTex = tex2D(_MainTex, intp.uv);

				float4 overlapTex = tex2D(_OverlapTex, intp.uv) * _OverlapTint;
				float4 overlapMask = tex2D(_OverlapMask, intp.uv);

				float3 albedo = GetAlbedo(intp);

				#if defined(_OVERLAP_FULL_TEXTURE)
					albedo = lerp(albedo, albedo * (1 - overlapMask.r) + overlapTex * overlapMask.r, timeVariation);
				#elif defined(_OVERLAP_MULTIPLY_TEXTURE)
					// albedo = lerp(albedo, albedo + overlapTex * overlapMask.r, timeVariation);
					albedo = albedo + overlapTex * overlapMask.r * timeVariation;
				#endif

				albedo = lerp(albedo, albedo * (1-overlapMask.r) + overlapTex * overlapMask.r, timeVariation);
				return albedo; 
			}

			FragmentOutput TextureOverlapFragmentShader(Interpolators intp) : SV_TARGET {
				float3 customColor = GetCustomColor(intp);
				float3 customNormals = GetCustomNormals(intp);
				return OlsyxFragmentWithCustomAttributes(intp, customColor, GetEmission(intp), customNormals);
			} 

			ENDCG
		}
	}

	CustomEditor "OlsyxTextureOverlapGUI"
}