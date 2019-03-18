Shader "Olsyx/ToonPBR" {

	Properties{
		_Outline("Outline Width", Range(0,10)) = 0.002
		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		
		_SpecularColor("Specular", Color) = (1,1,1,1)
		_Color("Tint", Color) = (0.5,0.5,0.5,1)
		_ShadowColor("Shadow", Color) = (0.1,0.1,0.1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_NormalMap("Normal", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1

		_SpecularMap("Specular Map", 2D) = "white" {}
		_Smoothness("Smoothness", Range(0, 1)) = 0.1
		_OcclusionTex("Occlusion", 2D) = "white" {}
		
		[MaterialToggle] _useRim("Use Rim", Float) = 0
		_RimColor("Rim Color", Color) = (0.0,0.5,0.5,0.0)
		_RimPower("Rim Power", Range(0.5,8.0)) = 3.0

	}

	SubShader{
		CGPROGRAM
			#pragma surface surf ToonRamp fullforwardshadows
			#pragma multi_compile RIM

			float4 _SpecularColor, _Color, _ShadowColor;

			float _useRim;
			float4 _RimColor;
			float _RimPower;

			sampler2D _MainTex, _NormalMap, _SpecularMap, _OcclusionTex;

			float _BumpScale, _Metallic, _Smoothness;

			
			struct Input {
				float3 worldPos;
				float3 viewDir;
				float3 lightDir;
				float2 uv_MainTex;
			};

			float3 GetShadeColor(float value) {
				return value <= 0.33 ? _ShadowColor : _Color;
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
				o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex) * _BumpScale);
				o.Specular = tex2D(_SpecularMap, IN.uv_MainTex).r * _Smoothness;
				o.Albedo = _Color * tex2D(_MainTex, IN.uv_MainTex) * tex2D(_OcclusionTex, IN.uv_MainTex);
				ApplyRim(IN, o);
			}
			
			float3 GetDiffuseLight(SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed attenuation) {
				float4 diffuseTerm = saturate(dot(s.Normal, lightDir));
				float shadow = smoothstep(0, fwidth(attenuation), attenuation * 2);
				float3 diffuse = GetShadeColor(diffuseTerm) * shadow;
				return diffuse * _LightColor0;
			}

			float4 GetSpecularLight(SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed attenuation) {
				// Blinn-Phong
				float3 halfVector = normalize(lightDir + viewDir);
				float NdotH = dot(s.Normal, halfVector);
				float4 specularTerm = attenuation * pow(saturate(NdotH), 25 * s.Specular);
				specularTerm = max(0.0, specularTerm);
				specularTerm = specularTerm > 0.6 ? specularTerm : float4(0, 0, 0, 1);
				return specularTerm * _SpecularColor * s.Specular;
			}

			float4 LightingToonRamp(SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed attenuation) {
				float3 diffuse = GetDiffuseLight(s, lightDir, viewDir, attenuation);
				float4 specular = GetSpecularLight(s, lightDir, viewDir, attenuation);
				float3 light =  diffuse;

				float4 color;
				color.rgb = s.Albedo * light + specular;
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
	CustomEditor "ToonPBRInspector"
	FallBack "Diffuse"
}
