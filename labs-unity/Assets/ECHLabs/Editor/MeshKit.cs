using System.Collections.Generic;
using UnityEngine;

namespace ECHLabs.EditorTools
{
    /// <summary>
    /// Procedural geometry for lab equipment.
    /// Lathe(): revolves a 2D profile (radius, height) → glassware with real wall thickness,
    /// a separate inner "liquid" mesh, and an exact volume→height curve so 20.0 mL looks like 20.0 mL.
    /// RoundedBox(): bevelled boxes for instruments/furniture (edges catch highlights like real products).
    /// </summary>
    public static class MeshKit
    {
        public sealed class LatheResult
        {
            public Mesh Glass;
            public Mesh Liquid;
            public AnimationCurve VolumeToHeight; // volume fraction → height fraction of the liquid mesh
            public float CapacityMl;               // geometric capacity of the liquid region
        }

        /// <summary>
        /// profile: outer surface from bottom-centre upward, (radius, y) in metres; first point radius 0.
        /// wall: glass thickness. liquidFrom/liquidTo: y range the liquid may occupy (inner).
        /// </summary>
        public static LatheResult Lathe(string name, IList<Vector2> profile, float wall, int segments = 48, float? liquidTo = null, float liquidFrom = -1f)
        {
            var outer = new List<Vector2>(profile);
            var inner = Offset(outer, wall);
            var glass = new Mesh { name = name + "_glass" };
            var verts = new List<Vector3>(); var norms = new List<Vector3>(); var uvs = new List<Vector2>(); var tris = new List<int>();

            Revolve(outer, segments, false, verts, norms, uvs, tris);
            Revolve(inner, segments, true, verts, norms, uvs, tris);
            // Rim: connect last outer point to last inner point.
            Revolve(new List<Vector2> { inner[inner.Count - 1], outer[outer.Count - 1] }, segments, false, verts, norms, uvs, tris, rim: true);
            glass.SetVertices(verts); glass.SetNormals(norms); glass.SetUVs(0, uvs); glass.SetTriangles(tris, 0);
            glass.RecalculateBounds(); glass.RecalculateTangents(); FixWinding(glass);

            // Liquid: inner profile shrunk slightly, clipped to the liquid range, closed at the bottom.
            float top = liquidTo ?? inner[inner.Count - 1].y - 0.002f;
            float bottom = liquidFrom >= 0 ? liquidFrom : inner[0].y;
            var lp = ClipProfile(Offset(inner, 0.0006f), bottom, top);
            var liquid = new Mesh { name = name + "_liquid" };
            verts.Clear(); norms.Clear(); uvs.Clear(); tris.Clear();
            Revolve(lp, segments, false, verts, norms, uvs, tris);
            liquid.SetVertices(verts); liquid.SetNormals(norms); liquid.SetUVs(0, uvs); liquid.SetTriangles(tris, 0);
            liquid.RecalculateBounds(); FixWinding(liquid);

            // Volume integral along y (frustum slices): V(h) = Σ π/3 (r0² + r0 r1 + r1²) Δy.
            var curve = new AnimationCurve();
            float total = 0;
            var cumulative = new List<(float y, float v)> { (lp[0].y, 0) };
            for (int i = 0; i < lp.Count - 1; i++)
            {
                float r0 = lp[i].x, r1 = lp[i + 1].x, dy = lp[i + 1].y - lp[i].y;
                if (dy <= 0) continue;
                total += Mathf.PI / 3f * (r0 * r0 + r0 * r1 + r1 * r1) * dy;
                cumulative.Add((lp[i + 1].y, total));
            }
            float y0 = liquid.bounds.min.y, y1 = liquid.bounds.max.y;
            foreach (var (y, v) in cumulative)
                curve.AddKey(new Keyframe(total > 0 ? v / total : 0, Mathf.InverseLerp(y0, y1, y)));
            for (int k = 0; k < curve.length; k++) curve.SmoothTangents(k, 0);
            return new LatheResult { Glass = glass, Liquid = liquid, VolumeToHeight = curve, CapacityMl = total * 1e6f };
        }

        static List<Vector2> Offset(List<Vector2> p, float d)
        {
            var o = new List<Vector2>(p.Count);
            for (int i = 0; i < p.Count; i++)
            {
                Vector2 a = p[Mathf.Max(i - 1, 0)], b = p[Mathf.Min(i + 1, p.Count - 1)];
                Vector2 tangent = (b - a).normalized;
                Vector2 normal = new Vector2(tangent.y, -tangent.x); // outward for a bottom→top profile
                var q = p[i] - normal * d;
                if (i == 0) q = new Vector2(0, p[0].y + d);           // inner bottom centre
                o.Add(new Vector2(Mathf.Max(q.x, 0), q.y));
            }
            return o;
        }

        static List<Vector2> ClipProfile(List<Vector2> p, float from, float to)
        {
            var o = new List<Vector2>();
            for (int i = 0; i < p.Count; i++)
            {
                if (p[i].y < from) continue;
                if (p[i].y > to)
                {
                    if (i > 0 && p[i - 1].y < to) o.Add(new Vector2(Mathf.Lerp(p[i - 1].x, p[i].x, Mathf.InverseLerp(p[i - 1].y, p[i].y, to)), to));
                    break;
                }
                if (o.Count == 0 && i > 0 && from > p[0].y) o.Add(new Vector2(0, from));
                o.Add(p[i]);
            }
            if (o.Count > 0 && o[0].x > 0) o.Insert(0, new Vector2(0, o[0].y));
            return o;
        }

        static void Revolve(List<Vector2> prof, int seg, bool flip, List<Vector3> v, List<Vector3> n, List<Vector2> uv, List<int> t, bool rim = false)
        {
            int start = v.Count;
            float length = 0;
            var acc = new float[prof.Count];
            for (int i = 1; i < prof.Count; i++) { length += Vector2.Distance(prof[i], prof[i - 1]); acc[i] = length; }
            for (int s = 0; s <= seg; s++)
            {
                float a = s / (float)seg * Mathf.PI * 2;
                float c = Mathf.Cos(a), sn = Mathf.Sin(a);
                for (int i = 0; i < prof.Count; i++)
                {
                    var p = prof[i];
                    v.Add(new Vector3(p.x * c, p.y, p.x * sn));
                    Vector2 a0 = prof[Mathf.Max(i - 1, 0)], b0 = prof[Mathf.Min(i + 1, prof.Count - 1)];
                    Vector2 tg = (b0 - a0).normalized;
                    Vector2 nn = new Vector2(tg.y, -tg.x);
                    if (flip) nn = -nn;
                    n.Add(new Vector3(nn.x * c, nn.y, nn.x * sn).normalized);
                    uv.Add(new Vector2(s / (float)seg, length > 0 ? acc[i] / length : 0));
                }
            }
            int rows = prof.Count;
            for (int s = 0; s < seg; s++)
                for (int i = 0; i < rows - 1; i++)
                {
                    int a = start + s * rows + i, b = a + rows, c2 = a + 1, d = b + 1;
                    if (!flip) { t.Add(a); t.Add(c2); t.Add(b); t.Add(b); t.Add(c2); t.Add(d); }
                    else { t.Add(a); t.Add(b); t.Add(c2); t.Add(b); t.Add(d); t.Add(c2); }
                }
        }

        /// <summary>Box with rounded edges (radius r, `smooth` subdivisions per corner).</summary>
        public static Mesh RoundedBox(string name, Vector3 size, float r, int smooth = 4)
        {
            r = Mathf.Min(r, Mathf.Min(size.x, Mathf.Min(size.y, size.z)) * 0.49f);
            Vector3 inner = size * 0.5f - Vector3.one * r;
            var verts = new List<Vector3>(); var norms = new List<Vector3>(); var uvs = new List<Vector2>(); var tris = new List<int>();
            int res = smooth * 2 + 2; // grid resolution per face
            // Build each face as a grid on a unit cube, then "round" by projecting onto the inner box + sphere offset.
            Vector3[] dirs = { Vector3.right, Vector3.left, Vector3.up, Vector3.down, Vector3.forward, Vector3.back };
            foreach (var nrm in dirs)
            {
                Vector3 u = nrm == Vector3.up || nrm == Vector3.down ? Vector3.right : Vector3.Cross(Vector3.up, nrm);
                Vector3 w = Vector3.Cross(nrm, u);
                int baseIndex = verts.Count;
                for (int i = 0; i <= res; i++)
                    for (int j = 0; j <= res; j++)
                    {
                        float a = Remap(i / (float)res, smooth), b = Remap(j / (float)res, smooth);
                        Vector3 p = nrm + u * (a * 2 - 1) + w * (b * 2 - 1);               // point on unit cube [-1,1]
                        Vector3 surf = Vector3.Scale(p, size * 0.5f);                       // point on the sharp box
                        Vector3 core = new Vector3(Mathf.Clamp(surf.x, -inner.x, inner.x), Mathf.Clamp(surf.y, -inner.y, inner.y), Mathf.Clamp(surf.z, -inner.z, inner.z));
                        Vector3 dir = (surf - core);
                        Vector3 nn = dir.sqrMagnitude > 1e-10f ? dir.normalized : nrm;
                        verts.Add(core + nn * r);
                        norms.Add(nn);
                        uvs.Add(new Vector2(a, b));
                    }
                for (int i = 0; i < res; i++)
                    for (int j = 0; j < res; j++)
                    {
                        int q = baseIndex + i * (res + 1) + j;
                        tris.Add(q); tris.Add(q + 1); tris.Add(q + res + 1);
                        tris.Add(q + 1); tris.Add(q + res + 2); tris.Add(q + res + 1);
                    }
            }
            var m = new Mesh { name = name };
            m.SetVertices(verts); m.SetNormals(norms); m.SetUVs(0, uvs); m.SetTriangles(tris, 0);
            m.RecalculateBounds(); m.RecalculateTangents();
            FixWinding(m);
            return m;
        }

        // Puts most grid lines into the rounded corners so bevels stay smooth.
        static float Remap(float t, int smooth)
        {
            float edge = 0.06f;
            int res = smooth * 2 + 2;
            int i = Mathf.RoundToInt(t * res);
            if (i <= smooth) return Mathf.Lerp(0, edge, i / (float)smooth);
            if (i >= res - smooth) return Mathf.Lerp(1 - edge, 1, (i - (res - smooth)) / (float)smooth);
            return Mathf.Lerp(edge, 1 - edge, (i - smooth) / (float)(res - 2 * smooth));
        }

        /// <summary>Flips any triangle whose winding disagrees with its vertex normals.</summary>
        static void FixWinding(Mesh m)
        {
            var v = m.vertices; var n = m.normals; var t = m.triangles;
            for (int i = 0; i < t.Length; i += 3)
            {
                Vector3 fn = Vector3.Cross(v[t[i + 1]] - v[t[i]], v[t[i + 2]] - v[t[i]]);
                if (Vector3.Dot(fn, n[t[i]] + n[t[i + 1]] + n[t[i + 2]]) < 0) { var tmp = t[i + 1]; t[i + 1] = t[i + 2]; t[i + 2] = tmp; }
            }
            m.triangles = t;
        }

        public static Mesh Cylinder(string name, float radius, float height, int segments = 32, float bevel = 0.002f)
        {
            var prof = new List<Vector2> { new Vector2(0, 0), new Vector2(radius - bevel, 0), new Vector2(radius, bevel), new Vector2(radius, height - bevel), new Vector2(radius - bevel, height), new Vector2(0, height) };
            return Solid(name, prof, segments);
        }

        /// <summary>Solid of revolution (no wall/liquid) — knobs, bobs, stands, rods.</summary>
        public static Mesh Solid(string name, IList<Vector2> profile, int segments = 32)
        {
            var verts = new List<Vector3>(); var norms = new List<Vector3>(); var uvs = new List<Vector2>(); var tris = new List<int>();
            Revolve(new List<Vector2>(profile), segments, false, verts, norms, uvs, tris);
            var m = new Mesh { name = name };
            m.SetVertices(verts); m.SetNormals(norms); m.SetUVs(0, uvs); m.SetTriangles(tris, 0);
            m.RecalculateBounds(); m.RecalculateTangents();
            FixWinding(m);
            return m;
        }

        public static Mesh Sphere(string name, float radius, int rings = 16)
        {
            var prof = new List<Vector2>();
            for (int i = 0; i <= rings; i++) { float a = -Mathf.PI / 2 + Mathf.PI * i / rings; prof.Add(new Vector2(Mathf.Cos(a) * radius, Mathf.Sin(a) * radius + radius)); }
            prof[0] = new Vector2(0, 0); prof[rings] = new Vector2(0, radius * 2);
            return Solid(name, prof, rings * 2);
        }
    }
}
