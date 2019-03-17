// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Olsyx/Mixer" {
	Properties{
		_MainTex("", 2D) = "white" {}
	}
		SubShader {
		Pass {
			CGPROGRAM
			sampler2D _MainTex;
			uniform sampler2D _ToMix;

			#pragma vertex MixerVertex
			#pragma fragment MixerFragment	
			#include "UnityCG.cginc"
			
			struct Interpolators {
				float4 position : SV_POSITION;
			};

			Interpolators MixerVertex(appdata_base v) {
				Interpolators intp;
				intp.position = UnityObjectToClipPos(v.vertex);
				return intp;
			}

			float3 MixerFragment(Interpolators input) : COLOR {
				return tex2D(_MainTex, input.position.xy) * tex2D(_ToMix, input.position.xy);
			}

			ENDCG
	}
	}
}
