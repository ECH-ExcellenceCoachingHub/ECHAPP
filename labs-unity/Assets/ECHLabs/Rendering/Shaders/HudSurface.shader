// ECH Labs — world-space HUD panel for Cardboard / VR. Always drawn on top so equipment never
// hides instructions; UI Toolkit renders premultiplied alpha into the RenderTexture.
Shader "ECH/HudSurface"
{
    Properties { _MainTex ("HUD", 2D) = "black" {} _Opacity ("Opacity", Range(0, 1)) = 1 }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Overlay" "RenderPipeline" = "UniversalPipeline" }
        Pass
        {
            ZTest Always ZWrite Off Cull Back
            Blend One OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial) float4 _MainTex_ST; half _Opacity; CBUFFER_END
            struct A { float4 p : POSITION; float2 uv : TEXCOORD0; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct V { float4 p : SV_POSITION; float2 uv : TEXCOORD0; UNITY_VERTEX_OUTPUT_STEREO };
            V vert(A a) { V o; UNITY_SETUP_INSTANCE_ID(a); UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); o.p = TransformObjectToHClip(a.p.xyz); o.uv = a.uv; return o; }
            half4 frag(V i) : SV_Target { UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i); return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Opacity; }
            ENDHLSL
        }
    }
}
