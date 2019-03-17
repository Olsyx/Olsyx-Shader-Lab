using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class ToonPBRInspector : ShaderGUI {
    MaterialEditor editor;
    MaterialProperty[] properties;

    public override void OnGUI(MaterialEditor editor, MaterialProperty[] properties) {
        this.editor = editor;
        this.properties = properties;

        OutlineSection();
        GUILayout.Space(20);
        MainSection();
        GUILayout.Space(20);
        RimSection();
    }

    void OutlineSection() {
        GUILayout.Label("Outline Properties", EditorStyles.boldLabel);
        editor.ColorProperty(FindProperty("_OutlineColor"), "Color");
        editor.ShaderProperty(FindProperty("_Outline"), "Width");
    }

    #region Main
    void MainSection() {
        GUILayout.Label("Main Properties", EditorStyles.boldLabel);
        ShowRamp();
        MaterialProperty mainTex = ShowMainTex();
        ShowSpecular();
        ShowNormalMap();
        ShowOcclusion();
        editor.TextureScaleOffsetProperty(mainTex);
    }
    
    void ShowRamp() {
        editor.ColorProperty(FindProperty("_SpecularColor"), "Specular");
        editor.ColorProperty(FindProperty("_Color"), "Tint");
        editor.ColorProperty(FindProperty("_ShadowColor"), "Shadow");
    }

    MaterialProperty ShowMainTex() {
        MaterialProperty texture = FindProperty("_MainTex");        
        GUIContent propertyLabel = new GUIContent(texture.displayName);       
        editor.TexturePropertySingleLine(propertyLabel, texture);
        return texture;
    }

    void ShowSpecular() {
        MaterialProperty texture = FindProperty("_SpecularMap");
        GUIContent propertyLabel = new GUIContent(texture.displayName);
        editor.TexturePropertySingleLine(propertyLabel, texture);
        MaterialProperty slider = FindProperty("_Smoothness");
        editor.ShaderProperty(slider, slider.displayName);
    }

    void ShowNormalMap() {
        MaterialProperty map = FindProperty("_NormalMap");
        GUIContent propertyLabel = new GUIContent(map.displayName);
        editor.TexturePropertySingleLine(propertyLabel, map, map.textureValue ? FindProperty("_BumpScale") : null);
    }

    void ShowOcclusion() {
        MaterialProperty texture = FindProperty("_OcclusionTex");
        GUIContent propertyLabel = new GUIContent(texture.displayName);
        editor.TexturePropertySingleLine(propertyLabel, texture);
    }
    #endregion


    void RimSection() {
        GUILayout.Label("Rim Properties", EditorStyles.boldLabel);
        MaterialProperty useRim = FindProperty("_useRim");
        editor.ShaderProperty(useRim, "Use Rim");
        if (useRim.floatValue == 0) {
            return;
        }

        editor.ColorProperty(FindProperty("_RimColor"), "Color");
        editor.ShaderProperty(FindProperty("_RimPower"), "Power");
    }

    MaterialProperty FindProperty(string name) {
        return FindProperty(name, properties);
    }
}
