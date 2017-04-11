using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class OlsyxCrazyParrotGUI : OlsyxShaderGUI {

    bool useShadersVariation;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
        base.OnGUI(materialEditor, properties);

        GUILayout.Label("Color Gradient", EditorStyles.boldLabel);
        GradientValueVariation();
        CustomColorSection();

    }

    void CustomColorSection() {
        MaterialProperty finalColor = FindProperty("_FinalColor", properties);
        MaterialProperty slider = (!useShadersVariation) ? FindProperty("_GradientVariation", properties) : null;

        editor.ColorProperty(finalColor, "Final Color (RGB)");
    }

    void GradientValueVariation() {
        EditorGUI.BeginChangeCheck();
        useShadersVariation = EditorGUILayout.Toggle(
            MakeLabel("Shader's Variation", "Use the shader's standard variation"), IsKeywordEnabled("_USE_STANDARD_VARIATION")
        );

        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_USE_STANDARD_VARIATION", useShadersVariation);
        }

        if (!useShadersVariation) {
            MaterialProperty variationSlider = FindProperty("_GradientVariation", properties);
            editor.RangeProperty(variationSlider, "Variation Value");
        }
    }


}
