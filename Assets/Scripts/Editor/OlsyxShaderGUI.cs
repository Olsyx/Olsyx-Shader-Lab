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

        MainSection();
        SecondarySection();
    }

    void MainSection() {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);

        MaterialProperty mainTex = FindProperty("_MainTex", properties);

        MaterialProperty tint = FindProperty("_Tint", properties);
        editor.TexturePropertySingleLine(MakeLabel(mainTex, "Albedo (RGB)"), mainTex, tint);

        RenderingModeSection();
        if (showAlphaCutoff)
            AlphaCutoff();
        MetallicSection();
        SmoothnessSection();
        NormalsSection();
        OcclusionSection();
        EmissionSection();
        DetailsSection();

        editor.TextureScaleOffsetProperty(mainTex);
    }

    void RenderingModeSection() {
        RenderingMode mode = RenderingMode.Opaque;
        showAlphaCutoff = false;
        if (IsKeywordEnabled("_RENDERING_CUTOUT")) {
            mode = RenderingMode.Cutout;
            showAlphaCutoff = true;
        } else if (IsKeywordEnabled("_RENDERING_FADE")) {
            mode = RenderingMode.Fade;
        } else if (IsKeywordEnabled("_RENDERING_TRANSPARENT")) {
            mode = RenderingMode.Transparent;
        }

        EditorGUI.BeginChangeCheck();
        mode = (RenderingMode)EditorGUILayout.EnumPopup(MakeLabel("Rendering Mode"), mode);
        if (EditorGUI.EndChangeCheck()) {
            RecordAction("Rendering Mode");
            SetKeyword("_RENDERING_CUTOUT", mode == RenderingMode.Cutout);
            SetKeyword("_RENDERING_FADE", mode == RenderingMode.Fade);
            SetKeyword("_RENDERING_TRANSPARENT", mode == RenderingMode.Transparent);

            RenderingSettings settings = RenderingSettings.modes[(int)mode];
            foreach (Material m in editor.targets) {
                m.renderQueue = (int)settings.queue;
                m.SetOverrideTag("RenderType", settings.renderType);
                m.SetInt("_SrcBlend", (int)settings.srcBlend);
                m.SetInt("_DstBlend", (int)settings.dstBlend);
                m.SetInt("_ZWrite", settings.zWrite ? 1 : 0);
            }
        }

        if (mode == RenderingMode.Fade || mode == RenderingMode.Transparent)
            SemitransparentShadows();
    }

    void SemitransparentShadows() {
        EditorGUI.BeginChangeCheck();
        bool semitransparentShadows = EditorGUILayout.Toggle(
            MakeLabel("Semitransp. Shadows", "Semitransparent Shadows"), IsKeywordEnabled("_SEMITRANSPARENT_SHADOWS")
        );

        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_SEMITRANSPARENT_SHADOWS", semitransparentShadows);
        }

        if (!semitransparentShadows)
            showAlphaCutoff = true;
    }

    void AlphaCutoff() {
        MaterialProperty slider = FindProperty("_AlphaCutoff", properties);
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(slider, MakeLabel(slider));
        EditorGUI.indentLevel -= 2;
    }

    void MetallicSection() {
        MaterialProperty map = FindProperty("_MetallicMap", properties);
        Texture tex = map.textureValue;
        MaterialProperty slider = tex ? null : FindProperty("_Metallic", properties);

        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(MakeLabel(map, "Metallic (R)"), map, slider);
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
            SetKeyword("_METALLIC_MAP", map.textureValue);
    }

    void OcclusionSection() {
        MaterialProperty map = FindProperty("_OcclusionMap", properties);
        Texture tex = map.textureValue;
        MaterialProperty slider = tex ? FindProperty("_OcclusionStrength", properties) : null;

        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(MakeLabel(map, "Occlusion (G)"), map, slider);
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
            SetKeyword("_OCCLUSION_MAP", map.textureValue);
    }

    void SmoothnessSection() {
        SmoothnessSource source = SmoothnessSource.Uniform;
        if (IsKeywordEnabled("_SMOOTHNESS_ALBEDO")) {
            source = SmoothnessSource.Albedo;
        } else if (IsKeywordEnabled("_SMOOTHNESS_METALLIC")) {
            source = SmoothnessSource.Metallic;
        }

        MaterialProperty slider = FindProperty("_Smoothness", properties);
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(slider, MakeLabel(slider));
        EditorGUI.indentLevel += 1;
        EditorGUI.BeginChangeCheck();
        source = (SmoothnessSource)EditorGUILayout.EnumPopup(MakeLabel("Source"), source);

        if (EditorGUI.EndChangeCheck()) {
            RecordAction("Smoothness Source");
            SetKeyword("_SMOOTHNESS_ALBEDO", source == SmoothnessSource.Albedo);
            SetKeyword("_SMOOTHNESS_METALLIC", source == SmoothnessSource.Metallic);
        }
        EditorGUI.indentLevel -= 3;
    }

    void NormalsSection() {
        MaterialProperty map = FindProperty("_NormalMap", properties);
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        MaterialProperty bump = tex ? FindProperty("_BumpScale", properties) : null;
        editor.TexturePropertySingleLine( MakeLabel(map), map, bump);
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
            SetKeyword("_NORMAL_MAP", map.textureValue);
    }

    void EmissionSection() {
        MaterialProperty map = FindProperty("_EmissionMap", properties);
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertyWithHDRColor(
            MakeLabel(map, "Emission (RGB)"), map, FindProperty("_Emission", properties), emissionConfig, false
           );
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
            SetKeyword("_EMISSION_MAP", map.textureValue);
    }

    void DetailsSection() {
        MaterialProperty mask = FindProperty("_DetailMask", properties);
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(MakeLabel(mask, "Detail Mask (A)"), mask);
        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_DETAIL_MASK", mask.textureValue);
        }
    }

    // -- SECONDARY -- //

    void SecondarySection() {
        GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);

        MaterialProperty detailTex = FindProperty("_DetailTex", properties);
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine( MakeLabel(detailTex, "Albedo (RGB) multiplied by 2"), detailTex );
        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_DETAIL_ALBEDO_MAP", detailTex.textureValue);
        }

        SecondaryNormalsSection();

        editor.TextureScaleOffsetProperty(detailTex);
    }

    void SecondaryNormalsSection() {
        MaterialProperty map = FindProperty("_DetailNormalMap", properties);
        Texture tex = map.textureValue;
        MaterialProperty bump = map.textureValue ? FindProperty("_DetailBumpScale", properties) : null;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(MakeLabel(map), map, bump);
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue) {
            SetKeyword("_DETAIL_NORMAL_MAP", map.textureValue);
        }
    }

    // -- UTILS -- //
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
