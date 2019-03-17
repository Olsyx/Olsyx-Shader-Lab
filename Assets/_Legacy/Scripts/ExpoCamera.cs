using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ExpoCamera : MonoBehaviour {

    public GameObject pivot;    // Can be a children to this object or not. We rotarte around its world position.
    public float speed;

	void Start () {
		
	}

    void Update () {
        transform.RotateAround(pivot.transform.position, Vector3.up, speed);


	}

    private void OnDrawGizmos() {
        if (pivot == null) {
            return;
        }

        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(pivot.transform.position, 1);
    }
}
