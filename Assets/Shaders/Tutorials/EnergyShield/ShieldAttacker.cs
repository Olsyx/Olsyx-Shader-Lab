using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class ShieldAttacker : MonoBehaviour {

    public float radius;
    public float cadence;
    public float projectileLife;
    public ShieldController shield;

    private float timer;
    private List<Vector4> projectiles = new List<Vector4>();

    void Start() {
    }

    void Update() {

        timer += Time.deltaTime;
        if (timer > cadence) {
            Shoot();
            timer -= cadence;
        }

        UpdateProjectiles();
        shield.points = projectiles.ToArray();
    }

    void Shoot() {
        Vector3 point = Random.onUnitSphere * radius;
        projectiles.Add(new Vector4(point.x, point.y, point.z, 0f));
    }

    void UpdateProjectiles() {
        for (int i = 0; i < projectiles.Count; i++) {
            Vector4 point = projectiles[i];
            point.w += Time.deltaTime / projectileLife;
            projectiles[i] = point;
        }

        for (int i = projectiles.Count - 1; i >= 0; i--) {
            if (projectiles[i].w > projectileLife) {
                projectiles.Remove(projectiles[i]);
            }
        }
    }
}
