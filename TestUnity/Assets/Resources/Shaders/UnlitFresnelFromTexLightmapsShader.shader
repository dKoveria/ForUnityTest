// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/UnlitFresnelFromTexLightmapsShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (0.07843138,0.3921569,0.7843137,1)
		[MaterialToggle] _UseFresnel ("UseFresnel", Float ) = 1
		_Fresnel ("Fresnel", Float ) = 1
		//_FresnelColor ("FresnelColor", Color) = (1,1,1,1)
	}


	CGINCLUDE
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			uniform fixed4 _Color;
			uniform fixed _Fresnel;
			uniform fixed _UseFresnel;
			//uniform fixed4 _FresnelColor;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float2 uv1: TEXCOORD1;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float2 uv1 : TEXCOORD3;
				UNITY_FOG_COORDS(4)
				float4 vertex : SV_POSITION;
			};
						
			v2f vert (appdata v)
			{
				v2f o;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv1 = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
				UNITY_TRANSFER_FOG(o,o.vertex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half4 lm = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1);
				i.normalDir = normalize(i.normalDir);
				half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				half3 normalDirection = i.normalDir;
				half3 viewReflectDirection = reflect( -viewDirection, normalDirection );

				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv) * _Color * lm * 2.0; //lm * 2.0;
				half3 fre = pow(1.0-max(0,dot(normalDirection, viewDirection)),col.a*0.218*_Fresnel)*unity_FogColor.rgb*_Color.a*_UseFresnel * lm*2.0;//* lm*8;
				fixed4 finalRGBA = fixed4(col+fre,1);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, finalRGBA);

				return finalRGBA;
				//return fixed4(col,1);
			}

			fixed4 frag_rgb (v2f i) : SV_Target
			{
				//half4 lm = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1);
				i.normalDir = normalize(i.normalDir);
				half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				half3 normalDirection = i.normalDir;
				half3 viewReflectDirection = reflect( -viewDirection, normalDirection );

				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;
				half3 fre = pow(1.0-max(0,dot(normalDirection, viewDirection)),col.a*_Fresnel)*unity_FogColor.rgb*_Color.a*_UseFresnel;
				fixed4 finalRGBA = fixed4(col+fre,1);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, finalRGBA);

				return finalRGBA;
			}
			fixed4 frag_rgbm (v2f i) : SV_Target
			{
				half4 lm = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1);
				i.normalDir = normalize(i.normalDir);
				half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				half3 normalDirection = i.normalDir;
				half3 viewReflectDirection = reflect( -viewDirection, normalDirection );

				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv) * _Color * lm * lm.a * 8;
				half3 fre = pow(1.0-max(0,dot(normalDirection, viewDirection)),col.a*_Fresnel)*unity_FogColor.rgb*_Color.a * _UseFresnel * lm*2;// * lm*2;
				fixed4 finalRGBA = fixed4(col+fre,1);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, finalRGBA);

				return finalRGBA;
			}

			ENDCG




	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Pass
		{
			Tags { "LightMode" = "VertexLM" }
			Stencil {
                Ref 200
                Pass Replace
            }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			ENDCG
		}
		Pass
        {
            Tags { "LightMode" = "Vertex" }
            Stencil {
                Ref 200
                Pass Replace
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_rgb
            #pragma multi_compile_fog
            ENDCG
        }
        Pass
        {
            Tags { "LightMode" = "VertexLMRGBM" }
			Stencil {
                Ref 200
                Pass Replace
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_rgbm
            #pragma multi_compile_fog
            ENDCG
        }
	}
}
