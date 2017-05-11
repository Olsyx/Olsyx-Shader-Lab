// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Olsyx/Single Lights/Diffuse Light" {
	SubShader {
		Pass {

			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#include "UnityCG.cginc"

			#pragma target 2.0
			#pragma vertex vertexShader
			#pragma fragment fragmentShader

			float4 _LightColor0;

			struct vsIn {
				float4 position : POSITION;
				float3 normal : NORMAL;
			};

			struct vsOut {
				float4 position : SV_POSITION;
				float3 normal : NORMAL;
			};

			vsOut vertexShader(vsIn v) {
				vsOut o;
				o.position = mul(UNITY_MATRIX_MVP, v.position);
				o.normal = normalize(mul(v.normal, unity_WorldToObject));
				return o;
			}

			float4 fragmentShader(vsOut psIn) : SV_Target {
				float4 AmbientLight = UNITY_LIGHTMODEL_AMBIENT;

				float4 LightDirection = normalize(_WorldSpaceLightPos0);

				float4 DiffuseTerm = saturate(dot(LightDirection, psIn.normal));
				float4 DiffuseLight = DiffuseTerm * _LightColor0;

				return AmbientLight + DiffuseLight;
			}

			ENDCG
		}
	}
}

