using System.IO;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace ECHLabs.EditorTools
{
    /// <summary>
    /// Physically based URP materials for the labs (glass, epoxy resin worktops, brushed steel,
    /// instrument plastics, liquids…). Re-running updates existing assets in place, so prefabs and
    /// scenes keep their references.
    /// </summary>
    public static class MaterialLibrary
    {
        public const string Dir = "Assets/ECHLabs/Art/Materials";

        static Material Lit(string name, Color color, float smoothness, float metallic = 0, Color? emission = null)
        {
            var m = LoadOrCreate(name, Shader.Find("Universal Render Pipeline/Lit"));
            m.SetColor("_BaseColor", color);
            m.SetFloat("_Smoothness", smoothness);
            m.SetFloat("_Metallic", metallic);
            m.SetFloat("_Surface", 0);
            m.DisableKeyword("_SURFACE_TYPE_TRANSPARENT");
            m.renderQueue = (int)RenderQueue.Geometry;
            // Emission is always enabled (black by default) so equipment can glow when highlighted.
            m.EnableKeyword("_EMISSION");
            m.globalIlluminationFlags = emission.HasValue ? MaterialGlobalIlluminationFlags.BakedEmissive : MaterialGlobalIlluminationFlags.None;
            m.SetColor("_EmissionColor", emission ?? Color.black);
            if (emission.HasValue) m.EnableKeyword("_EMISSION_LOCKED");
            EditorUtility.SetDirty(m);
            return m;
        }

        static Material Glass(string name, Color tint, float smoothness = 0.97f)
        {
            var m = LoadOrCreate(name, Shader.Find("Universal Render Pipeline/Lit"));
            m.SetColor("_BaseColor", tint);
            m.SetFloat("_Smoothness", smoothness);
            m.SetFloat("_Metallic", 0);
            m.SetFloat("_Surface", 1);       // transparent
            m.SetFloat("_Blend", 0);         // alpha: reflections scale with transparency → clear glass
            m.SetFloat("_BlendModePreserveSpecular", 0);
            m.SetFloat("_SrcBlend", (float)BlendMode.SrcAlpha);
            m.SetFloat("_DstBlend", (float)BlendMode.OneMinusSrcAlpha);
            m.SetFloat("_ZWrite", 0);
            m.SetFloat("_Cull", (float)CullMode.Back);
            m.EnableKeyword("_SURFACE_TYPE_TRANSPARENT");
            m.DisableKeyword("_ALPHAPREMULTIPLY_ON");
            m.EnableKeyword("_EMISSION");
            m.SetColor("_EmissionColor", Color.black);
            m.renderQueue = (int)RenderQueue.Transparent;
            m.SetShaderPassEnabled("ShadowCaster", false);
            EditorUtility.SetDirty(m);
            return m;
        }

        static Material LoadOrCreate(string name, Shader shader)
        {
            Directory.CreateDirectory(Dir);
            string path = $"{Dir}/{name}.mat";
            var m = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (!m) { m = new Material(shader) { name = name }; AssetDatabase.CreateAsset(m, path); }
            else if (m.shader != shader) m.shader = shader;
            return m;
        }

        // ── Library ─────────────────────────────────────────────────────────
        public static Material GlassClear => Glass("Glass_Clear", new Color(0.9f, 0.96f, 1f, 0.22f), 0.95f);
        public static Material GlassAmber => Glass("Glass_Amber", new Color(0.55f, 0.30f, 0.10f, 0.55f), 0.93f);
        public static Material GlassLens => Glass("Glass_Lens", new Color(0.8f, 0.9f, 1f, 0.25f));
        public static Material Liquid
        {
            get
            {
                var m = LoadOrCreate("Liquid", Shader.Find("ECH/Liquid"));
                EditorUtility.SetDirty(m);
                return m;
            }
        }
        public static Material PlasticWhite => Lit("Plastic_White", new Color(0.92f, 0.93f, 0.94f), 0.62f);
        public static Material PlasticGraphite => Lit("Plastic_Graphite", new Color(0.13f, 0.14f, 0.16f), 0.48f);
        public static Material PlasticBlue => Lit("Plastic_Blue", new Color(0.15f, 0.36f, 0.78f), 0.55f);
        public static Material Rubber => Lit("Rubber_Black", new Color(0.04f, 0.04f, 0.045f), 0.22f);
        public static Material SteelBrushed => Lit("Steel_Brushed", new Color(0.72f, 0.73f, 0.75f), 0.58f, 1f);
        public static Material SteelDark => Lit("Steel_Dark", new Color(0.25f, 0.26f, 0.28f), 0.5f, 1f);
        public static Material Brass => Lit("Brass", new Color(0.80f, 0.62f, 0.32f), 0.7f, 1f);
        public static Material EpoxyBlack => Lit("Worktop_Epoxy", new Color(0.055f, 0.06f, 0.065f), 0.78f);
        public static Material CabinetWhite => Lit("Cabinet_White", new Color(0.90f, 0.90f, 0.88f), 0.3f);
        public static Material FloorTerrazzo => Lit("Floor_Terrazzo", new Color(0.74f, 0.75f, 0.76f), 0.55f);
        public static Material WallPaint
        {
            get
            {
                var m = Lit("Wall_Paint", new Color(0.96f, 0.965f, 0.96f), 0.18f);
                m.SetTexture("_BaseMap", null); // clean painted walls
                m.SetTexture("_BumpMap", null);
                m.DisableKeyword("_NORMALMAP");
                return m;
            }
        }
        public static Material WallSlate => Lit("Wall_Slate", new Color(0.4f, 0.44f, 0.5f), 0.25f);
        public static Material FloorDark => Lit("Floor_Dark", new Color(0.3f, 0.32f, 0.36f), 0.62f);
        public static Material Ceiling => Lit("Ceiling", new Color(0.97f, 0.97f, 0.97f), 0.05f);
        public static Material AccentEmerald => Lit("Accent_Emerald", new Color(0.06f, 0.72f, 0.5f), 0.6f, 0, new Color(0.06f, 0.72f, 0.5f) * 1.6f);
        public static Material AccentBlue => Lit("Accent_Blue", new Color(0.23f, 0.51f, 0.96f), 0.6f, 0, new Color(0.23f, 0.51f, 0.96f) * 1.3f);
        public static Material LightPanel => Lit("Light_Panel", Color.white, 0.2f, 0, Color.white * 6f);
        public static Material Screen => Lit("Screen_Black", new Color(0.02f, 0.03f, 0.04f), 0.92f, 0, new Color(0.03f, 0.08f, 0.13f) * 1.6f);
        public static Material LedGreen => Lit("Led_Green", new Color(0.2f, 1f, 0.5f), 0.8f, 0, new Color(0.2f, 1f, 0.5f) * 3f);
        public static Material LedRed => Lit("Led_Red", new Color(1f, 0.2f, 0.15f), 0.8f, 0, new Color(1f, 0.2f, 0.15f) * 3f);
        public static Material Fabric => Lit("Fabric_White", new Color(0.95f, 0.95f, 0.96f), 0.08f);
        public static Material Wood => Lit("Wood_Light", new Color(0.80f, 0.64f, 0.42f), 0.35f);
        public static Material Ceramic => Lit("Ceramic_White", new Color(0.97f, 0.97f, 0.97f), 0.85f);
        public static Material BoardGreen => Lit("PCB_Green", new Color(0.07f, 0.32f, 0.2f), 0.55f);
        public static Material ResistorBeige => Lit("Resistor_Beige", new Color(0.86f, 0.76f, 0.58f), 0.4f);
        public static Material WireRed => Lit("Wire_Red", new Color(0.8f, 0.1f, 0.08f), 0.45f);
        public static Material WireBlack => Lit("Wire_Black", new Color(0.05f, 0.05f, 0.05f), 0.45f);
        public static Material Reticle
        {
            get { var m = LoadOrCreate("Reticle", Shader.Find("ECH/Reticle")); EditorUtility.SetDirty(m); return m; }
        }
        public static Material Laser => Lit("Laser", new Color(0.06f, 0.72f, 0.5f, 1f), 0.5f, 0, new Color(0.06f, 0.72f, 0.5f) * 4f);

        [MenuItem("ECH Labs/Rebuild materials")]
        public static void BuildAll()
        {
            _ = GlassClear; _ = GlassAmber; _ = GlassLens; _ = Liquid; _ = PlasticWhite; _ = PlasticGraphite; _ = PlasticBlue;
            _ = Rubber; _ = SteelBrushed; _ = SteelDark; _ = Brass; _ = EpoxyBlack; _ = CabinetWhite; _ = FloorTerrazzo; _ = WallPaint;
            _ = Ceiling; _ = AccentEmerald; _ = AccentBlue; _ = LightPanel; _ = Screen; _ = LedGreen; _ = LedRed; _ = Fabric; _ = Wood;
            _ = Ceramic; _ = BoardGreen; _ = ResistorBeige; _ = WireRed; _ = WireBlack; _ = Reticle; _ = Laser;
            AssetDatabase.SaveAssets();
        }

        /// <summary>Applies downloaded CC0 PBR textures (tools/asset-pipeline) when present.</summary>
        public static void ApplyDownloadedTextures()
        {
            Apply(FloorTerrazzo, "Terrazzo");
            Apply(Wood, "Wood");
            Apply(EpoxyBlack, "Epoxy");
            AssetDatabase.SaveAssets();
        }

        static void Apply(Material m, string set)
        {
            string dir = $"Assets/ECHLabs/Art/Downloaded/{set}";
            if (!Directory.Exists(dir)) return;
            var color = Find(dir, "_Color", "_albedo", "_diff");
            var normal = Find(dir, "_NormalGL", "_nor_gl", "_Normal");
            if (color) { m.SetTexture("_BaseMap", color); m.SetColor("_BaseColor", Color.white); }
            if (normal)
            {
                var imp = (TextureImporter)AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(normal));
                if (imp.textureType != TextureImporterType.NormalMap) { imp.textureType = TextureImporterType.NormalMap; imp.SaveAndReimport(); }
                m.SetTexture("_BumpMap", normal);
                m.EnableKeyword("_NORMALMAP");
            }
            m.SetTextureScale("_BaseMap", new Vector2(2, 2));
            EditorUtility.SetDirty(m);
        }

        static Texture2D Find(string dir, params string[] tags)
        {
            foreach (var f in Directory.GetFiles(dir))
                foreach (var t in tags)
                    if (f.Replace('\\', '/').ToLowerInvariant().Contains(t.ToLowerInvariant()) && (f.EndsWith(".png") || f.EndsWith(".jpg")))
                        return AssetDatabase.LoadAssetAtPath<Texture2D>(f.Replace('\\', '/'));
            return null;
        }
    }
}
