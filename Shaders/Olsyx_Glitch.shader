Shader "Olsyx/Glitch" {
	Properties {
		[HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
		[HideInInspector] _ZWrite("_ZWrite", Float) = 1
	} 

	SubShader {
		Pass {
			Tags { "LightMode" = "ForwardBase" }

			Blend [_SrcBlend] [_DstBlend]

			CGPROGRAM

			#pragma target 3.0

			#pragma vertex OlsyxToonVertex
			#pragma fragment OlsyxToonFragment

			#define FORWARD_BASE_PASS

			#include "OlsyxGlitch.cginc"

			ENDCG
		}
/*
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
			
			#pragma vertex OlsyxVertexShader
			#pragma fragment OlsyxFragmentShader

			#include "OlsyxToon.cginc"

			ENDCG
		}
*/

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

	
	}
}