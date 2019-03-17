Shader "Custom/SimpleShieldShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
		_PointColor("Point Color (RGB)", Color) = (1,0,0,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_ImpactSize("Impact Size", Float) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
			float3 worldPos;
            float2 uv_MainTex;
        };

        fixed4 _Color, _PointColor;
		float _ImpactSize;
		fixed4 _PointList[50];
		int _ListSize;
		
        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			fixed emissive = 0;

			float3 objectPosition = mul(unity_WorldToObject, float4(IN.worldPos, 1)).xyz;
			for (int i = 0; i < _ListSize; i++) {
				emissive += max(0, frac( 1.0 - max(0, (_PointList[i].w * _ImpactSize) - distance(_PointList[i].xyz, objectPosition.xyz)) / _ImpactSize) * (1 - _PointList[i].w));
			}

            o.Albedo = c.rgb;
			o.Emission = emissive * _PointColor;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
