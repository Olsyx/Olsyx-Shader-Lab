using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Depth_Normals : MonoBehaviour {

    public Shader NormalsRender;
    public Shader DepthRender;
    public Shader Mixer;
    Camera Camera;
    Camera NormalsCamera;
    Camera DepthCamera;

    void Start() {
        Camera = GetComponent<Camera>();
        NormalsCamera = SetTemporaryCamera(NormalsCamera);
       // DepthCamera = SetTemporaryCamera(DepthCamera);
       // DepthCamera.depthTextureMode = DepthTextureMode.Depth;

        NormalsCamera.SetReplacementShader(NormalsRender, "");
       // DepthCamera.SetReplacementShader(DepthRender, "");
        Camera.targetTexture = null;
    }

    Camera SetTemporaryCamera(Camera camera) {
        camera = new GameObject("RenderCamera").AddComponent<Camera>();
        camera.transform.parent = transform;
        camera.transform.localPosition = new Vector3(0, 0, 0);
        return camera;
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination) {
        Material mat = new Material(Mixer);
        mat.SetTexture("_MainTex", NormalsCamera.targetTexture);
      //  mat.SetTexture("_ToMix", DepthCamera.targetTexture);
        
        Graphics.Blit(source, destination, mat);
    }
}
