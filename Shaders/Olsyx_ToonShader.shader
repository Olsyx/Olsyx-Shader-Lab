Shader "Olsyx/Toon Shader" {
	Properties {
		_OutlineColor("Outline Color", Color) = (1,1,1,1)
		_OutlineThickness("Outline Thickness", Range(0, 1)) = .02

		_Tint("Tint", Color) = (1, 1, 1, 1)
		_MainTex("Albedo", 2D) = "white" {}

		_AlphaCutoff("Alpha Cutoff", Range(0, 1)) = 0.5

		[NoScaleOffset] _NormalMap("Normals", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1
						
		_ShadingRamp("Shading Ramp", 2D) = "gray" {}
			
		_SpecularValue("Specular Value", Range(0, 15)) = 0.1	// Shininess
		_SpecularSteps("Specular Steps", Range(1, 100)) = 1
		_DiffuseSteps("Specular Steps", Range(1, 100)) = 1

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
	} 

CGINCLUDE

#define BINORMAL_PER_FRAGMENT

ENDCG

	SubShader {
		Pass {
			Name "Outline"
			Tags {}

			Cull Front
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			// Olsyx Options
			#define VERTEXCOLOR_ON
			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT

			// This shader options
			//#pragma shader_feature _USE_WIDTH_VARIATION
								
			#pragma vertex OlsyxOutlineVertex
			#pragma fragment OlsyxOutlineFragment

			#include "OlsyxToon.cginc"


			ENDCG		
		}

		Pass {
			Tags { "LightMode" = "ForwardBase" }

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

			#pragma shader_feature _USE_SHADING_RAMP

			#pragma vertex OlsyxToonVertex
			#pragma fragment OlsyxToonFragment

			#define FORWARD_BASE_PASS

			#include "OlsyxToon.cginc"

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

			#pragma shader_feature _USE_SHADING_RAMP
			
			#pragma vertex OlsyxToonVertex
			#pragma fragment OlsyxToonFragment

			#include "OlsyxToon.cginc"

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
			
			#pragma shader_feature _USE_SHADING_RAMP

			#pragma vertex OlsyxVertexShader
			#pragma fragment OlsyxFragmentShader

			#define DEFERRED_PASS

			#include "OlsyxLighting.cginc"

			ENDCG
		}
	
	}

		CustomEditor "OlsyxToonShaderGUI"
}