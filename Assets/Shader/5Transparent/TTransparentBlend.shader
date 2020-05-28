﻿Shader "TShader/TTransparentBlend"
{
    Properties
    {
        _DiffuseTexture("DiffuseTexture", 2D) = "White" {}
        _DiffuseColor("DiffuseColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _AlphaScale("Alpha Scale", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        pass
        {
            Tags { "LightMode"="ForwardBase" }
            ZWrite Off
            //Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            sampler2D _DiffuseTexture;
            float4 _DiffuseTexture_ST;
            fixed4 _DiffuseColor;
            fixed _AlphaScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCoord0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : Texcoord0;
                float3 worldVertex : Texcoord1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                o.worldVertex = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _DiffuseTexture);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldVertex));
                fixed4 texColor = tex2D(_DiffuseTexture, i.uv);
                fixed3 albedo = texColor.rgb * _DiffuseColor.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //diffuse
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldLight, i.worldNormal));

                fixed3 color = ambient + diffuse;

                return fixed4(color, texColor.a * _AlphaScale);
            }

            ENDCG
        }
    }
}