using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class Scorch : MonoBehaviour {

    Material mat;
    float currentScorch;
    
    
    void Start () {
        mat = GetComponent<Renderer>().material;
        currentScorch = 0;
    }
	
    void Update () {
        if (Input.GetKey(KeyCode.Space))
            ScorchMe();
    }

    void ScorchMe() {
        Debug.Log("Scorching!");
        if (currentScorch < 1) {
            currentScorch += (float) Math.Abs(Math.Sin(Time.deltaTime));
            if (currentScorch > 1)
                currentScorch = 1;

            mat.SetFloat("_TransitionValue", currentScorch);
        }
    }
}
