using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterController : MonoBehaviour {

    public float waveHeight;
    public List<Transform> points;
    public Material waterMaterial;

    private Vector4[] defaultVector = new Vector4[1];
    private List<Vector4> positions = new List<Vector4>();

    void Start() {
        for (int i = 0; i < points.Count; i++) {
            positions.Add(points[i].position);
        }
    }


    void Update() {
        waterMaterial.SetFloat("_WaveHeight", waveHeight);
        waterMaterial.SetInt("_ListSize", positions.Count);
        waterMaterial.SetVectorArray("_CollisionPoints", positions.Count > 0 ? positions.ToArray() : defaultVector);
        Debug.Log(positions[0]);
    }

    void OnDrawGizmos() {
        for (int i = 0; i < points.Count; i++) {
            Gizmos.DrawWireSphere(points[i].position, 0.2f);
        }
    }
}
