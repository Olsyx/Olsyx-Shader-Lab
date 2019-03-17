Shader "Olsyx/Water"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

		Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			float _WaveHeight;
			float4 _Color;

			int _ListSize;
			fixed4 _CollisionPoints[50];

			struct appdata {
				float4 position : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 position : SV_POSITION;
				fixed4 color : COLOR;
			};

			v2f vert(appdata v) {
				v2f o;
				o.position = UnityObjectToClipPos(v.position);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				return  distance(UnityObjectToViewPos(i.position), _CollisionPoints[0]);
			}
			ENDCG
		}
    }
    FallBack "Diffuse"
}
