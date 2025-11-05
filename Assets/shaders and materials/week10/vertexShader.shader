Shader "Custom/vertexShader"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _WingHeight("Wing Height", Float) = 1.0
        _FlapSpeed("Flap Speed", Float) = 1.0
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

            float4 _BaseColor;
            float _WingHeight;
            float _FlapSpeed;
            
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

            float3 ApplyWingFlap(float3 positionOS, float t)
            {
                float vertexDistance = abs(positionOS.x);
                float3 modifiedPositionOS = positionOS.xyz + float3(0,sin(t*_FlapSpeed) * _WingHeight,0) * vertexDistance;
                return modifiedPositionOS;
            }
            
            Varyings vertex(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                IN.positionOS.xyz = ApplyWingFlap(IN.positionOS.xyz, _Time.y);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 fragment(Varyings IN) : SV_Target
            {
                InputData lightData = (InputData)0;
                lightData.positionWS = IN.worldPos;
                lightData.normalWS = normalize(cross(ddy(lightData.positionWS), ddx(lightData.positionWS)));
                lightData.viewDirectionWS = GetWorldSpaceViewDir(lightData.positionWS);
                lightData.shadowCoord = TransformWorldToShadowCoord(lightData.positionWS);
                
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = _BaseColor.rgb;
                surfaceData.alpha = 1.0;
                surfaceData.smoothness = .5;
                surfaceData.specular = .5;

                return UniversalFragmentBlinnPhong(lightData, surfaceData);

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

            float4 _BaseColor;
            float _WingHeight;
            float _FlapSpeed;

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

            float3 ApplyWingFlap(float3 positionOS, float t)
            {
                float vertexDistance = abs(positionOS.x);
                float3 modifiedPositionOS = positionOS.xyz + float3(0,sin(t*_FlapSpeed) * _WingHeight,0) * vertexDistance;
                return modifiedPositionOS;
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
                IN.positionOS.xyz = ApplyWingFlap(IN.positionOS.xyz, _Time.y);
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