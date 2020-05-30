
Shader "TShader/TRefraction"
{
    Properties
    {
        _DiffuseColor("DiffuseColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _RefractCubeMap("Refract CubeMap", Cube) = "_Skybox" {}
        _RefractColor("Refract Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _RefractAmount("Refract Amount", Range(0, 1)) = 1
        _RefractRatio("Refract Ratio", Range(0, 1)) = 0.5

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
            samplerCUBE _RefractCubeMap;
            fixed4 _RefractColor;
            fixed _RefractAmount;
            fixed _RefractRatio;
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
                float3 worldViewDir : Texcoord2;
                float3 worldRefract : Texcoord3;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldVertex = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldVertex);
                o.worldRefract = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldViewDir = normalize(i.worldViewDir);
                fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldVertex));

                fixed3 refraction = texCUBE(_RefractCubeMap, i.worldRefract).rgb * _RefractColor.rgb;

                fixed3 albedo = _DiffuseColor.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //diffuse
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldLight, worldNormal));

                //*******************blinnPhong specular*******************//
                fixed3 halfDir = normalize(worldLight + worldViewDir);
                fixed3 specular = _LightColor0.rgb * _SpecularColor * pow(max(0, dot(worldLight, halfDir)), _Gloss);
                
                fixed3 color = ambient + specular + lerp(diffuse, refraction, _RefractAmount);

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
}
