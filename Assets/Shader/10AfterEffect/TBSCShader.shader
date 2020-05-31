Shader "TShader/TBSCShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Brightness("Brightness", FLoat) = 1
        _Saturation("Saturation", FLoat) = 1
        _Contrast("Contrast", FLoat) = 1
        _UseEdge("UseEdge", Range(0, 1)) = 0
        _EdgesOnly("EdgesOnly", FLoat) = 1
        _EdgeColor("EdgeColor", Color) = (0, 0, 0, 1)
        _BackgroundColor("BackgroundColor", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            ZTest Always
            Cull Off
            ZWrite off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv[9] : TEXCOORD0;
            };

            sampler2D _MainTex;
            half4 _MainTex_TexelSize;
            float4 _MainTex_ST;
            float _Brightness;
            float _Saturation;
            float _Contrast;
            int _UseEdge;
            float _EdgesOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;


            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                half2 uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);

                return o;
            }

            fixed luminance(fixed3 color) 
            {
				return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
			}
			
			half Sobel(v2f i) {
				const half Gx[9] = {-1,  0,  1,
										-2,  0,  2,
										-1,  0,  1};
				const half Gy[9] = {-1, -2, -1,
										0,  0,  0,
										1,  2,  1};		
				
				half texColor;
				half edgeX = 0;
				half edgeY = 0;
				for (int it = 0; it < 9; it++) 
                {
					texColor = luminance(tex2D(_MainTex, i.uv[it]).rgb);
					edgeX += texColor * Gx[it];
					edgeY += texColor * Gy[it];
				}
				
				half edge = 1 - abs(edgeX) - abs(edgeY);
				
				return edge;
			}

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 Tex = tex2D(_MainTex, i.uv[4]);
                fixed3 TempColor = Tex.rgb * _Brightness;

                fixed luminance = 0.2125 * Tex.r + 0.7154 * Tex.g + 0.0721 * Tex.b;
                fixed3 luminanceColor = fixed3(luminance, luminance, luminance);
                TempColor = lerp(luminanceColor, TempColor, _Saturation);

                fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
                TempColor = lerp(avgColor, TempColor, _Contrast);

                fixed4 finalColor = fixed4(TempColor, 1);

                if (_UseEdge == 1)
                {
                    half edge = Sobel(i);
                    fixed4 withEdgeColor = lerp(_EdgeColor, finalColor, edge);
                    fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
                    finalColor = lerp(withEdgeColor, onlyEdgeColor, _EdgesOnly);
                }
                return finalColor;
            }

            ENDCG
        }
    }

    Fallback off
}
