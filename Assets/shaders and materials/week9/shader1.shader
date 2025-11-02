Shader "Custom/shader1"
{
    Properties
    {
        _PatternColor("Pattern Color", Color) = (1, 1, 1, 1)
        _PatternScale("Pattern Scale", Float) = 8
        _FresnelPower("Fresnel Power", Float) = 0.5
        _DistortRadius("Distort Radius", Float) = 2
    }

    SubShader
    {
        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "LightMode" = "UniversalForward"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            float4 _PatternColor;
            float _PatternScale;
            float _FresnelPower;
            float4 _SpherePos;
            float _DistortRadius;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS);

                OUT.uv = IN.uv;
                return OUT;
            }


            half4 frag(Varyings IN) : SV_Target
            {
                float3 viewDir = normalize(_WorldSpaceCameraPos - IN.worldPos);
                float fresnel = pow(1.0 - saturate(dot(viewDir, normalize(IN.worldNormal))), _FresnelPower);

                float dist = distance(IN.worldPos, _SpherePos.xyz);
                float distortEffect = smoothstep(_DistortRadius, 0, dist);

                float2 offset = (IN.worldPos.xy - _SpherePos.xy) * distortEffect * 0.2;
                float2 p = (IN.uv + offset) * _PatternScale;
                
                float2 grid = frac(p) - 0.5;

                float diagonal1 = abs(grid.x + grid.y);
                float diagonal2 = abs(grid.x - grid.y);
                float xPattern = 1-smoothstep(0.02, 0.021, min(diagonal1, diagonal2));

                xPattern *= fresnel;

                return float4(float3(_PatternColor.rgb), xPattern);
            }

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }

}
