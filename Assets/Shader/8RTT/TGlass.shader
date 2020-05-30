
Shader "TShader/TGlass"
{
    Properties
    {
        _DiffuseTexture("DiffuseTexture", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _CubeMap("Environment CubeMap", Cube) = "_Skybox" {}
        _Distortion("Distortion", Range(0.0, 100.0)) = 10
        _RefractAmount("Refract Amount", Range(0.0, 1.0)) = 1.0
        _SpecularColor("SpecularColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _Gloss("Gloss", Range(1, 256)) = 20
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Opaque" }
        GrabPass { "_RefractionTex" }

        pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            sampler2D _DiffuseTexture;
            float4 _DiffuseTexture_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _CubeMap;
            float _Distortion;
            fixed _RefractAmount;
            fixed4 _SpecularColor;
            float _Gloss;
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; 
                float4 texcoord : TEXCoord0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 scrPos : Texcoord0;
                float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;
			    float4 TtoW1 : TEXCOORD3;
			    float4 TtoW2 : TEXCOORD4;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeGrabScreenPos(o.pos);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _DiffuseTexture);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                fixed3 worldLight = normalize(UnityWorldSpaceLightDir(worldPos));
                
                fixed3 albedo = tex2D(_DiffuseTexture, i.uv.xy).rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				// Get the normal in tangent space
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));	
				
				// Compute the offset in tangent space
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				fixed3 refractionColor = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;

				// Convert the normal to world space
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				fixed3 reflDir = reflect(-worldViewDir, bump);
				fixed3 reflectionColor = texCUBE(_CubeMap, reflDir).rgb * albedo;
				
				fixed3 finalColor = reflectionColor * (1 - _RefractAmount) + refractionColor * _RefractAmount;

                //diffuse
                fixed3 diffuse = _LightColor0.rgb * finalColor * max(0, dot(worldLight, bump));

                //*******************blinnPhong specular*******************//
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                fixed3 halfDir = normalize(worldLight + viewDir);
                fixed3 specular = _LightColor0.rgb * _SpecularColor * pow(max(0, dot(worldLight, halfDir)), _Gloss);
                
                fixed3 color = ambient + diffuse + specular;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
}
