Shader "Olsyx/Transition" {
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
		_TransitionSpeed("Transition Speed", Float) = 1
		[NoScaleOffset] _FinalTex("Final Albedo (RGB)", 2D) = "white" {}
		_FinalTint("Final Tint", Color) = (1, 1, 1, 1)
		[NoScaleOffset] _FinalNormals("Final Normals", 2D) = "bump" {}
		_FinalBumpScale("Final Bump Scale", Float) = 1

		[NoScaleOffset] _TransitionMask("Transition Mask (RGB)", 2D) = "white" {}
		[NoScaleOffset] _ColorRamp("Color Ramp (RGB)", 2D) = "white" {}

		_TransitionColorAmount("Transition Color Amount", Range(0.0, 1.0)) = 0.15
		_TransitionValue("Transition Value", Range(0.0, 1.001)) = 0.5
		_TransitionThreshold("Transition Threshold", Range(0, 0.13)) = 0.03
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

			// Olsyx Lighting
			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _OCCLUSION_MAP
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP
		
			// Olsyx Transition
			#pragma shader_feature _DO_DISSOLVE_CLIPPING
			#pragma shader_feature _ADD_COLOR_TO_DISSOLVE
			#pragma shader_feature _USE_STANDARD_VARIATION

			#pragma vertex OlsyxVertexShader
			#pragma fragment Olsyx_Dissolve_FragmentShader

			#define FORWARD_BASE_PASS

			#include "OlsyxTransition.cginc"	


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

			// Olsyx Lighting
			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
		
			// Olsyx Transition
			#pragma shader_feature _DO_DISSOLVE_CLIPPING
			#pragma shader_feature _ADD_COLOR_TO_DISSOLVE
			#pragma shader_feature _USE_STANDARD_VARIATION
						
			#pragma vertex OlsyxVertexShader
			#pragma fragment Olsyx_Dissolve_FragmentShader
			
			#include "OlsyxTransition.cginc"	

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

			// Olsyx Lighting
			#pragma shader_feature _ _RENDERING_CUTOUT
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _OCCLUSION_MAP
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP
			
			// Olsyx Transition
			#pragma shader_feature _DO_DISSOLVE_CLIPPING
			#pragma shader_feature _ADD_COLOR_TO_DISSOLVE
			#pragma shader_feature _USE_STANDARD_VARIATION

			#pragma vertex OlsyxVertexShader
			#pragma fragment Olsyx_Dissolve_FragmentShader
			
			#define DEFERRED_PASS

			#include "OlsyxTransition.cginc"	
			ENDCG
		}
	}

	CustomEditor "OlsyxTransitionGUI"
}