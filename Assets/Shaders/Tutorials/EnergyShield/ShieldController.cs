using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShieldController : MonoBehaviour {

    public Vector4[] points;
    public Material shieldMaterial;

    private Vector4[] defaultVector = new Vector4[1];

    void Start() {
        
    }


    void Update() {
        shieldMaterial.SetInt("_ListSize", points.Length);
        shieldMaterial.SetVectorArray("_PointList", points.Length > 0 ? points : defaultVector);
    }
}
