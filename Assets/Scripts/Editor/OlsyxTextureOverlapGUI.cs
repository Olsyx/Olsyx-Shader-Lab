using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class OlsyxTextureOverlapGUI : OlsyxShaderGUI {

    protected enum OverlapMode {
        Full, Multiply
    }

    bool useShadersVariation;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
        base.OnGUI(materialEditor, properties);

        GUILayout.Label("Texture Overlap Maps", EditorStyles.boldLabel);
        OverlapTextureModeSection();
        OverlapValueVariation();
        OverlapBaseSection();
        OverlapNormalsSection();
        OverlapMaskSection();

    }


    void OverlapTextureModeSection() {
        OverlapMode mode = OverlapMode.Full;

        if (IsKeywordEnabled("_OVERLAP_FULL_TEXTURE")) {
            mode = OverlapMode.Full;
            showAlphaCutoff = true;
        } else if (IsKeywordEnabled("_OVERLAP_MULTIPLY_TEXTURE")) {
            mode = OverlapMode.Multiply;
        }

        EditorGUI.BeginChangeCheck();
        mode = (OverlapMode)EditorGUILayout.EnumPopup(MakeLabel("Overlapping Mode"), mode);
        if (EditorGUI.EndChangeCheck()) {
            RecordAction("Texture Overlap Mode");
            SetKeyword("_OVERLAP_FULL_TEXTURE", mode == OverlapMode.Full);
            SetKeyword("_OVERLAP_MULTIPLY_TEXTURE", mode == OverlapMode.Multiply);
        }
    }
    
    void OverlapValueVariation() {
        EditorGUI.BeginChangeCheck();
        useShadersVariation = EditorGUILayout.Toggle(
            MakeLabel("Shader's Variation", "Use the shader's standard variation"), IsKeywordEnabled("_USE_STANDARD_VARIATION")
        );

        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_USE_STANDARD_VARIATION", useShadersVariation);
        }
    }

    void OverlapBaseSection() {
        MaterialProperty tint = FindProperty("_OverlapTint", properties);
        MaterialProperty map = FindProperty("_OverlapTex", properties);        
        MaterialProperty slider = (!useShadersVariation) ? FindProperty("_OverlapValue", properties) : null;
        editor.TexturePropertySingleLine(MakeLabel(map, "Albedo (RGB)"), map, tint, slider);
        
    }

    void OverlapNormalsSection() {
        MaterialProperty map = FindProperty("_OverlapNormals", properties);
        Texture tex = map.textureValue;
        MaterialProperty bump = tex ? FindProperty("_OverlapBumpScale", properties) : null;
        editor.TexturePropertySingleLine(MakeLabel(map, "Normals"), map, bump);
    }

    void OverlapMaskSection() {
        MaterialProperty map = FindProperty("_OverlapMask", properties);
        editor.TexturePropertySingleLine(MakeLabel(map, "Mask (R)"), map);
    }
}
