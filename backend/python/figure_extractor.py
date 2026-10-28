#!/usr/bin/env python3
"""
ECH textbook figure extractor (PyMuPDF).

Reads a PDF and writes, into an output directory:
  * one PNG per detected figure (page region rendered at a configurable DPI,
    so vector artwork, overlays and labels stay visible), and
  * figures.json describing every figure, table, equation candidate and the
    per-page reading order.

It never claims a figure is complete when it is not: every figure carries a
``quality`` value (ok | needs_review | incomplete) and a list of warnings.

Usage:
  python figure_extractor.py --pdf book.pdf --out ./out [--dpi 140]
         [--pages 1-40] [--config '{"min_image_side": 40}']

Exit code 0 on success; the summary JSON is printed on stdout.
"""

import argparse
import hashlib
import json
import os
import re
import sys

import fitz  # PyMuPDF

EXTRACTOR_VERSION = "1.0.0"

DEFAULT_CONFIG = {
    "dpi": 140,
    # Raster images smaller than this (points) are decorative icons / bullets.
    "min_image_side": 36,
    "min_image_area": 2500,
    # Images covering most of the page are page backgrounds / scans.
    "background_area_ratio": 0.85,
    # Vector drawings: gap used to cluster nearby paths into one diagram.
    "drawing_merge_gap": 14,
    "min_drawing_items": 3,
    "min_vector_area": 3000,
    # Ruled lines spanning the page (headers/footers) are not figures.
    "rule_max_thickness": 2.5,
    "rule_min_width_ratio": 0.6,
    # Merge image/vector regions closer than this into a single figure.
    "region_merge_gap": 10,
    # Short text lines this close to a region are treated as figure labels.
    "label_margin": 16,
    "label_max_chars": 48,
    # Caption search.
    "max_caption_gap": 72,
    "caption_search_height": 320,
    "min_x_overlap": 0.25,
    # Uncaptioned regions smaller than this are dropped as decorative.
    "min_uncaptioned_area": 15000,
    "render_padding": 4,
    "surrounding_chars": 700,
    "surrounding_distance": 160,
    "edge_tolerance": 3,
    "detect_tables": True,
    "table_min_filled_ratio": 0.5,
    "ocr": True,
}

CAPTION_RE = re.compile(
    r"^\s*(fig(?:ure)?s?\.?|diagram|plate|illustration|graph|chart|table|exhibit)\s*"
    r"(\d+(?:\s*[.\-–:]\s*\d+)*[a-z]?)\b",
    re.IGNORECASE,
)
CONTINUED_RE = re.compile(r"\(?\b(cont(?:inued|'d|\.)?)\b\)?", re.IGNORECASE)
PAGE_NUMBER_RE = re.compile(r"^\s*(?:page\s+)?(\d{1,4}|[ivxlcdm]{1,7})\s*$", re.IGNORECASE)
MATH_CHARS = set("=±×÷√∑∫∏∂∞≈≠≤≥→⇒∆Δπθλμσωαβγ^²³")


# ─── Geometry helpers ─────────────────────────────────────────────────────────

def rect_of(b):
    return fitz.Rect(b)


def expand(r, d):
    return fitz.Rect(r.x0 - d, r.y0 - d, r.x1 + d, r.y1 + d)


def near(a, b, gap):
    return expand(a, gap).intersects(b)


def x_overlap_ratio(a, b):
    inter = min(a.x1, b.x1) - max(a.x0, b.x0)
    if inter <= 0:
        return 0.0
    return inter / max(1.0, min(a.width, b.width))


def union_clusters(rects, gap):
    """Transitive union of rectangles closer than ``gap`` (repeat until stable)."""
    clusters = [{"rect": fitz.Rect(r["rect"]), "members": [r]} for r in rects]
    changed = True
    while changed:
        changed = False
        out = []
        for c in clusters:
            for o in out:
                if near(o["rect"], c["rect"], gap):
                    o["rect"] |= c["rect"]
                    o["members"].extend(c["members"])
                    changed = True
                    break
            else:
                out.append(c)
        clusters = out
    return clusters


def r2l(r):
    return [round(r.x0, 2), round(r.y0, 2), round(r.x1, 2), round(r.y1, 2)]


# ─── Page analysis ────────────────────────────────────────────────────────────

def text_lines(page):
    """All text lines with bbox, text and max font size, in stream order."""
    lines = []
    blocks = []
    d = page.get_text("dict")
    for b in d.get("blocks", []):
        if b.get("type") != 0:
            continue
        btext = []
        for l in b.get("lines", []):
            spans = l.get("spans", [])
            t = "".join(s.get("text", "") for s in spans).strip()
            if not t:
                continue
            size = max((s.get("size", 0) for s in spans), default=0)
            lines.append({"rect": fitz.Rect(l["bbox"]), "text": t, "size": size, "block": len(blocks)})
            btext.append(t)
        if btext:
            blocks.append({"rect": fitz.Rect(b["bbox"]), "text": " ".join(btext)})
    return lines, blocks


def image_regions(page, cfg):
    page_area = page.rect.width * page.rect.height
    out = []
    backgrounds = 0
    try:
        infos = page.get_image_info(xrefs=True)
    except Exception:  # pragma: no cover - very old PyMuPDF
        infos = []
    for info in infos:
        r = fitz.Rect(info["bbox"]) & page.rect
        if r.is_empty:
            continue
        if r.width * r.height >= cfg["background_area_ratio"] * page_area:
            backgrounds += 1
            continue
        if min(r.width, r.height) < cfg["min_image_side"] or r.width * r.height < cfg["min_image_area"]:
            continue
        out.append({"rect": r, "kind": "raster", "xref": info.get("xref", 0)})
    return out, backgrounds


def vector_regions(page, cfg):
    pw = page.rect.width
    items = []
    try:
        drawings = page.get_drawings()
    except Exception:  # pragma: no cover
        drawings = []
    for d in drawings:
        r = fitz.Rect(d.get("rect")) & page.rect
        if r.is_empty and not (r.width > 0 or r.height > 0):
            continue
        # Full-width hairlines are running-header/footer rules.
        if min(r.width, r.height) <= cfg["rule_max_thickness"] and max(r.width, r.height) >= cfg["rule_min_width_ratio"] * pw:
            continue
        # Filled white page-size rectangles are backgrounds.
        if r.width >= 0.95 * pw and r.height >= 0.95 * page.rect.height:
            continue
        items.append({"rect": fitz.Rect(r.x0, r.y0, max(r.x1, r.x0 + 0.5), max(r.y1, r.y0 + 0.5)), "kind": "vector",
                      "segments": max(1, len(d.get("items") or []))})
    clusters = union_clusters(items, cfg["drawing_merge_gap"])
    out = []
    small = []
    for c in clusters:
        r = c["rect"]
        segments = sum(m.get("segments", 1) for m in c["members"])
        if segments >= cfg["min_drawing_items"] and r.width * r.height >= cfg["min_vector_area"]:
            out.append({"rect": r, "kind": "vector", "count": segments})
        else:
            small.append({"rect": r, "kind": "vector", "count": segments})
    return out, small, items


def find_captions(lines, blocks):
    caps = []
    used_blocks = set()
    for ln in lines:
        m = CAPTION_RE.match(ln["text"])
        if not m:
            continue
        b = ln["block"]
        if b in used_blocks:
            continue
        # A caption is short-ish; a paragraph merely *mentioning* "Figure 2.1" is not.
        block = blocks[b]
        starts_block = block["text"].startswith(ln["text"][:20])
        if not starts_block:
            continue
        if len(block["text"]) > 400:
            continue
        used_blocks.add(b)
        word = m.group(1).lower()
        label = re.sub(r"\s+", "", m.group(2)).replace("–", "-")
        caps.append({
            "rect": fitz.Rect(block["rect"]),
            "text": block["text"].strip(),
            "label": label,
            "kind": "table" if word.startswith("table") else "figure",
            "continued": bool(CONTINUED_RE.search(block["text"][:80])),
            "block": b,
        })
    return caps


def merge_regions(regions, cfg):
    clusters = union_clusters([{"rect": r["rect"], **{k: v for k, v in r.items() if k != "rect"}} for r in regions],
                              cfg["region_merge_gap"])
    out = []
    for c in clusters:
        kinds = {m["kind"] for m in c["members"]}
        out.append({
            "rect": c["rect"],
            "has_raster": "raster" in kinds or any(m.get("has_raster") for m in c["members"]),
            "has_vector": "vector" in kinds or any(m.get("has_vector") for m in c["members"]),
            "parts": sum(m.get("parts", 1) for m in c["members"]),
        })
    return out


def attach_labels(region, lines, caption_blocks, cfg):
    """Grow a region to include short text labels sitting on/around it."""
    r = fitz.Rect(region["rect"])
    grown = True
    passes = 0
    while grown and passes < 3:
        grown = False
        passes += 1
        probe = expand(r, cfg["label_margin"])
        for ln in lines:
            if ln["block"] in caption_blocks:
                continue
            if len(ln["text"]) > cfg["label_max_chars"]:
                continue
            if probe.intersects(ln["rect"]) and not r.contains(ln["rect"]):
                r |= ln["rect"]
                grown = True
    region["rect"] = r
    return region


def associate_captions(regions, captions, cfg):
    """Greedy nearest match: caption below the figure first, then above."""
    pairs = []
    for ci, c in enumerate(captions):
        for ri, r in enumerate(regions):
            if x_overlap_ratio(c["rect"], r["rect"]) < cfg["min_x_overlap"]:
                continue
            below = c["rect"].y0 - r["rect"].y1      # caption under figure
            above = r["rect"].y0 - c["rect"].y1      # caption over figure (tables)
            if -4 <= below <= cfg["max_caption_gap"]:
                pairs.append((below, ci, ri))
            elif -4 <= above <= (cfg["max_caption_gap"] if c["kind"] == "table" else cfg["max_caption_gap"] / 2):
                # Captions above are common for tables, less so for figures.
                pairs.append((above + (0 if c["kind"] == "table" else 20), ci, ri))
    pairs.sort()
    cap_for_region = {}
    used_c = set()
    for _, ci, ri in pairs:
        if ci in used_c or ri in cap_for_region:
            continue
        cap_for_region[ri] = ci
        used_c.add(ci)
    return cap_for_region, used_c


def search_region_for_caption(page, caption, lines, small_vectors, all_vectors, rasters_all, cfg, taken):
    """Caption with no figure: look for drawings / images / labels above it."""
    c = caption["rect"]
    pw = page.rect.width
    # Column guess: if the caption sits in one half, search that half.
    if c.x1 <= pw * 0.55:
        x0, x1 = page.rect.x0, pw * 0.55
    elif c.x0 >= pw * 0.45:
        x0, x1 = pw * 0.45, page.rect.x1
    else:
        x0, x1 = page.rect.x0, page.rect.x1
    window = fitz.Rect(x0, max(page.rect.y0, c.y0 - cfg["caption_search_height"]), x1, c.y0)
    # Stop the window at the nearest long text block above (body paragraph).
    for ln in lines:
        if ln["rect"].y1 <= c.y0 - 2 and ln["rect"].y1 > window.y0 and len(ln["text"]) > 70 \
                and x_overlap_ratio(ln["rect"], window) > 0.5:
            window.y0 = ln["rect"].y1
    found = None
    for src in (all_vectors, rasters_all):
        for item in src:
            if window.intersects(item["rect"]) and not any(t.intersects(item["rect"]) for t in taken):
                found = fitz.Rect(item["rect"]) if found is None else found | item["rect"]
    if found is None or found.width * found.height < 400:
        return None
    return {"rect": found & window if not (found & window).is_empty else found,
            "has_raster": any(window.intersects(i["rect"]) for i in rasters_all),
            "has_vector": True, "parts": 1, "method": "caption_search"}


def column_of(rect, pw):
    if rect.width > pw * 0.6:
        return -1  # spans columns
    return 0 if (rect.x0 + rect.x1) / 2 < pw / 2 else 1


def reading_order(page, blocks, figures, tables, caption_blocks):
    """Sort text blocks, figures and tables into reading order (column-aware)."""
    pw = page.rect.width
    items = []
    for i, b in enumerate(blocks):
        if i in caption_blocks:
            continue
        if any(f["_rect"].contains(b["rect"]) for f in figures):
            continue  # label text belongs to its figure
        items.append({"type": "text", "rect": b["rect"], "ref": i, "preview": b["text"][:80]})
    for f in figures:
        items.append({"type": "figure", "rect": f["_rect"], "ref": f["id"]})
    for t in tables:
        items.append({"type": "table", "rect": fitz.Rect(t["bbox"]), "ref": t["id"]})

    two_col = sum(1 for it in items if column_of(it["rect"], pw) == 1) >= 2 and \
        sum(1 for it in items if column_of(it["rect"], pw) == 0) >= 2
    if not two_col:
        items.sort(key=lambda it: (round(it["rect"].y0, 1), it["rect"].x0))
    else:
        # Full-width items split the page into bands; inside a band read the
        # left column top-to-bottom, then the right column.
        spans = sorted([it for it in items if column_of(it["rect"], pw) == -1], key=lambda it: it["rect"].y0)
        rest = [it for it in items if column_of(it["rect"], pw) != -1]
        ordered = []
        prev_y = -1e9
        for sp in spans + [None]:
            limit = sp["rect"].y0 if sp else 1e9
            band = [it for it in rest if prev_y <= it["rect"].y0 < limit]
            band.sort(key=lambda it: (column_of(it["rect"], pw), it["rect"].y0))
            ordered.extend(band)
            if sp:
                ordered.append(sp)
                prev_y = sp["rect"].y0
        items = ordered
    return [{"type": it["type"], "ref": it["ref"], "bbox": r2l(it["rect"]),
             **({"preview": it["preview"]} if "preview" in it else {})} for it in items]


def equation_candidates(lines):
    out = []
    for ln in lines:
        t = ln["text"]
        if len(t) > 120 or len(t) < 3:
            continue
        mathy = sum(1 for ch in t if ch in MATH_CHARS)
        letters = sum(1 for ch in t if ch.isalpha())
        if ("=" in t and mathy >= 1 and letters <= len(t) * 0.6) or mathy >= 3:
            out.append({"text": t, "bbox": r2l(ln["rect"])})
    return out


def printed_page_number(lines, page):
    h = page.rect.height
    for ln in lines:
        if ln["rect"].y1 < h * 0.08 or ln["rect"].y0 > h * 0.92:
            m = PAGE_NUMBER_RE.match(ln["text"])
            if m:
                return m.group(1)
    return None


def average_hash(page, rect):
    """64-bit average hash of a region, for duplicate detection."""
    try:
        pix = page.get_pixmap(clip=rect, dpi=24, colorspace=fitz.csGRAY, alpha=False)
    except Exception:
        return None
    w, h = pix.width, pix.height
    if w < 2 or h < 2:
        return None
    s = pix.samples
    cells = []
    for gy in range(8):
        for gx in range(8):
            xs = range(gx * w // 8, max(gx * w // 8 + 1, (gx + 1) * w // 8))
            ys = range(gy * h // 8, max(gy * h // 8 + 1, (gy + 1) * h // 8))
            tot = 0
            n = 0
            for y in ys:
                row = y * pix.stride
                for x in xs:
                    tot += s[row + x]
                    n += 1
            cells.append(tot / max(1, n))
    avg = sum(cells) / 64
    bits = "".join("1" if c > avg else "0" for c in cells)
    # 16 hex digits of structure + 2 hex digits of mean brightness
    return "%016x%02x" % (int(bits, 2), int(avg) & 0xFF)


def hamming(a, b):
    """Bit distance of the structure part; mean brightness must also be close."""
    if abs(int(a[16:], 16) - int(b[16:], 16)) > 10:
        return 64
    return bin(int(a[:16], 16) ^ int(b[:16], 16)).count("1")


def try_ocr(pix_path):
    """Optional OCR with Tesseract (only if pytesseract + binary are installed)."""
    try:
        import pytesseract  # noqa: F401
        from PIL import Image
        return pytesseract.image_to_string(Image.open(pix_path)).strip()
    except Exception:
        return None


# ─── Main extraction ──────────────────────────────────────────────────────────

def extract(pdf_path, out_dir, cfg, page_range=None):
    os.makedirs(out_dir, exist_ok=True)
    with open(pdf_path, "rb") as fh:
        sha = hashlib.sha256(fh.read()).hexdigest()
    doc = fitz.open(pdf_path)
    first, last = 1, doc.page_count
    if page_range:
        first = max(1, page_range[0])
        last = min(doc.page_count, page_range[1])

    figures = []
    pages_out = []
    for pno in range(first, last + 1):
        page = doc[pno - 1]
        lines, blocks = text_lines(page)
        rasters, backgrounds = image_regions(page, cfg)
        try:
            rasters_all = [{"rect": fitz.Rect(i["bbox"]) & page.rect, "kind": "raster"} for i in page.get_image_info()]
        except Exception:
            rasters_all = []
        vectors, small_vectors, all_vectors = vector_regions(page, cfg)
        captions = find_captions(lines, blocks)
        caption_blocks = {c["block"] for c in captions}

        tables = []
        table_rects = []
        if cfg["detect_tables"] and hasattr(page, "find_tables"):
            try:
                for ti, t in enumerate(page.find_tables().tables):
                    rows = t.extract()
                    if not rows or len(rows) < 2 or max(len(r) for r in rows) < 2:
                        continue
                    # Grids of lines with (almost) no text inside are diagrams
                    # (axes, geometry), not tables.
                    cells = [c for r in rows for c in r]
                    filled = sum(1 for c in cells if c and str(c).strip())
                    if filled < max(2, cfg["table_min_filled_ratio"] * len(cells)):
                        continue
                    tr = fitz.Rect(t.bbox)
                    table_rects.append(tr)
                    tables.append({"id": f"p{pno}_t{ti + 1}", "bbox": r2l(tr),
                                   "rows": [[(c or "").strip() for c in row] for row in rows][:60]})
            except Exception:
                pass

        # Vector clusters that are really table rulings belong to the table.
        vectors = [v for v in vectors if not any(tr.contains(v["rect"]) or
                                                 (tr & v["rect"]).get_area() > 0.8 * v["rect"].get_area()
                                                 for tr in table_rects)]

        regions = merge_regions(rasters + vectors, cfg)
        regions = [attach_labels(r, lines, caption_blocks, cfg) for r in regions]
        # Label growth can make regions touch — merge again.
        if len(regions) > 1:
            regions = merge_regions([{**r, "kind": "raster" if r["has_raster"] else "vector"} for r in regions], cfg)
        for r in regions:
            r.setdefault("method", "image_bbox" if r["has_raster"] and not r["has_vector"]
                         else "vector_cluster" if r["has_vector"] and not r["has_raster"] else "merged")

        cap_for_region, used_c = associate_captions(regions, captions, cfg)

        # Table captions with a detected table and no other region.
        for ci, c in enumerate(captions):
            if ci in used_c or c["kind"] != "table":
                continue
            for t in tables:
                tr = fitz.Rect(t["bbox"])
                if x_overlap_ratio(c["rect"], tr) >= cfg["min_x_overlap"] and \
                        (abs(tr.y0 - c["rect"].y1) <= cfg["max_caption_gap"] or abs(c["rect"].y0 - tr.y1) <= cfg["max_caption_gap"]):
                    regions.append({"rect": tr, "has_raster": False, "has_vector": True, "parts": 1, "method": "table"})
                    cap_for_region[len(regions) - 1] = ci
                    used_c.add(ci)
                    t["caption"] = c["text"]
                    break

        # Captions still without a figure → search the area above for drawings.
        taken = [r["rect"] for r in regions]
        orphan_caps = []
        for ci, c in enumerate(captions):
            if ci in used_c:
                continue
            found = search_region_for_caption(page, c, lines, small_vectors, all_vectors, rasters_all, cfg, taken)
            if found:
                found = attach_labels(found, lines, caption_blocks, cfg)
                regions.append(found)
                cap_for_region[len(regions) - 1] = ci
                used_c.add(ci)
                taken.append(found["rect"])
            else:
                orphan_caps.append(c)

        page_figs = []
        for ri, r in enumerate(regions):
            cap = captions[cap_for_region[ri]] if ri in cap_for_region else None
            rect = r["rect"]
            if cap is None and rect.width * rect.height < cfg["min_uncaptioned_area"]:
                continue
            page_figs.append((r, cap))

        page_figs.sort(key=lambda rc: (rc[0]["rect"].y0, rc[0]["rect"].x0))
        page_fig_objs = []
        for idx, (r, cap) in enumerate(page_figs, start=1):
            rect = fitz.Rect(r["rect"])
            clip = expand(rect, cfg["render_padding"]) & page.rect
            fname = f"p{pno:04d}_f{idx:02d}.png"
            fpath = os.path.join(out_dir, fname)
            pix = page.get_pixmap(clip=clip, dpi=cfg["dpi"], alpha=False)
            pix.save(fpath)

            inside = []
            label_boxes = []
            for ln in lines:
                if cap and ln["block"] == cap["block"]:
                    continue
                if clip.contains(ln["rect"]) or (clip & ln["rect"]).get_area() > 0.6 * max(1e-6, ln["rect"].get_area()):
                    inside.append(ln["text"])
                    lr = ln["rect"] & clip
                    # position of the label inside the rendered image, as 0..1 fractions
                    label_boxes.append({"text": ln["text"], "box": [
                        round((lr.x0 - clip.x0) / clip.width, 4), round((lr.y0 - clip.y0) / clip.height, 4),
                        round((lr.x1 - clip.x0) / clip.width, 4), round((lr.y1 - clip.y0) / clip.height, 4)]})

            surround = []
            for b_i, b in enumerate(blocks):
                if b_i in caption_blocks or clip.contains(b["rect"]):
                    continue
                dist = min(abs(b["rect"].y1 - clip.y0), abs(b["rect"].y0 - clip.y1))
                if dist <= cfg["surrounding_distance"] and len(b["text"]) > 40:
                    surround.append(b["text"])
            surrounding = " ".join(surround)[: cfg["surrounding_chars"]]

            warnings = []
            e = cfg["edge_tolerance"]
            pr = page.rect
            touches_top = rect.y0 <= pr.y0 + e
            touches_bottom = rect.y1 >= pr.y1 - e
            if touches_top or touches_bottom or rect.x0 <= pr.x0 + e or rect.x1 >= pr.x1 - e:
                warnings.append("touches_page_edge")
            if cap is None:
                warnings.append("no_caption")
            if cap and cap["continued"]:
                warnings.append("continued_from_previous_page")
            if touches_bottom and cap is None:
                warnings.append("possible_multi_page")
            if r.get("method") == "caption_search":
                warnings.append("reconstructed_from_caption")

            needs_ocr = bool(r["has_raster"]) and len(" ".join(inside)) < 3
            ocr_text = None
            if needs_ocr and cfg["ocr"]:
                ocr_text = try_ocr(fpath)
                if ocr_text:
                    needs_ocr = False

            if cap is None or "continued_from_previous_page" in warnings or "possible_multi_page" in warnings:
                quality = "needs_review" if "possible_multi_page" not in warnings else "incomplete"
            elif "touches_page_edge" in warnings or "reconstructed_from_caption" in warnings:
                quality = "needs_review"
            else:
                quality = "ok"

            fig = {
                "id": f"p{pno}_f{idx}",
                "page": pno,
                "bbox": r2l(rect),
                "renderBox": r2l(clip),
                "pageSize": [round(pr.width, 2), round(pr.height, 2)],
                "caption": cap["text"] if cap else None,
                "captionLabel": cap["label"] if cap else None,
                "kind": (cap["kind"] if cap else ("photo" if r["has_raster"] and not r["has_vector"] else "diagram")),
                "file": fname,
                "widthPx": pix.width,
                "heightPx": pix.height,
                "dpi": cfg["dpi"],
                "labels": inside[:60],
                "labelBoxes": label_boxes[:60],
                "surroundingText": surrounding,
                "method": r.get("method", "merged"),
                "hasRaster": bool(r["has_raster"]),
                "hasVector": bool(r["has_vector"]),
                "parts": r.get("parts", 1),
                "needsOcr": needs_ocr,
                "ocrText": ocr_text,
                "quality": quality,
                "warnings": warnings,
                "hash": average_hash(page, clip),
                "duplicateOf": None,
                "continuationOf": None,
                "_rect": rect,
            }
            page_fig_objs.append(fig)

        for c in orphan_caps:
            # Do NOT pretend: record the caption with no image.
            page_fig_objs.append({
                "id": f"p{pno}_c{len(page_fig_objs) + 1}",
                "page": pno, "bbox": r2l(c["rect"]), "renderBox": None,
                "pageSize": [round(page.rect.width, 2), round(page.rect.height, 2)],
                "caption": c["text"], "captionLabel": c["label"], "kind": c["kind"],
                "file": None, "widthPx": 0, "heightPx": 0, "dpi": cfg["dpi"],
                "labels": [], "labelBoxes": [], "surroundingText": "", "method": "caption_only",
                "hasRaster": False, "hasVector": False, "parts": 0,
                "needsOcr": False, "ocrText": None, "quality": "incomplete",
                "warnings": ["caption_without_region"], "hash": None,
                "duplicateOf": None, "continuationOf": None, "_rect": fitz.Rect(c["rect"]),
            })

        rendered = [f for f in page_fig_objs if f["file"]]
        order = reading_order(page, blocks, rendered, tables, caption_blocks)
        figures.extend(page_fig_objs)
        pages_out.append({
            "n": pno,
            "printedPage": printed_page_number(lines, page),
            "width": round(page.rect.width, 2),
            "height": round(page.rect.height, 2),
            "backgroundImages": backgrounds,
            "readingOrder": order,
            "equations": equation_candidates(lines),
            "tables": tables,
        })

    # Duplicates (identical logos / repeated diagrams) by perceptual hash.
    seen = []
    for f in figures:
        if not f.get("hash"):
            continue
        for g in seen:
            if hamming(f["hash"], g["hash"]) <= 3 and abs(f["widthPx"] - g["widthPx"]) < 0.1 * max(1, g["widthPx"]):
                f["duplicateOf"] = g["id"]
                f["warnings"].append("duplicate")
                break
        else:
            seen.append(f)

    # Multi-page figures: "Figure 3.2 (continued)" links to the earlier part.
    by_label = {}
    for f in figures:
        lbl = f.get("captionLabel")
        if not lbl:
            continue
        if "continued_from_previous_page" in f["warnings"] and lbl in by_label:
            f["continuationOf"] = by_label[lbl]["id"]
        else:
            by_label.setdefault(lbl, f)
    # An uncaptioned region at the top of a page right after a page whose
    # figure ran off the bottom edge is probably its continuation.
    for i, f in enumerate(figures):
        if "possible_multi_page" in f["warnings"]:
            nxt = [g for g in figures if g["page"] == f["page"] + 1 and g["bbox"][1] < 80]
            if nxt:
                nxt[0]["continuationOf"] = f["id"]
                if "continued_from_previous_page" not in nxt[0]["warnings"]:
                    nxt[0]["warnings"].append("continued_from_previous_page")

    for f in figures:
        f.pop("_rect", None)

    result = {
        "extractorVersion": EXTRACTOR_VERSION,
        "pymupdfVersion": fitz.VersionBind,
        "pdf": {"sha256": sha, "pageCount": doc.page_count, "firstPage": first, "lastPage": last},
        "config": cfg,
        "pages": pages_out,
        "figures": figures,
        "summary": {
            "figures": sum(1 for f in figures if f["file"]),
            "ok": sum(1 for f in figures if f["quality"] == "ok"),
            "needsReview": sum(1 for f in figures if f["quality"] == "needs_review"),
            "incomplete": sum(1 for f in figures if f["quality"] == "incomplete"),
            "captionOnly": sum(1 for f in figures if not f["file"]),
            "duplicates": sum(1 for f in figures if f["duplicateOf"]),
            "needsOcr": sum(1 for f in figures if f["needsOcr"]),
            "tables": sum(len(p["tables"]) for p in pages_out),
        },
    }
    doc.close()
    with open(os.path.join(out_dir, "figures.json"), "w", encoding="utf-8") as fh:
        json.dump(result, fh, ensure_ascii=False)
    return result


def parse_range(s):
    if not s:
        return None
    a, _, b = s.partition("-")
    return (int(a), int(b or a))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--pdf", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--dpi", type=int)
    ap.add_argument("--pages")
    ap.add_argument("--config", default="{}")
    args = ap.parse_args(argv)
    cfg = dict(DEFAULT_CONFIG)
    cfg.update(json.loads(args.config or "{}"))
    if args.dpi:
        cfg["dpi"] = args.dpi
    res = extract(args.pdf, args.out, cfg, parse_range(args.pages))
    print(json.dumps({"ok": True, "summary": res["summary"], "pdf": res["pdf"]}))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # report a machine-readable error to Node
        print(json.dumps({"ok": False, "error": f"{type(exc).__name__}: {exc}"}))
        sys.exit(1)
