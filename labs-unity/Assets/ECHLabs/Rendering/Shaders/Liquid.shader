// ECH Labs — liquid inside glassware (URP).
// Fill level is a world-space plane (_FillWorldY) tilted by a damped wobble; pixels above it are
// clipped. Back faces are shaded as the liquid's top surface, so the container looks filled from
// any angle. A brighter band just under the surface fakes the meniscus that students read.
Shader "ECH/Liquid"
{
    Properties
    {
        _LiquidColor ("Liquid colour", Color) = (0.9, 0.95, 1, 0.2)
        _SurfaceColor ("Surface colour", Color) = (1, 1, 1, 0.35)
        _FillWorldY ("Fill height (world Y)", Float) = 0
        _WobbleX ("Wobble X", Float) = 0
        _WobbleZ ("Wobble Z", Float) = 0
        _Visible ("Visible", Float) = 1
        _FresnelPower ("Fresnel power", Range(0.5, 8)) = 3
        _RimStrength ("Rim strength", Range(0, 2)) = 0.6
        _MeniscusWidth ("Meniscus width (m)", Range(0, 0.01)) = 0.0025
        _Absorption ("Absorption (deep = darker)", Range(0, 4)) = 1.2
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent-10" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        Pass
        {
            Name "Liquid"
            Tags { "LightMode" = "UniversalForward" }
            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _LiquidColor;
                half4 _SurfaceColor;
                float _FillWorldY, _WobbleX, _WobbleZ, _Visible;
                half _FresnelPower, _RimStrength, _MeniscusWidth, _Absorption;
            CBUFFER_END

            struct Attributes { float4 positionOS : POSITION; float3 normalOS : NORMAL; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 centerWS : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                VertexPositionInputs p = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = p.positionCS;
                o.positionWS = p.positionWS;
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.centerWS = TransformObjectToWorld(float3(0, 0, 0));
                return o;
            }

            half4 frag(Varyings i, half facing : VFACE) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                clip(_Visible - 0.5);
                float2 d = i.positionWS.xz - i.centerWS.xz;
                float surfaceY = _FillWorldY + d.x * _WobbleX * 10 + d.y * _WobbleZ * 10;
                float below = surfaceY - i.positionWS.y;
                clip(below);

                float3 viewDir = normalize(GetWorldSpaceViewDir(i.positionWS));
                Light mainLight = GetMainLight();

                if (facing < 0)
                {
                    // Back face = top surface of the liquid (seen through the opening / walls).
                    half3 n = half3(0, 1, 0);
                    half spec = pow(saturate(dot(n, normalize(mainLight.direction + viewDir))), 64) * 0.6;
                    half4 c = _SurfaceColor;
                    c.rgb += spec * mainLight.color;
                    c.a = saturate(c.a + spec);
                    return c;
                }

                half3 n = normalize(i.normalWS);
                half fres = pow(1 - saturate(dot(n, viewDir)), _FresnelPower);
                half depth = saturate(below * 6);                 // darker / more saturated deeper down
                half4 col = _LiquidColor;
                col.rgb *= lerp(1.15, 1 - 0.25 * _Absorption * col.a, depth);
                col.rgb += fres * _RimStrength * mainLight.color * 0.5;
                col.a = saturate(col.a + fres * 0.35);
                // Meniscus: bright, more opaque band right under the surface.
                half men = 1 - saturate(below / max(_MeniscusWidth, 1e-4));
                col.rgb = lerp(col.rgb, col.rgb * 0.55, men * 0.8);
                col.a = saturate(col.a + men * 0.45);
                half ndl = saturate(dot(n, mainLight.direction)) * 0.25 + 0.75;
                col.rgb *= ndl;
                return col;
            }
            ENDHLSL
        }
    }
    FallBack Off
}
