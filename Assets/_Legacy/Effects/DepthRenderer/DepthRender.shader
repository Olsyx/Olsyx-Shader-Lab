// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Olsyx/Camera/Depth Render" {
	SubShader {
		Tags { "RenderType" = "Opaque" }

		Pass {
			CGPROGRAM
				#pragma vertex DepthVertex
				#pragma fragment DepthFragment	
				#include "UnityCG.cginc"

				sampler2D _CameraDepthTexture;

				struct v2f {
					float4 position : SV_POSITION;
					float4 screenPosition : TEXCOORD0;
				};

				v2f DepthVertex(appdata_base v) {
					v2f output;
					output.position = UnityObjectToClipPos(v.vertex);
					output.screenPosition = ComputeScreenPos(output.position);
					return output;
				}

				half4 DepthFragment(v2f input) : COLOR {
					float depthValue = Linear01Depth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(input.screenPosition)).r);
					half4 depth;

					depth.r = depthValue;
					depth.g = depthValue;
					depth.b = depthValue;

					depth.a = 1;
					return depth;
				}

			ENDCG
		}	
	}
}
