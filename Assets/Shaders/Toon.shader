Shader "Olsyx/Toon" {

	Properties{
		_Outline("Outline Width", Range(0,10)) = 0.002
		_OutlineColor("Outline Color", Color) = (0,0,0,1)

		_CelShadeLight("CelShade Light", Color) = (1,1,1,1)
		_CelShadeMedium("CelShade Medium", Color) = (0.5,0.5,0.5,1)
		_CelShadeDark("CelShade Dark", Color) = (0.1,0.1,0.1,1)

		[MaterialToggle] _useRim("Use Rim", Float) = 0
		_RimColor("Rim Color", Color) = (0.0,0.5,0.5,0.0)
		_RimPower("Rim Power", Range(0.5,8.0)) = 3.0

		_Color("Tint", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_NormalMap("Normal", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1

		_MetallicMap("Metallic", 2D) = "white" {}
		[Gamma] _Metallic("Metallic", Range(0, 1)) = 0
		_Smoothness("Smoothness", Range(0, 1)) = 0.1
		_OcclusionTex("Occlusion", 2D) = "white" {}
	}

	SubShader{
		CGPROGRAM
			#pragma surface surf ToonRamp
			#pragma multi_compile RIM

			float4 _CelShadeLight, _CelShadeMedium, _CelShadeDark;

			float _useRim;
			float4 _RimColor;
			float _RimPower;

			float4 _Color;
			sampler2D _MainTex, _NormalMap, _MetallicMap, _OcclusionTex;

			float _BumpScale, _Metallic, _Smoothness;

			
			struct Input {
				float3 viewDir;
				float2 uv_MainTex;
			};

			float3 GetShadeColor(float value) {
				if (value <= 0.33) {
					return _CelShadeDark;
				} else if (value <= 0.66) {
					return _CelShadeMedium;
				} 
				return _CelShadeLight;
			}

			void ApplyRim(Input IN, inout SurfaceOutput o) {
				if (_useRim < 1) {
					return;
				}

				half rim = 1 - saturate(dot(normalize(IN.viewDir), o.Normal));
				float rimPower = pow(rim, _RimPower);
				o.Emission = _RimColor.rgb * rimPower * 10; // rim^3 pushes the rim to the edge even farther.
				o.Alpha = rimPower;
			}

			void surf(Input IN, inout SurfaceOutput o) {
				o.Specular = tex2D(_MetallicMap, IN.uv_MainTex) * (1 - _Smoothness) + _Metallic;
				o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex)) * _BumpScale;

				float3 direction = dot(IN.viewDir, o.Normal);
				float2 uv = direction * 0.5 + 0.5;
				float3 shade = GetShadeColor(uv.x * o.Specular.x);

				o.Albedo = _Color.rgb * tex2D(_MainTex, IN.uv_MainTex) * tex2D(_OcclusionTex, IN.uv_MainTex);
				ApplyRim(IN, o);
			}

			float4 LightingToonRamp(SurfaceOutput s, fixed3 lightDir, fixed atten) {
				float diffuse = dot(s.Normal, lightDir);
				float value = diffuse * 0.5 + 0.5;
				float3 shade = GetShadeColor(value * s.Specular.x);

				float4 color;
				color.rgb = s.Albedo *_LightColor0.rgb * shade;
				color.a = s.Alpha;
				return color;
			}

		ENDCG
			

		// OUTLINE
		Pass {
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			float _Outline;
			float4 _OutlineColor;

			struct appdata {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				fixed4 color : COLOR;
			};

			v2f vert(appdata v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				float3 norm = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));
				float2 offset = TransformViewToProjection(norm.xy);

				o.pos.xy += offset * o.pos.z * _Outline;
				o.color = _OutlineColor;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				return i.color;
			}
			ENDCG
		}
	}

	FallBack "Diffuse"
}
