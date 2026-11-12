using UnityEngine;

namespace ECHLabs.Runtime.Equipment
{
    /// <summary>
    /// Drives the ECH/Liquid shader on a container's inner mesh: fill height from a millilitre
    /// value (via the container's real volume→height curve), colour, and a damped wobble that
    /// reacts to the container being moved or swirled.
    /// </summary>
    [RequireComponent(typeof(Renderer))]
    public sealed class LiquidVolume : MonoBehaviour
    {
        [Tooltip("Container capacity in mL (full = top of inner mesh)")] public float capacityMl = 250;
        [Tooltip("Height (local, normalized 0..1 of inner mesh) for a given fraction of volume. Baked by PrefabFactory from the lathe profile.")]
        public AnimationCurve volumeToHeight = AnimationCurve.Linear(0, 0, 1, 1);
        [Tooltip("Graduated tubes (burette): volume is measured from the TOP; liquid still fills from the bottom.")]
        public bool bottomUp = true;

        public float wobbleSpring = 32f, wobbleDamping = 4.5f, wobbleMax = 0.035f;

        Renderer rend;
        MaterialPropertyBlock mpb;
        Vector3 lastPos, lastEuler;
        float wobbleX, wobbleZ, velX, velZ, pulse;
        float minY = 0, maxY = 1;

        static readonly int FillId = Shader.PropertyToID("_FillWorldY");
        static readonly int ColorId = Shader.PropertyToID("_LiquidColor");
        static readonly int TopColorId = Shader.PropertyToID("_SurfaceColor");
        static readonly int WobbleXId = Shader.PropertyToID("_WobbleX");
        static readonly int WobbleZId = Shader.PropertyToID("_WobbleZ");
        static readonly int VisibleId = Shader.PropertyToID("_Visible");

        public float VolumeMl { get; private set; }
        public Color Color { get; private set; } = new Color(0.9f, 0.95f, 1f, 0.15f);

        void Awake() => Init();

        void Init()
        {
            if (rend) return;
            rend = GetComponent<Renderer>();
            mpb = new MaterialPropertyBlock();
            var mf = GetComponent<MeshFilter>();
            if (mf && mf.sharedMesh) { minY = mf.sharedMesh.bounds.min.y; maxY = mf.sharedMesh.bounds.max.y; }
            lastPos = transform.position;
            lastEuler = transform.eulerAngles;
        }

        public void Set(float volumeMl, Color color)
        {
            VolumeMl = Mathf.Clamp(volumeMl, 0, capacityMl * 1.02f);
            Color = color;
        }

        /// <summary>A splash from pouring in: kicks the wobble.</summary>
        public void Splash(float strength = 1f) => pulse = Mathf.Max(pulse, strength);

        void LateUpdate()
        {
            Init();
            float dt = Mathf.Max(Time.deltaTime, 1e-4f);
            Vector3 v = (transform.position - lastPos) / dt;
            Vector3 av = (transform.eulerAngles - lastEuler);
            av = new Vector3(Mathf.DeltaAngle(0, av.x), 0, Mathf.DeltaAngle(0, av.z)) / dt;
            lastPos = transform.position;
            lastEuler = transform.eulerAngles;

            // Damped spring per axis, excited by motion (and splashes).
            float exX = Mathf.Clamp(v.x * 0.02f + av.z * 0.0002f, -wobbleMax, wobbleMax) + pulse * 0.01f * Mathf.Sin(Time.time * 37f);
            float exZ = Mathf.Clamp(v.z * 0.02f + av.x * 0.0002f, -wobbleMax, wobbleMax) + pulse * 0.01f * Mathf.Cos(Time.time * 41f);
            velX += (-wobbleSpring * wobbleX - wobbleDamping * velX) * dt + exX;
            velZ += (-wobbleSpring * wobbleZ - wobbleDamping * velZ) * dt + exZ;
            wobbleX = Mathf.Clamp(wobbleX + velX * dt, -wobbleMax, wobbleMax);
            wobbleZ = Mathf.Clamp(wobbleZ + velZ * dt, -wobbleMax, wobbleMax);
            pulse = Mathf.MoveTowards(pulse, 0, dt * 1.5f);

            float frac = capacityMl > 0 ? Mathf.Clamp01(VolumeMl / capacityMl) : 0;
            float h01 = Mathf.Clamp01(volumeToHeight.Evaluate(frac));
            float localY = Mathf.Lerp(minY, maxY, h01);
            float worldY = transform.TransformPoint(new Vector3(0, localY, 0)).y;

            rend.GetPropertyBlock(mpb);
            mpb.SetFloat(FillId, worldY);
            mpb.SetColor(ColorId, Color);
            mpb.SetColor(TopColorId, Color.Lerp(Color, Color.white, 0.25f));
            mpb.SetFloat(WobbleXId, wobbleX);
            mpb.SetFloat(WobbleZId, wobbleZ);
            mpb.SetFloat(VisibleId, VolumeMl > 0.01f ? 1 : 0);
            rend.SetPropertyBlock(mpb);
        }
    }
}
