using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class OlsyxToonShaderGUI : OlsyxShaderGUI {
    
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
        base.OnGUI(materialEditor, properties);


        GUILayout.Label("Outline Properties", EditorStyles.boldLabel);
        OutlineSection();

        GUILayout.Label("Shading Properties", EditorStyles.boldLabel);
        CelShadingSection();

        GUILayout.Label("Main Maps", EditorStyles.boldLabel);
        MaterialProperty mainTex = AlbedoSection();

        RenderingModeSection();
        if (showAlphaCutoff)
            AlphaCutoff();

        NormalsSection();
        OcclusionSection();
        EmissionSection();

        editor.TextureScaleOffsetProperty(mainTex);

        DetailsSection();
        
    }

    void OutlineSection() {
        ColorAndSliderInLine("_OutlineColor", "Color", "_OutlineThickness", "Thickness");
    }

    void CelShadingSection() {
        ShadingRampSection();
        
        MaterialProperty specular = FindProperty("_SpecularValue", properties);
        editor.RangeProperty(specular, "Smoothness");

        MaterialProperty diffuse = FindProperty("_SpecularSteps", properties);
        editor.RangeProperty(diffuse, "Specular Steps");

        MaterialProperty unlit = FindProperty("_DiffuseSteps", properties);
        editor.RangeProperty(unlit, "Diffuse Steps");
    }

    void ShadingRampSection() {
        MaterialProperty shadingMap = FindProperty("_ShadingRamp", properties);
        Texture tex = shadingMap.textureValue;

        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(MakeLabel(shadingMap, "Shading Ramp"), shadingMap);

        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_USE_SHADING_RAMP", shadingMap.textureValue);
        }

;
    }

    MaterialProperty AlbedoSection() {
        MaterialProperty mainTex = FindProperty("_MainTex", properties);
        MaterialProperty tint = FindProperty("_Tint", properties);
        editor.TexturePropertySingleLine(MakeLabel(mainTex, "Albedo (RGB)"), mainTex, tint);
        return mainTex;
    }

    void MainSection() {

        MetallicSection();
        SmoothnessSection();

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
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue) {
            SetKeyword("_METALLIC_MAP", map.textureValue);
        }
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
        editor.TexturePropertySingleLine(MakeLabel(map), map, bump);
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
        GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);

        MaterialProperty mask = FindProperty("_DetailMask", properties);

        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(MakeLabel(mask, "Detail Mask (A)"), mask);
        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_DETAIL_MASK", mask.textureValue);
        }

        DetailsMapSection();
    }

    // -- SECONDARY -- //

    void DetailsMapSection() {
        MaterialProperty detailTex = FindProperty("_DetailTex", properties);
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(MakeLabel(detailTex, "Albedo (RGB) multiplied by 2"), detailTex);
        if (EditorGUI.EndChangeCheck()) {
            SetKeyword("_DETAIL_ALBEDO_MAP", detailTex.textureValue);
        }

        DetailsNormalsSection();

        editor.TextureScaleOffsetProperty(detailTex);
    }

    void DetailsNormalsSection() {
        MaterialProperty map = FindProperty("_DetailNormalMap", properties);
        Texture tex = map.textureValue;
        MaterialProperty bump = map.textureValue ? FindProperty("_DetailBumpScale", properties) : null;
        EditorGUI.BeginChangeCheck();
        editor.TexturePropertySingleLine(MakeLabel(map), map, bump);
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue) {
            SetKeyword("_DETAIL_NORMAL_MAP", map.textureValue);
        }
    }
}
