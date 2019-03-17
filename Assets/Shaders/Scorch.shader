Shader "Olsyx/Scorch" {
	Properties {
		_Tint("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalMap ("Normal", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1
		
		_MetallicMap("Metallic", 2D) = "white" {}
		[Gamma] _Metallic("Metallic", Range(0, 1)) = 0
		_Smoothness("Smoothness", Range(0, 1)) = 0.1

		_EmissionMap("Emision", 2D) = "black" {}
		_Emission("Emission", Color) = (0, 0, 0)
				
		_Transition("Scorch Step", Range(0.0, 1.0)) = 0.5
		_TransitionWidth("Scorch Line Width", Range(0.0, 1.0)) = 0.1
		[NoScaleOffset] _TransitionMask("Transition Mask (RGB)", 2D) = "white" {}
		[NoScaleOffset] _ColorRamp("Color Ramp (RGB)", 2D) = "white" {}

	}

	SubShader{
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0

		float4 _Tint;
		float4 _Emission;
		float _BumpScale;
		float _Metallic;
		float _Smoothness;
		float _Transition;
		float _TransitionWidth;

		sampler2D _MainTex;
		sampler2D _NormalMap;
		sampler2D _MetallicMap;
		sampler2D _EmissionMap;
		sampler2D _TransitionMask;
		sampler2D _ColorRamp;
		
		struct Input {
			float2 uv_MainTex;
			float2 uv_NormalMap;
			float2 uv_MetallicMap;
			float2 uv_EmissionMap;
		};
		
		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

		float3 GetMask(Input IN) {
			float3 maskTex = tex2D(_TransitionMask, IN.uv_MainTex).rgb;
			float3 white = float3(1, 1, 1);

			maskTex = lerp(white, maskTex, _Transition * 5);

			return maskTex;
		}

		float3 GetAlbedo(Input IN, float3 emission, float step, float threshold, half mask) {
			float3 albedo = tex2D(_MainTex, IN.uv_MainTex) * _Tint;
			float3 finalTint = float3(0.2, 0.2, 0.2);
			
			if (step >= mask && step <= threshold) {
				albedo = albedo * .1 + emission * .8 + finalTint * .1;

			} else if (step > threshold) {
				albedo = finalTint;
			}
			return albedo;
		}

		float3 GetEmission(Input IN, float step, float threshold, half mask) {
			float4 emission;

			if (step >= mask && step <= threshold && mask > 0 && mask < 1) {
				emission = tex2D(_ColorRamp, float2(step * (1 / threshold - mask), 0));
			} else {
				emission = tex2D(_EmissionMap, IN.uv_EmissionMap) * _Emission;
			}

			return emission;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			half mask = GetMask(IN);
			float threshold = (mask + _TransitionWidth) * sin(sin(sin(_Transition * 3.14))*2);

			o.Emission = GetEmission(IN, _Transition, threshold, mask);
			o.Albedo = GetAlbedo(IN, o.Emission, _Transition, threshold, mask);
			o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex)) * _BumpScale;
			//o.Metallic = tex2D(_MetallicMap, IN.uv_MetallicMap) * _Smoothness;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
