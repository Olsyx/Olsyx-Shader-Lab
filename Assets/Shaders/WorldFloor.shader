Shader "Olsyx/WorldFloor"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

		_Normals("Normals Strength", Range(0,1)) = 0.0
		_NormalMap("Normals", 2D) = "bump" {}
       
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Smoothness("Smoothness", Range(0,1)) = 0.5
        _MetallicMap ("Metallic (RGB)", 2D) = "white" {}
		
		_EmissiveColor("Emissive Color", Color) = (0,0,0,0)
		_Emissive("Emissive Strength", Range(0,1)) = 0.5
		_EmissiveMap("Emissive Map (RGB)", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex, _NormalMap, _MetallicMap, _EmissiveMap;
        float4 _MainTex_ST, _NormalMap_ST, _MetallicMap_ST, _EmissiveMap_ST;
		fixed4 _Color, _EmissiveColor;
		half _Normals, _Metallic, _Smoothness, _Emissive;

        struct Input {
			float3 worldPos;
        };

        #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o) {
			float2 position = float2(IN.worldPos.x, IN.worldPos.z);

            fixed4 c = tex2D (_MainTex, position * _MainTex_ST) * _Color;
            o.Albedo = c.rgb;
			o.Normal = UnpackNormal(tex2D(_NormalMap, position * _NormalMap_ST));
            o.Metallic = tex2D(_MetallicMap, position * _MetallicMap_ST) * _Metallic;
            o.Smoothness = tex2D(_MetallicMap, position * _MetallicMap_ST) * _Smoothness;
            o.Emission = tex2D(_EmissiveMap, position * _EmissiveMap_ST) * _EmissiveColor * _Emissive;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
