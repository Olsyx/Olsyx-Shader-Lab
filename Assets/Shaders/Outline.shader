Shader "Olsyx/Outline" {
	Properties {
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Bump ("Bump Texture", 2D) = "bump" {}
		_Strength ("Bump Strength", Range(0,10)) = 1
		_Outline("Outline Width", Range(0,1)) = 0.02
		_OutlineColor ("Outline Color", Color) = (0,0,0,1)
	}
	SubShader{
		Tags { "Queue" = "Transparent"}
		ZWrite Off
		CGPROGRAM
			#pragma surface surf Lambert vertex:vert
			float _Outline;
			float4 _OutlineColor;
			sampler2D _MainTex;

			struct Input {
				float2 uv_MainTex;
				float2 uv_Bump;
			};

			void vert(inout appdata_full v) {
				v.vertex.xyz += v.normal * _Outline;
			}

			void surf(Input IN, inout SurfaceOutput o) {
				o.Emission = _OutlineColor.rgb;
			}
		ENDCG

		ZWrite On
		CGPROGRAM
			#pragma surface surf Lambert

			sampler2D _MainTex;
			sampler2D _Bump;
			half _Strength;

			struct Input {
				float2 uv_MainTex;
				float2 uv_Bump;
			};

			void surf(Input IN, inout SurfaceOutput o) {
				o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;
				o.Normal = UnpackNormal(tex2D(_Bump, IN.uv_Bump));
				o.Normal.rg *= _Strength;
			}
		ENDCG
	}
	FallBack "Diffuse"
}

