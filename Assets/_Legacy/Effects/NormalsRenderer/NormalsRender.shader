// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Olsyx/Camera/Normals Render" {

	SubShader {
		Tags { "RenderType" = "Opaque" }

		Pass {
			CGPROGRAM
				#pragma vertex NormalsVertex
				#pragma fragment NormalsFragment	
				#include "UnityCG.cginc"

				struct v2f {
					float4 position : SV_POSITION;
					float4 screenPosition : TEXCOORD0;
					float3 color : COLOR;
				};

		
				struct Interpolators {
					float4 position : SV_POSITION;
					float4 screenPosition : TEXCOORD0;
					float3 normal : TEXCOORD1;
					float3 color : COLOR;
				};

				//sampler2D _CameraDepthNormalsTexture;

				Interpolators NormalsVertex(appdata_base v) {
					Interpolators intp;
					intp.position = UnityObjectToClipPos(v.vertex);
					intp.screenPosition = ComputeScreenPos(intp.position);
					intp.screenPosition.y = 1 - intp.screenPosition.y;
					//intp.pos = UnityObjectToClipPos(v.vertex);
					
					intp.normal = UnityObjectToWorldNormal(v.normal);
					return intp;
				}

				float3 NormalsFragment(Interpolators input) : COLOR {
					return input.normal;
				}

			ENDCG
		}	
	}
}
