using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NormalsRenderer : MonoBehaviour {
    
    public Shader NormalsRender;
    Camera Camera;
    Camera TempCamera;

	void Start () {
        Camera = GetComponent<Camera>();
        //SetTemporaryCamera();

        Camera.SetReplacementShader(NormalsRender, "");
    }

    void SetTemporaryCamera() {
        TempCamera = new GameObject("RenderCamera").AddComponent<Camera>();
        TempCamera.transform.parent = transform;
        TempCamera.transform.localPosition = new Vector3(0, 0, 0);

    }
	
	void OnRenderImage(RenderTexture source, RenderTexture destination) {
        Graphics.Blit(source, destination);
	}
}
 