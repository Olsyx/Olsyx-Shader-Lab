// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Olsyx/Single Lights/Ambient Light" {
	Properties {
		_AmbientLightColor("Ambient Light Color", Color) = (1,1,1,1)
		_AmbientLightIntensity("Ambient Light Intensity", Range(0.0, 1.0)) = 1.0
	}

	SubShader {
		Pass {
			CGPROGRAM
			#pragma target 2.0
			#pragma vertex vertexShader
			#pragma fragment fragmentShader

			fixed4 _AmbientLightColor;
			float _AmbientLightIntensity;

			float4 vertexShader(float4 v:POSITION) : SV_POSITION{
				return UnityObjectToClipPos(v);
			}

			fixed4 fragmentShader() : SV_Target{
				return _AmbientLightColor * _AmbientLightIntensity;
			}

			ENDCG
		}
	}
}

