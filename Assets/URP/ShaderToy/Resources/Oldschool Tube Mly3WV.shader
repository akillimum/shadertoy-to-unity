Shader "Custom/ParticleFlowShader"
{
    Properties
    {
        _StartColor ("Start Color", Color) = (0, 0.64, 0.2, 1)
        _EndColor ("End Color", Color) = (0.06, 0.35, 0.85, 1)
        _StartRadius ("Start Radius", Float) = 0.84
        _EndRadius ("End Radius", Float) = 1.6
        _Power ("Power", Float) = 0.51
        _Duration ("Duration", Float) = 4.0
        _ParticleCount ("Particle Count", Int) = 100
    }
    
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            float4 _StartColor;
            float4 _EndColor;
            float _StartRadius;
            float _EndRadius;
            float _Power;
            float _Duration;
            int _ParticleCount;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            float4 frag (v2f i) : SV_Target
            {
                float t = _Time.y + 5.0;
                float z = 6.0;
                
                float2 s = _ScreenParams.xy;
                float2 fragCoord = i.uv * s;
                float2 v = z * (2.0 * fragCoord - s) / s.y;
                
                // Mouse interaction removed as Unity doesn't have direct mouse access like Shadertoy
                
                float3 col = float3(0, 0, 0);
                float2 pm = v.yx * 2.8;
                float dMax = _Duration;
                
                float evo = (sin(_Time.y * 0.01 + 400.0) * 0.5 + 0.5) * 99.0 + 1.0;
                
                float mb = 0.0;
                float mbRadius = 0.0;
                float sum = 0.0;
                
                for(int i = 0; i < _ParticleCount; i++)
                {
                    float fi = (float)i;
                    float fn = (float)_ParticleCount;
                    
                    float d = frac(t * _Power + 48934.4238 * sin(fi/evo * 692.7398));
                    float a = 6.28318530718 * fi/fn;
                    
                    float x = d * cos(a) * _Duration;
                    float y = d * sin(a) * _Duration;
                    
                    float distRatio = d/dMax;
                    mbRadius = lerp(_StartRadius, _EndRadius, distRatio);
                    
                    float2 p = v - float2(x, y);
                    mb = mbRadius/dot(p, p);
                    
                    sum += mb;
                    
                    col = lerp(col, lerp(_StartColor.rgb, _EndColor.rgb, distRatio), mb/sum);
                }
                
                sum /= (float)_ParticleCount;
                col = normalize(col) * sum;
                sum = clamp(sum, 0.0, 0.4);
                
                float3 tex = float3(1, 1, 1);
                col *= smoothstep(tex, float3(0, 0, 0), float3(sum, sum, sum));
                
                return float4(col, 1.0);
            }
            ENDCG
        }
    }
}