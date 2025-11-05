Shader "Custom/vertexShader"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (0.65, 0.63, 1.0)
        _MiddleColor("Middle Color", Color) = (1.0, 0.8, 0.1)
        _TipColor("Tip Color", Color) = (1.0, 0.3, 0.05)
        _DistortionSize("Distortion Size", Float) = 0.23
        _FlickerSpeed("Ficker Speed", Float) = 2.9
        _EmissionColor("Emission Color", Color) = (1,0.5,0.1,1)
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

            #pragma vertex vertex
            #pragma fragment fragment

            #pragma shader_feature _CLUSTER_LIGHT_LOOP
            #pragma shader_feature _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma shader_feature _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma shader_feature _ADDITIONAL_LIGHT_SHADOWS
            #pragma shader_feature _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/JasonNoise.hlsl"

            float4 _BaseColor;
            float4 _MiddleColor;
            float4 _TipColor;
            float _DistortionSize;
            float _FlickerSpeed;
            float4 _EmissionColor;
            
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
                float3 positionOS : TEXCOORD3;
            };

            float3 ApplyFlameDistortion(float3 positionOS, float t, float2 uv)
            {
                float vertexDistance = abs(positionOS.y);

                float n = noise21(uv * 4 + float2(0, t * _FlickerSpeed)); //scrolling noise
                float xOffset = (n - 0.5) * vertexDistance * _DistortionSize; //horizontal swaying
                float yOffset = sin(t * _FlickerSpeed + n*6) * vertexDistance * 0.15; //vertical flicker

                return positionOS + float3(xOffset, yOffset, 0);
            }
            
            Varyings vertex(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                IN.positionOS.xyz = ApplyFlameDistortion(IN.positionOS.xyz, _Time.y, IN.uv);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.positionOS = IN.positionOS;
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 fragment(Varyings IN) : SV_Target
            {
                /*
                InputData lightData = (InputData)0;
                lightData.positionWS = IN.worldPos;
                lightData.normalWS = normalize(cross(ddy(lightData.positionWS), ddx(lightData.positionWS)));
                lightData.viewDirectionWS = GetWorldSpaceViewDir(lightData.positionWS);
                lightData.shadowCoord = TransformWorldToShadowCoord(lightData.positionWS);
                
                SurfaceData surfaceData = (SurfaceData)0;

                float flameHeight = saturate(IN.positionOS.y);

                float3 flameColor = lerp(lerp(_BaseColor, _MiddleColor, flameHeight*0.7), _TipColor, flameHeight);

                surfaceData.albedo = flameColor;
                surfaceData.alpha = 0.8;
                surfaceData.smoothness = 0;
                surfaceData.specular = 0;
                surfaceData.emission = _EmissionColor.rgb * flameHeight * 5.0;

                return UniversalFragmentBlinnPhong(lightData, surfaceData);
                */
                float flameHeight = saturate(IN.positionOS.y);
                float3 flameColor = lerp(lerp(_BaseColor.rgb, _MiddleColor.rgb, flameHeight*0.8), _TipColor.rgb, flameHeight);

                float3 emissionColor = _EmissionColor.rgb * flameHeight * 5.0;
                float3 finalColor = flameColor + emissionColor;

                return half4(finalColor, 1);
            }
            ENDHLSL
        }
        Pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
            HLSLPROGRAM

            #pragma vertex vertex
            #pragma fragment fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Assets/JasonNoise.hlsl"

            float4 _BaseColor;
            float _DistortionSize;
            float _FlickerSpeed;

            float3 _LightDirection0; // filled by unity and this is barely documented anywhere
            float3 _LightPosition;
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // for rendering final fragment
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1; // maybe...?
                float3 worldNormal : TEXCOORD2; // also maybe...?
            };

            float3 ApplyFlameDistortion(float3 positionOS, float t, float2 uv)
            {
                float vertexDistance = abs(positionOS.y);

                float n = noise21(uv * 4 + float2(0, t * _FlickerSpeed)); //scrolling noise
                float xOffset = n * vertexDistance * _DistortionSize; //horizontal swaying
                float yOffset = sin(t * _FlickerSpeed + n*6) * vertexDistance; //vertical flicker

                return positionOS + float3(xOffset, yOffset, 0);
            }

            float4 GetShadowPositionHClip(Attributes Input)
            {
                float3 positionWS = TransformObjectToWorld(Input.positionOS.xyz);
                float4 positionCS = TransformWorldToHClip(positionWS);
                positionCS = ApplyShadowClamping(positionCS);
                return positionCS;
            }
            
            Varyings vertex(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                IN.positionOS.xyz = ApplyFlameDistortion(IN.positionOS.xyz, _Time.y, IN.uv);
                OUT.positionHCS = GetShadowPositionHClip(IN);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 fragment(Varyings IN) : SV_Target
            {
                return 0;

            }
            ENDHLSL
        }
    }
}