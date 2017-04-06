using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class OlsyxTransitionGUI : OlsyxShaderGUI {

    protected enum OverlapMode {
        Full, Multiply
    }

    bool useShadersVariation;
    bool dissolveOnTransition;
    bool useColorRampForTransition;
    public AnimationCurve colorCurve = AnimationCurve.Linear(0, 0, 1, 0);
    
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
        base.OnGUI(materialEditor, properties);

        GUILayout.Label("Transition Maps", EditorStyles.boldLabel);

        Variation();
        Dissolve();
        FinalAlbedo();
        FinalNormals();
        Masks();
    }


    void Variation() {
        EditorGUI.BeginChangeCheck();
        useShadersVariation = EditorGUILayout.Toggle(
            MakeLabel("Shader's Variation", "Use the shader's standard variation"), IsKeywordEnabled("_USE_STANDARD_VARIATION")
        );

        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_USE_STANDARD_VARIATION", useShadersVariation);
        }

        if (useShadersVariation) {
            MaterialProperty speed = FindProperty("_TransitionSpeed", properties);
            editor.FloatProperty(speed, "Transition Speed");
        } else { 
            MaterialProperty variationSlider = FindProperty("_TransitionValue", properties);
            editor.RangeProperty(variationSlider, "Variation Value");
        }
    }

    void Dissolve() {
        EditorGUI.BeginChangeCheck();
        dissolveOnTransition = EditorGUILayout.Toggle(
            MakeLabel("Dissolve", "Should the object disappear on transition?"), IsKeywordEnabled("_DO_DISSOLVE_CLIPPING")
        );

        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_DO_DISSOLVE_CLIPPING", dissolveOnTransition);
        }
    }

    void FinalAlbedo() {
        if (!dissolveOnTransition) {
            OverlapModeToggle();

            MaterialProperty tint = FindProperty("_FinalTint", properties);
            MaterialProperty map = FindProperty("_FinalTex", properties);

            editor.TexturePropertySingleLine(MakeLabel(map, "Albedo (RGB)"), map, tint);
            MaterialProperty slider = FindProperty("_TransitionThreshold", properties);
        }
    }

    void FinalNormals() {
        MaterialProperty map = FindProperty("_FinalNormals", properties);
        Texture tex = map.textureValue;
        MaterialProperty bump = tex ? FindProperty("_FinalBumpScale", properties) : null;
        editor.TexturePropertySingleLine(MakeLabel(map, "Normals"), map, bump);
    }

    void Masks() {
        MaterialProperty mask = FindProperty("_TransitionMask", properties);
        MaterialProperty variationSlider = FindProperty("_TransitionThreshold", properties);
        editor.TexturePropertySingleLine(MakeLabel(mask, "Mask (RGB)"), mask, variationSlider);

        UseColorRamp();

        if (useColorRampForTransition) {
            MaterialProperty colorRamp = FindProperty("_ColorRamp", properties);
            MaterialProperty colorSlider = FindProperty("_TransitionColorAmount", properties);
            editor.TexturePropertySingleLine(MakeLabel(colorRamp, "Color Ramp (RGB)"), colorRamp, colorSlider);
        }
    }

    void UseColorRamp() {
        EditorGUI.BeginChangeCheck();
        useColorRampForTransition = EditorGUILayout.Toggle(
            MakeLabel("Use Color Ramp", "Use a color ramp for the transition edges"), IsKeywordEnabled("_ADD_COLOR_TO_DISSOLVE")
        );

        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_ADD_COLOR_TO_DISSOLVE", useColorRampForTransition);
        }
    }


    // - Sub Sections -
    void OverlapModeToggle() {
        OverlapMode mode = OverlapMode.Full;

        if (IsKeywordEnabled("_OVERLAP_FULL_TEXTURE")) {
            mode = OverlapMode.Full;
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
    
    
}
