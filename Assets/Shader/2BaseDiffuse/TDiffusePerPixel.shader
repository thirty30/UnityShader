// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TShader/TDiffusePerPixel"
{
    Properties
    {
        _DiffuseColor("DiffuseColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularColor("SpecularColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _Gloss("Gloss", Range(1, 256)) = 20
    }

    SubShader
    {
        pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _DiffuseColor;
            fixed4 _SpecularColor;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : Texcoord0;
                float3 worldVertex : Texcoord1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                o.worldVertex = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                //fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldVertex));

                //*******************Half Lambert enhance lighting*******************//
                //fixed halfLambert = dot(i.worldNormal, worldLight) * 0.5 + 0.5;
                //fixed3 diffuse = _LightColor0.rgb * _DiffuseColor.rgb * halfLambert;
                
                //*******************Stander Specular*******************//
                //fixed3 reflectDir = normalize(reflect(-worldLight, i.worldNormal));
                //fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldVertex.xyz);
                //fixed3 specular = _LightColor0.rgb * _SpecularColor * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

                //*******************blinnPhong specular*******************//
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldVertex.xyz);
                fixed3 halfDir = normalize(worldLight + viewDir);
                fixed3 specular = _LightColor0.rgb * _SpecularColor * pow(max(0, dot(worldLight, halfDir)), _Gloss);

                //diffuse
                fixed3 diffuse = _LightColor0.rgb * _DiffuseColor.rgb * saturate(dot(i.worldNormal, worldLight));
                
                fixed3 color = UNITY_LIGHTMODEL_AMBIENT.xyz + diffuse + specular;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
}
