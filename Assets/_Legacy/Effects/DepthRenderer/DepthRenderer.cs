using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthRenderer : MonoBehaviour {

    public Material material;
    Camera camera;

	void Start () {
        camera = GetComponent<Camera>();
        camera.depthTextureMode = DepthTextureMode.Depth;	
	}
	
	void OnRenderImage(RenderTexture source, RenderTexture destination) {
        Graphics.Blit(source, destination, material);
	}
}
 