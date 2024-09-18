Shader "ShaderToy/URP/Clouds XslGRr"
{
    Properties
    {
        _Channel0("Channel0 (RGB)", 2D) = "" {}
        _Channel1("Channel1 (RGB)", 2D) = "" {}
        _Channel2("Channel2 (RGB)", 2D) = "" {}
        _Channel3("Channel3 (RGB)", 2D) = "" {}
        [HideInInspector]iMouse("Mouse", Vector) = (0,0,0,0)


    }

        SubShader
        {
            // With SRP we introduce a new "RenderPipeline" tag in Subshader. This allows to create shaders
            // that can match multiple render pipelines. If a RenderPipeline tag is not set it will match
            // any render pipeline. In case you want your subshader to only run in LWRP set the tag to
            // "UniversalRenderPipeline"
            Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
            LOD 300

            // ------------------------------------------------------------------
            // Forward pass. Shades GI, emission, fog and all lights in a single pass.
            // Compared to Builtin pipeline forward renderer, LWRP forward renderer will
            // render a scene with multiple lights with less drawcalls and less overdraw.
            Pass
            {
                // "Lightmode" tag must be "UniversalForward" or not be defined in order for
                // to render objects.
                Name "StandardLit"
                //Tags{"LightMode" = "UniversalForward"}

                //Blend[_SrcBlend][_DstBlend]
                //ZWrite Off ZTest Always
                //ZWrite[_ZWrite]
                //Cull[_Cull]

                HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            //do not add LitInput, it has already BaseMap etc. definitions, we do not need them (manually described below)
            //#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

            float4 _Channel0_ST;
            TEXTURE2D(_Channel0);       SAMPLER(sampler_Channel0);
            float4 _Channel1_ST;
            TEXTURE2D(_Channel1);       SAMPLER(sampler_Channel1);
            float4 _Channel2_ST;
            TEXTURE2D(_Channel2);       SAMPLER(sampler_Channel2);
            float4 _Channel3_ST;
            TEXTURE2D(_Channel3);       SAMPLER(sampler_Channel3);

            float4 iMouse;


            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv                       : TEXCOORD0;
                float4 positionCS               : SV_POSITION;
                float4 screenPos                : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                // VertexPositionInputs contains position in multiple spaces (world, view, homogeneous clip space)
                // Our compiler will strip all unused references (say you don't use view space).
                // Therefore there is more flexibility at no additional cost with this struct.
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                // TRANSFORM_TEX is the same as the old shader library.
                output.uv = TRANSFORM_TEX(input.uv, _Channel0);
                // We just use the homogeneous clip position from the vertex input
                output.positionCS = vertexInput.positionCS;
                output.screenPos = ComputeScreenPos(vertexInput.positionCS);
                return output;
            }

            #define FLT_MAX 3.402823466e+38
            #define FLT_MIN 1.175494351e-38
            #define DBL_MAX 1.7976931348623158e+308
            #define DBL_MIN 2.2250738585072014e-308

             #define iTimeDelta unity_DeltaTime.x
            // float;

            #define iFrame ((int)(_Time.y / iTimeDelta))
            // int;

           #define clamp(x,minVal,maxVal) min(max(x, minVal), maxVal)

           float mod(float a, float b)
           {
               return a - floor(a / b) * b;
           }
           float2 mod(float2 a, float2 b)
           {
               return a - floor(a / b) * b;
           }
           float3 mod(float3 a, float3 b)
           {
               return a - floor(a / b) * b;
           }
           float4 mod(float4 a, float4 b)
           {
               return a - floor(a / b) * b;
           }

           float3 makeDarker(float3 item) {
               return item *= 0.90;
           }

           float4 pointSampleTex2D(Texture2D sam, SamplerState samp, float2 uv)//, float4 st) st is aactually screenparam because we use screenspace
           {
               //float2 snappedUV = ((float2)((int2)(uv * st.zw + float2(1, 1))) - float2(0.5, 0.5)) * st.xy;
               float2 snappedUV = ((float2)((int2)(uv * _ScreenParams.zw + float2(1, 1))) - float2(0.5, 0.5)) * _ScreenParams.xy;
               return  SAMPLE_TEXTURE2D(sam, samp, float4(snappedUV.x, snappedUV.y, 0, 0));
           }

           // Created by inigo quilez - iq / 2013 
// I share this piece ( art and code ) here in Shadertoy and through its Public API , only for educational purposes. 
// You cannot use , sell , share or host this piece or modifications of it as part of your own commercial or non - commercial product , website or project. 
// You can share a link to it or an unmodified screenshot of it provided you attribute "by Inigo Quilez , @iquilezles and iquilezles.org". 
// If you are a techer , lecturer , educator or similar and these conditions are too restrictive for your needs , please contact me and we'll work it out. 

// Volumetric clouds. Not physically correct in any way - 
// it does the wrong extintion computations and also 
// works in sRGB instead of linear RGB color space. No 
// shadows are computed , no scattering is computed. It is 
// a volumetric raymarcher than samples an fBM and tweaks 
// the colors to make it look good. 
// 
// Lighting is done with only one extra sample per raymarch 
// step instead of using 3 to compute a density gradient , 
// by using this directional derivative technique: 
// 
// https: // iquilezles.org / www / articles / derivative / derivative.htm 


// 0: one 3d SAMPLE_TEXTURE2D lookup 
// 1: two 2d SAMPLE_TEXTURE2D lookups with hardware interpolation 
// 2: two 2d SAMPLE_TEXTURE2D lookups with software interpolation 
#define NOISE_METHOD 1 

 // 0: no LOD 
 // 1: yes LOD 
#define USE_LOD 1 



float noise(in float3 x)
 {
    float3 p = floor(x);
    float3 f = frac(x);
     f = f * f * (3.0 - 2.0 * f);

#if NOISE_METHOD == 0 
    x = p + f;
    return SAMPLE_TEXTURE2D_LOD(_Channel2 , sampler_Channel2 , (x + 0.5) / 32.0 , 0.0).x * 2.0 - 1.0;
#endif 
#if NOISE_METHOD == 1 
     float2 uv = (p.xy + float2 (37.0 , 239.0) * p.z) + f.xy;
    float2 rg = SAMPLE_TEXTURE2D_LOD(_Channel0 , sampler_Channel0 , (uv + 0.5) / 256.0 , 0.0).yx;
     return lerp(rg.x , rg.y , f.z) * 2.0 - 1.0;
#endif 
#if NOISE_METHOD == 2 
    int3 q = int3 (p);
     int2 uv = q.xy + int2 (37 , 239) * q.z;
     float2 rg = lerp(lerp(pointSampleTex2D(_Channel0 , sampler_Channel0 , (uv) & 255 , 0) ,
                          pointSampleTex2D(_Channel0 , sampler_Channel0 , (uv + int2 (1 , 0)) & 255 , 0) , f.x) ,
                      lerp(pointSampleTex2D(_Channel0 , sampler_Channel0 , (uv + int2 (0 , 1)) & 255 , 0) ,
                          pointSampleTex2D(_Channel0 , sampler_Channel0 , (uv + int2 (1 , 1)) & 255 , 0) , f.x) , f.y).yx;
     return lerp(rg.x , rg.y , f.z) * 2.0 - 1.0;
#endif 
 }

float map(in float3 p , int oct)
 {
     float3 q = p - float3 (0.0 , 0.1 , 1.0) * _Time.y;
    float g = 0.5 + 0.5 * noise(q * 0.3);

     float f;
    f = 0.50000 * noise(q); q = q * 2.02;
    #if USE_LOD == 1 
    if (oct >= 2)
    #endif 
    f += 0.25000 * noise(q); q = q * 2.23;
    #if USE_LOD == 1 
    if (oct >= 3)
    #endif 
    f += 0.12500 * noise(q); q = q * 2.41;
    #if USE_LOD == 1 
    if (oct >= 4)
    #endif 
    f += 0.06250 * noise(q); q = q * 2.62;
    #if USE_LOD == 1 
    if (oct >= 5)
    #endif 
    f += 0.03125 * noise(q);

    f = lerp(f * 0.1 - 0.75 , f , g * g) + 0.1;
    return 1.5 * f - 0.5 - p.y;
 }

static const float3 sundir = normalize(float3 (-1.0 , 0.0 , -1.0));
static const int kDiv = 10; // make bigger for higher quality 

float4 raymarch(in float3 ro , in float3 rd , in float3 bgcol , in int2 px)
 {
    // bounding planes 
   static const float yb = -3.0;
   static const float yt = 0.6;
   float tb = (yb - ro.y) / rd.y;
   //float tt = (yt - ro.y) / rd.t;
   float tt = (yt - ro.y) / rd.y;

   // find tigthest possible raymarching segment 
  float tmin , tmax;
  if (ro.y > yt)
   {
      // above top plane 
     if (tt < 0.0) return float4 (0.0 , 0.0 , 0.0 , 0.0); // early exit 
     tmin = tt;
     tmax = tb;
  }
 else
  {
      // inside clouds slabs 
     tmin = 0.0;
     tmax = 60.0;
     if (tt > 0.0) tmax = min(tmax , tt);
     if (tb > 0.0) tmax = min(tmax , tb);
  }

  // dithered near distance 
 float t = tmin + 0.1 * pointSampleTex2D(_Channel1 , sampler_Channel1 , px & 1023 ).x;

 // raymarch loop 
 float4 sum = float4 (0.0 , 0.0 , 0.0 , 0.0);
for (int i = 0; i < 190 * kDiv; i++)
 {
    // step size 
   float dt = max(0.05 , 0.02 * t / float(kDiv));

   // lod 
  #if USE_LOD == 0 
  static const int oct = 5;
  #else 
  int oct = 5 - int(log2(1.0 + t * 0.5));
  #endif 

  // sample cloud 
 float3 pos = ro + t * rd;
 float den = map(pos , oct);
 if (den > 0.01) // if inside 
  {
     // do lighting 
    float dif = clamp((den - map(pos + 0.3 * sundir , oct)) / 0.3 , 0.0 , 1.0);
    float3 lin = float3 (0.65 , 0.65 , 0.75) * 1.1 + 0.8 * float3 (1.0 , 0.6 , 0.3) * dif;
    float4 col = float4 (lerp(float3 (1.0 , 0.95 , 0.8) , float3 (0.25 , 0.3 , 0.35) , den) , den);
    col.xyz *= lin;
    // fog 
   col.xyz = lerp(col.xyz , bgcol , 1.0 - exp2(-0.075 * t));
   // composite front to back 
  col.w = min(col.w * 8.0 * dt , 1.0);
  col.rgb *= col.a;
  sum += col * (1.0 - sum.a);
}
 // advance ray 
t += dt;
// until far clip or full opacity 
if (t > tmax || sum.a > 0.99) break;
}

return clamp(sum , 0.0 , 1.0);
}

float3x3 setCamera(in float3 ro , in float3 ta , float cr)
 {
     float3 cw = normalize(ta - ro);
     float3 cp = float3 (sin(cr) , cos(cr) , 0.0);
     float3 cu = normalize(cross(cw , cp));
     float3 cv = normalize(cross(cu , cw));
    return float3x3 (cu , cv , cw);
 }

float4 render(in float3 ro , in float3 rd , in int2 px)
 {
     float sun = clamp(dot(sundir , rd) , 0.0 , 1.0);

     // background sky 
    float3 col = float3 (0.76 , 0.75 , 0.86);
    col -= 0.6 * float3 (0.90 , 0.75 , 0.95) * rd.y;
     col += 0.2 * float3 (1.00 , 0.60 , 0.10) * pow(sun , 8.0);

     // clouds 
    float4 res = raymarch(ro , rd , col , px);
    col = col * (1.0 - res.w) + res.xyz;

    // sun glare 
    col += 0.2 * float3 (1.0 , 0.4 , 0.2) * pow(sun , 3.0);

    // tonemap 
   col = smoothstep(0.15 , 1.1 , col);

   return float4 (col , 1.0);
}

half4 LitPassFragment(Varyings input) : SV_Target  {
UNITY_SETUP_INSTANCE_ID(input);
UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
 half4 fragColor = half4 (1 , 1 , 1 , 1);
 float2 fragCoord = ((input.screenPos.xy) / (input.screenPos.w + FLT_MIN)) * _ScreenParams.xy;
     float2 p = (2.0 * fragCoord - _ScreenParams.xy) / _ScreenParams.y;
     float2 m = iMouse.xy / _ScreenParams.xy;

     // camera 
    float3 ro = 4.0 * normalize(float3 (sin(3.0 * m.x) , 0.8 * m.y , cos(3.0 * m.x))) - float3 (0.0 , 0.1 , 0.0);
     float3 ta = float3 (0.0 , -1.0 , 0.0);
    float3x3 ca = setCamera(ro , ta , 0.07 * cos(0.25 * _Time.y));
    // ray 
   float3 rd = mul(ca , normalize(float3 (p.xy , 1.5)));

   fragColor = render(ro , rd , int2 (fragCoord - 0.5));
   return fragColor;
}

//void mainVR(out float4 fragColor , in float2 fragCoord , in float3 fragRayOri , in float3 fragRayDir)
// {
//    fragColor = render(fragRayOri , fragRayDir , int2 (fragCoord - 0.5));
// return fragColor;
//}

//half4 LitPassFragment(Varyings input) : SV_Target
//{
//    [FRAGMENT]
//    //float2 uv = input.uv;
//    //SAMPLE_TEXTURE2D_LOD(_BaseMap, sampler_BaseMap, uv + float2(-onePixelX, -onePixelY), _Lod);
//    //_ScreenParams.xy 
//    //half4 color = half4(1, 1, 1, 1);
//    //return color;
//}
ENDHLSL
}
        }
}