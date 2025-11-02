Shader "Custom/shader2"
{
    Properties
    {
        _Color ("Pattern Color", Color) = (0,0,0,1)
        _BackgroundColor ("Background Color", Color) = (1,1,1,1)
        _MainScallopAmp ("Main Scallop Amplitude", Float) = 0.02
        _MainScallopFreq ("Main Scallop Frequency", Float) = 10
        _SubScallopAmp ("Sub Scallop Amplitude", Float) = 0.004
        _SubScallopFreq ("Sub Scallop Frequency", Float) = 50.0
        _BoostAmount ("Scallop Boost", Float) = 0.05
    }
    SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "LightMode" = "UniversalForward"
        }

        Pass
        {
            Cull Off

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

            float4 _Color;
            float4 _BackgroundColor;
            float _MainScallopAmp;
            float _MainScallopFreq;
            float _SubScallopAmp;
            float _SubScallopFreq;
            float4 _SpherePos;
            float _InteractionRadius;
            float _BoostAmount;

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

                float2 p = (IN.uv) * 8;
                float2 grid = frac(p) - 0.5;

                float diagonal1 = abs(grid.x + grid.y);
                float diagonal2 = abs(grid.x - grid.y);
                float xPattern = 1-smoothstep(0.02, 0.021, min(diagonal1, diagonal2));

                //above is the same grid thing from shader 1

                float distLeft = IN.uv.x;
                float distRight = 1.0 - IN.uv.x;
                float distBottom = IN.uv.y;
                float distTop = 1.0 - IN.uv.y;

                float minDist = min(min(distLeft, distRight), min(distBottom, distTop));

                float t;
                if(minDist == distLeft || minDist == distRight)
                {
                  t = IN.worldPos.y;
                }
                else if(minDist == distBottom || minDist == distTop)
                {
                  t = IN.worldPos.x;
                }

                float sphereDist = distance(IN.worldPos, _SpherePos.xyz);
                float sphereEffect = smoothstep(_InteractionRadius, 0, sphereDist);
                float boostedAmp = _MainScallopAmp + (_BoostAmount * sphereEffect);

                float mainScallop = boostedAmp * abs(sin(t * _MainScallopFreq * PI));
                float subScallop = _SubScallopAmp * abs(sin(t * _SubScallopFreq * PI));

                float scallop = mainScallop + subScallop;

                float dist = minDist - scallop;
                float step = 1-smoothstep(0.01, 0.012, dist);

                float3 baseColor = lerp(_BackgroundColor.rgb, _Color.rgb, xPattern);
                float3 col = lerp(baseColor, _Color.rgb, step);

                return float4(col, 1.);
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