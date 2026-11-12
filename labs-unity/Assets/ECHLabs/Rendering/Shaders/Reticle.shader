// ECH Labs — gaze reticle: a dot that becomes an emerald ring filling clockwise during dwell.
Shader "ECH/Reticle"
{
    Properties { _Progress ("Progress", Range(0, 1)) = 0 _Active ("Active", Float) = 0 _Color ("Colour", Color) = (0.06, 0.73, 0.5, 1) }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Overlay+10" "RenderPipeline" = "UniversalPipeline" }
        Pass
        {
            ZTest Always ZWrite Off Cull Off Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial) half _Progress; half _Active; half4 _Color; CBUFFER_END
            struct A { float4 p : POSITION; float2 uv : TEXCOORD0; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct V { float4 p : SV_POSITION; float2 uv : TEXCOORD0; UNITY_VERTEX_OUTPUT_STEREO };
            V vert(A a) { V o; UNITY_SETUP_INSTANCE_ID(a); UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); o.p = TransformObjectToHClip(a.p.xyz); o.uv = a.uv * 2 - 1; return o; }
            half4 frag(V i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                float r = length(i.uv);
                float aa = fwidth(r) * 1.5;
                // Idle: small white dot. Active: ring with a progress arc.
                half dot = 1 - smoothstep(0.28 - aa, 0.28 + aa, r);
                half ring = smoothstep(0.72 - aa, 0.72 + aa, r) * (1 - smoothstep(0.95 - aa, 0.95 + aa, r));
                float angle = (atan2(i.uv.x, i.uv.y) / 6.2831853) + 0.5; // 0..1 clockwise from top
                half arc = ring * step(angle, _Progress);
                half4 c = half4(1, 1, 1, dot * 0.9);
                if (_Active > 0.5)
                {
                    c = lerp(half4(1, 1, 1, ring * 0.35), _Color, arc);
                    c.a = max(c.a, dot * 0.9);
                }
                return c;
            }
            ENDHLSL
        }
    }
}
