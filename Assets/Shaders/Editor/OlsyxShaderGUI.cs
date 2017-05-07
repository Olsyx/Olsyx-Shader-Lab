using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class OlsyxShaderGUI : ShaderGUI {
    protected enum SmoothnessSource {
        Uniform, Albedo, Metallic
    }

    protected enum RenderingMode {
        Opaque, Cutout, Fade, Transparent
    }

    protected struct RenderingSettings {
        public RenderQueue queue;
        public string renderType;
        public BlendMode srcBlend, dstBlend;
        public bool zWrite;

        public static RenderingSettings[] modes = {
            new RenderingSettings() {
                queue = RenderQueue.Geometry,
                renderType = "",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.Zero,
                zWrite = true
            },

            new RenderingSettings() {
                queue = RenderQueue.AlphaTest,
                renderType = "TransparentCutout",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.Zero,
                zWrite = true
            },

            new RenderingSettings() {
                queue = RenderQueue.Transparent,
                renderType = "Transparent",
                srcBlend = BlendMode.SrcAlpha,
                dstBlend = BlendMode.OneMinusSrcAlpha,
                zWrite = false
            },

            new RenderingSettings() {
                queue = RenderQueue.Transparent,
                renderType = "Transparent",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.OneMinusSrcAlpha,
                zWrite = false
            }
        };
    }

    protected static GUIContent staticLabel = new GUIContent();
    protected static ColorPickerHDRConfig emissionConfig = new ColorPickerHDRConfig(0f, 99f, 1f / 99f, 3f);

    protected Material target;
    protected MaterialEditor editor;
    protected MaterialProperty[] properties;

    protected bool showAlphaCutoff;
    
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
        this.target = materialEditor.target as Material;
        this.editor = materialEditor;
        this.properties = properties;
    }

    protected void ColorAndSlider(string colorPropertyName, string colorLabel, string sliderPropertyName, string sliderLabel) {
        MaterialProperty color = FindProperty(colorPropertyName, properties);
        MaterialProperty slider = FindProperty(sliderPropertyName, properties);

        editor.ColorProperty(color, colorLabel);
        EditorGUI.indentLevel += 2;
        editor.RangeProperty(slider, sliderLabel);
        EditorGUI.indentLevel -= 2;
    }

    protected void ColorAndSliderInLine(string colorPropertyName, string colorLabel, string sliderPropertyName, string sliderLabel) {
        MaterialProperty color = FindProperty(colorPropertyName, properties);
        MaterialProperty slider = FindProperty(sliderPropertyName, properties);


        GUILayout.BeginHorizontal();

        EditorGUIUtility.labelWidth = 115;
        editor.ColorProperty(color, colorLabel);

        EditorGUIUtility.labelWidth = 100;
        GUILayout.Label(sliderLabel);
        editor.RangeProperty(slider, "");
        EditorGUIUtility.labelWidth = 0; // Resets Width
        GUILayout.EndHorizontal();
    }

    protected bool IsKeywordEnabled (string keyword) {
        return target.IsKeywordEnabled(keyword);
    }

    protected void SetKeyword(string keyword, bool state) {
        if (state) {
            foreach (Material m in editor.targets)
                m.EnableKeyword(keyword);
        } else {
            foreach (Material m in editor.targets)
                m.DisableKeyword(keyword);
        }
    }

    protected static GUIContent MakeLabel(string text, string tooltip = null) {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    protected static GUIContent MakeLabel(MaterialProperty property, string tooltip = null) {
        staticLabel.text = property.displayName;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    protected void RecordAction(string label) {
        editor.RegisterPropertyChangeUndo(label);
    }
}
