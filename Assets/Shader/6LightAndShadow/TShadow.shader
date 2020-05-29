
Shader "TShader/TShadow"
{
    Properties
    {
        _DiffuseTexture("DiffuseTexture", 2D) = "White" {}
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
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLIght.cginc"

            sampler2D _DiffuseTexture;
            float4 _DiffuseTexture_ST;
            fixed4 _DiffuseColor;
            fixed4 _SpecularColor;
            float _Gloss;

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
                SHADOW_COORDS(3)
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                o.worldVertex = mul(unity_ObjectToWorld, v.vertex).xyz;
                //o.uv = v.texcoord * _DiffuseTexture_ST.xy + _DiffuseTexture_ST.zw;
                o.uv = TRANSFORM_TEX(v.texcoord, _DiffuseTexture);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldVertex));
                fixed3 albedo = tex2D(_DiffuseTexture, i.uv).rgb * _DiffuseColor.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //diffuse
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldLight, i.worldNormal));

                //*******************blinnPhong specular*******************//
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldVertex));
                fixed3 halfDir = normalize(worldLight + viewDir);
                fixed3 specular = _LightColor0.rgb * _SpecularColor * pow(max(0, dot(worldLight, halfDir)), _Gloss);

                fixed shadow = SHADOW_ATTENUATION(i);
                
                fixed3 color = ambient + (diffuse + specular) * shadow;

                return fixed4(color, 1.0);
            }

            ENDCG
        }

        pass
        {
            Tags { "LightMode" = "ShadowCaster" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f
            {
                V2F_SHADOW_CASTER;
            };

            v2f vert( appdata_base v )
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_TARGET
            {
                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
    }
}
