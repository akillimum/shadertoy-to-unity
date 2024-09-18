﻿
using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;

//using UnityEngine.UI;

// ReSharper disable InconsistentNaming

// ReSharper disable once CheckNamespace
namespace URP.ShaderToy
{
    public class MultiPassShader : MonoBehaviour
    {
        //public RawImage a1;
        //public RawImage a2;
        public Texture Texture1;
        public Texture Texture2;
        public Texture Texture3;
        public Texture Texture4;

        public Shader BufferA;
        /// <summary>
        /// They must follow the channel order, So if first buffer channel usage attached like "BufferB and BufferA"
        /// this must be B,A, if usage is BufferA and BufferB it must be "B,A", if no usage it must be empty
        /// If buffer uses a texture put its number as same in order,
        /// So if BufferA uses itself and BufferB and a texture which is attached to first slot, it will be
        /// "A,B,1" etc.
        /// </summary>
        public string UsePassForBufferA;
        public Shader BufferB;
        public string UsePassForBufferB;
        public Shader BufferC;
        public string UsePassForBufferC;
        public Shader BufferD;
        public string UsePassForBufferD;
        public Shader MainImage; //it is the last drawing shader, it maybe always attached!!
        public string UsePassForMainImage;

        //A is for buffer A :) Last one is M for MainImage :)
        RenderTexture _rtA1, _rtA2, _rtA, _rtB1, _rtB2, _rtB, _rtC1, _rtC2, _rtC, _rtD1, _rtD2, _rtD, _rtM1, _rtM2, _rtM;

        private List<Renderer> _renderers;
        [NonSerialized]
        public Material _m1, _m2, _m3, _m4, _m5;
        private bool _change;

        // Start is called before the first frame update
        // ReSharper disable once ArrangeTypeMemberModifiers
        // ReSharper disable once UnusedMember.Local
        void Start()
        {
            int width = Screen.width + Screen.width % 2;
            int height = Screen.height + Screen.height % 2;
            int depth = 0; //32;
            //_rtA1 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
            //https://forum.unity.com/threads/how-to-write-negative-values-to-render-textures.536963/
            _rtA1 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _rtA2 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _rtB1 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _rtB2 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _rtC1 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _rtC2 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _rtD1 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _rtD2 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _rtM1 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _rtM2 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _rtA1.useMipMap = true;
            _rtA2.useMipMap = true;
            _rtB1.useMipMap = true;
            _rtB2.useMipMap = true;
            _rtC1.useMipMap = true;
            _rtC2.useMipMap = true;
            _rtD1.useMipMap = true;
            _rtD2.useMipMap = true;
            _rtM1.useMipMap = true;
            _rtM2.useMipMap = true;
            _rtA1.autoGenerateMips = true;
            _rtA2.autoGenerateMips = true;
            _rtB1.autoGenerateMips = true;
            _rtB2.autoGenerateMips = true;
            _rtC1.autoGenerateMips = true;
            _rtC2.autoGenerateMips = true;
            _rtD1.autoGenerateMips = true;
            _rtD2.autoGenerateMips = true;
            _rtM1.autoGenerateMips = true;
            _rtM2.autoGenerateMips = true;

            _renderers = this.GetComponentsInChildren<Renderer>().ToList();

            RenderPipelineManager.beginCameraRendering += RenderPipelineManager_beginCameraRendering;
        }

        private void RenderPipelineManager_beginCameraRendering(ScriptableRenderContext arg1, Camera arg2)
        {
            CheckBuffer(BufferA, UsePassForBufferA, ref _m1, ref _rtA1, ref _rtA2, ref _rtA);
            CheckBuffer(BufferB, UsePassForBufferB, ref _m2, ref _rtB1, ref _rtB2, ref _rtB);
            CheckBuffer(BufferC, UsePassForBufferC, ref _m3, ref _rtC1, ref _rtC2, ref _rtC);
            CheckBuffer(BufferD, UsePassForBufferD, ref _m4, ref _rtD1, ref _rtD2, ref _rtD);
            CheckBuffer(MainImage, UsePassForMainImage, ref _m5, ref _rtM1, ref _rtM2, ref _rtM);


            //if(a1) a1.texture = _rt1a;
            //if(a2) a2.texture = _rt1b;
            
            if (_renderers != null && _renderers.Count > 0)
            {
                foreach (var ren in _renderers)
                {
                    //this is just for to draw, nothing special
                    ren.sharedMaterial.SetTexture("_Channel0", _rtM);
                }
            }

            _change = !_change; //!!
        }

        private void CheckBuffer(Shader buffer, string usePassForBuffer, ref Material m, 
            ref RenderTexture r1, ref RenderTexture r2, ref RenderTexture latest)
        {
            if (buffer != null)
            {
                if (m == null) m = new Material(buffer);
                if (!string.IsNullOrWhiteSpace(usePassForBuffer))
                {
                    var buffers = usePassForBuffer.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                    for (int i = 0; i < buffers.Length; i++)
                    {
                        if (buffers[i] == "A")
                            m.SetTexture("_Channel" + i, _rtA);
                        if (buffers[i] == "B")
                            m.SetTexture("_Channel" + i, _rtB);
                        if (buffers[i] == "C")
                            m.SetTexture("_Channel" + i, _rtC);
                        if (buffers[i] == "D")
                            m.SetTexture("_Channel" + i, _rtD);
                        if (buffers[i] == "1")
                            m.SetTexture("_Channel" + i, Texture1);
                        if (buffers[i] == "2")
                            m.SetTexture("_Channel" + i, Texture2);
                        if (buffers[i] == "3")
                            m.SetTexture("_Channel" + i, Texture3);
                        if (buffers[i] == "4")
                            m.SetTexture("_Channel" + i, Texture4);
                    }
                }

                if (_change)
                {
                    Graphics.Blit(r1, r2, m);
                    latest = r2;
                }
                else
                {
                    Graphics.Blit(r2, r1, m);
                    latest = r1;
                }
            }
        }

        // ReSharper disable once ArrangeTypeMemberModifiers
        // ReSharper disable once UnusedMember.Local
        void OnDestroy()
        {
            _rtA1.Release();
            _rtA2.Release();
            _rtB1.Release();
            _rtB2.Release();
            _rtC1.Release();
            _rtC2.Release();
            _rtD1.Release();
            _rtD2.Release();
            _rtM1.Release();
            _rtM2.Release();

            RenderPipelineManager.beginCameraRendering -= RenderPipelineManager_beginCameraRendering;
        }
    }
}
//using System.Collections;
//using System.Collections.Generic;
//using System.Linq;
//using UnityEngine;

//namespace URP.ShaderToy
//{
//    public class MultiPassShader : MonoBehaviour
//    {
//        public Shader[] Shaders;
//        RenderTexture _rt1, _rt2, _rt3, _rt4, _rt5;
//        private List<Renderer> _renderers;
//        private Material _m1, _m2, _m3, _m4, _m5;

//        // Start is called before the first frame update
//        void Start()
//        {
//            int width = Screen.width + Screen.width % 2;
//            int height = Screen.height + Screen.height % 2;
//            int depth = 32;
//            _rt1 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
//            _rt2 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
//            _rt3 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
//            _rt4 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
//            _rt5 = new RenderTexture(width, height, depth, RenderTextureFormat.ARGBFloat);  //buffer must be floating point RT
//            _rt1.useMipMap = true;
//            _rt2.useMipMap = true;
//            _rt3.useMipMap = true;
//            _rt4.useMipMap = true;
//            _rt5.useMipMap = true;
//            _rt1.autoGenerateMips = true;
//            _rt2.autoGenerateMips = true;
//            _rt3.autoGenerateMips = true;
//            _rt4.autoGenerateMips = true;
//            _rt5.autoGenerateMips = true;

//            if(Shaders.Length>0)
//                _m1 = new Material(Shaders[0]);
//            if (Shaders.Length > 1)
//                _m2 = new Material(Shaders[1]);
//            if (Shaders.Length > 2)
//                _m3 = new Material(Shaders[2]);
//            if (Shaders.Length > 3)
//                _m4 = new Material(Shaders[3]);
//            if (Shaders.Length > 4)
//                _m5 = new Material(Shaders[4]);

//            _renderers = this.GetComponentsInChildren<Renderer>().ToList();
//        }

//        // Update is called once per frame
//        void Update()
//        {
//            Graphics.Blit(_rt1, _rt2, _m1);

//            _m2.SetTexture("_Channel0",_rt2);
//            Graphics.Blit(_rt2, _rt3, _m2);

//            if (_renderers != null && _renderers.Count > 0)
//            {
//                foreach (var ren in _renderers)
//                {
//                    ren.sharedMaterial.SetTexture("_Channel0", _rt3);
//                }
//            }
//        }

//        void OnDestroy()
//        {
//            _rt1.Release();
//            _rt2.Release();
//            _rt3.Release();
//            _rt4.Release();
//            _rt5.Release();
//        }
//    }
//}