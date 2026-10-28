"""
Tests for figure_extractor.py using small synthetic textbooks generated on the fly:

  * maths book   — vector graph (axes, curve, labels) + formulas, two-column page
  * science book — raster apparatus picture with text labels, experiment caption
  * general book — overlapping images forming one figure, a table, duplicates,
                   a caption that has no figure, decorative icons

Run:  python -m unittest discover -s tests   (from backend/python)
"""
import json
import os
import shutil
import sys
import tempfile
import unittest

import fitz

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import figure_extractor as fx  # noqa: E402


def solid_pixmap(w, h, rgb, stripe=None):
    pix = fitz.Pixmap(fitz.csRGB, fitz.IRect(0, 0, w, h), 0)
    pix.set_rect(pix.irect, rgb)
    if stripe:
        # A stripe makes the image non-uniform so hashes differ between images.
        pix.set_rect(fitz.IRect(0, h // 3, w, h // 3 + h // 6), stripe)
    return pix


def body(page, rect, text, size=10):
    page.insert_textbox(fitz.Rect(rect), text, fontsize=size, fontname="helv")


LOREM = ("The derivative measures how a function changes as its input changes. "
         "In this section we study gradients of curves and how they relate to tangents. ") * 3


def make_maths_book(path):
    doc = fitz.open()
    # Page 1: single column, vector graph with labels and caption below.
    p = doc.new_page(width=595, height=842)
    body(p, (50, 30, 545, 62), "Chapter 1 Functions and Graphs", 16)
    body(p, (50, 70, 545, 160), LOREM)
    # Axes + curve drawn as vector paths
    sh = p.new_shape()
    sh.draw_line((100, 400), (400, 400))  # x axis
    sh.draw_line((250, 200), (250, 420))  # y axis
    pts = [(100 + i * 10, 400 - ((i - 15) ** 2) * 0.8) for i in range(31)]
    for a, b in zip(pts, pts[1:]):
        sh.draw_line(a, b)
    sh.draw_line((395, 396), (400, 400))  # arrow heads
    sh.draw_line((395, 404), (400, 400))
    sh.finish(color=(0, 0, 0), width=1)
    sh.commit()
    p.insert_text((404, 404), "x", fontsize=10)
    p.insert_text((254, 205), "y", fontsize=10)
    p.insert_text((235, 412), "O", fontsize=9)
    body(p, (100, 430, 450, 450), "Figure 1.1 Graph of y = x^2 - 4", 9)
    body(p, (50, 470, 545, 520), "y = x² − 4 and dy/dx = 2x", 11)
    body(p, (50, 530, 545, 640), LOREM)

    # Page 2: two columns; a figure in the right column, text in both.
    p = doc.new_page(width=595, height=842)
    body(p, (40, 30, 555, 62), "1.2 Gradients", 14)  # full-width heading
    body(p, (40, 80, 285, 400), "LEFT-A " + LOREM)
    body(p, (40, 410, 285, 700), "LEFT-B " + LOREM)
    sh = p.new_shape()
    sh.draw_rect((330, 90, 540, 260))
    sh.draw_line((330, 260), (540, 90))
    sh.draw_circle((435, 175), 30)
    sh.finish(color=(0, 0, 1), width=1)
    sh.commit()
    body(p, (330, 268, 555, 290), "Figure 1.2 Tangent to a circle", 9)
    body(p, (310, 310, 555, 700), "RIGHT-A " + LOREM)
    doc.save(path)


def make_science_book(path):
    doc = fitz.open()
    p = doc.new_page(width=595, height=842)
    body(p, (50, 30, 545, 62), "Chapter 4 Acids and Bases", 16)
    body(p, (50, 70, 545, 150), "In this experiment we titrate hydrochloric acid with sodium hydroxide using a burette. " * 2)
    p.insert_image(fitz.Rect(150, 170, 450, 400), pixmap=solid_pixmap(300, 230, (200, 220, 240), (90, 90, 90)))
    # Labels drawn as real PDF text over the picture (callouts)
    p.insert_text((460, 200), "burette", fontsize=9)
    p.insert_text((460, 380), "conical flask", fontsize=9)
    body(p, (150, 410, 450, 430), "Fig. 4.3 Apparatus for a titration", 9)
    body(p, (50, 450, 545, 600), "Safety: wear goggles. Acids are corrosive. " * 4)

    # Page 2: raster image with no text inside -> needsOcr
    p = doc.new_page(width=595, height=842)
    p.insert_image(fitz.Rect(100, 100, 400, 300), pixmap=solid_pixmap(300, 200, (120, 60, 60)))
    body(p, (100, 310, 400, 330), "Figure 4.4 Colour change of the indicator", 9)
    doc.save(path)


def make_general_book(path):
    doc = fitz.open()
    logo = solid_pixmap(200, 120, (30, 60, 200), (250, 250, 0))
    for i in range(2):
        p = doc.new_page(width=595, height=842)
        # Decorative icon: must be ignored
        p.insert_image(fitz.Rect(20, 20, 34, 34), pixmap=solid_pixmap(14, 14, (255, 0, 0)))
        if i == 0:
            body(p, (50, 50, 545, 120), "Chapter 2 Markets. " + LOREM)
            # Two overlapping images forming one figure
            p.insert_image(fitz.Rect(100, 150, 300, 300), pixmap=solid_pixmap(200, 150, (0, 150, 0), (0, 0, 0)))
            p.insert_image(fitz.Rect(280, 160, 480, 310), pixmap=solid_pixmap(200, 150, (150, 0, 150), (255, 255, 255)))
            body(p, (100, 318, 480, 338), "Figure 2.1 Supply and demand photographs", 9)
            # Table with caption above
            body(p, (100, 380, 480, 398), "Table 2.1 Prices by year", 9)
            tab_y = 405
            rows = [["Year", "Price"], ["2020", "10"], ["2021", "12"], ["2022", "15"]]
            sh = p.new_shape()
            for r, row in enumerate(rows):
                for c, val in enumerate(row):
                    rect = fitz.Rect(100 + c * 150, tab_y + r * 20, 250 + c * 150, tab_y + (r + 1) * 20)
                    sh.draw_rect(rect)
                    p.insert_text((rect.x0 + 4, rect.y1 - 6), val, fontsize=9)
            sh.finish(color=(0, 0, 0), width=0.7)
            sh.commit()
            # A caption whose figure is missing from the PDF
            body(p, (100, 600, 480, 620), "Figure 2.2 Market equilibrium (image not reproduced)", 9)
        # The same uncaptioned large logo on both pages -> duplicate
        p.insert_image(fitz.Rect(150, 680, 450, 800), pixmap=logo)
    doc.save(path)


class FigureExtractorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="ech_fig_")
        cls.books = {}
        for name, maker in (("maths", make_maths_book), ("science", make_science_book), ("general", make_general_book)):
            pdf = os.path.join(cls.tmp, f"{name}.pdf")
            maker(pdf)
            out = os.path.join(cls.tmp, f"{name}_out")
            cfg = dict(fx.DEFAULT_CONFIG)
            cfg["ocr"] = False
            cls.books[name] = fx.extract(pdf, out, cfg)
            cls.books[name]["_out"] = out

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def figs(self, book, page=None):
        return [f for f in self.books[book]["figures"] if page is None or f["page"] == page]

    # ── page numbering / output ────────────────────────────────────────────
    def test_page_numbering_and_json_written(self):
        res = self.books["maths"]
        self.assertEqual([p["n"] for p in res["pages"]], [1, 2])
        self.assertEqual(res["pdf"]["pageCount"], 2)
        with open(os.path.join(res["_out"], "figures.json"), encoding="utf-8") as fh:
            self.assertEqual(json.load(fh)["pdf"]["sha256"], res["pdf"]["sha256"])

    # ── vector figures + caption matching ──────────────────────────────────
    def test_vector_graph_detected_with_caption_and_labels(self):
        figs = [f for f in self.figs("maths", 1) if f["file"]]
        self.assertEqual(len(figs), 1, figs)
        f = figs[0]
        self.assertTrue(f["caption"].startswith("Figure 1.1"))
        self.assertEqual(f["captionLabel"], "1.1")
        self.assertTrue(f["hasVector"])
        self.assertFalse(f["hasRaster"])
        # axis labels drawn as text must be inside the figure region
        for label in ("x", "y"):
            self.assertIn(label, f["labels"])
        self.assertEqual(f["quality"], "ok")
        self.assertTrue(os.path.exists(os.path.join(self.books["maths"]["_out"], f["file"])))
        self.assertGreater(f["widthPx"], 300)  # rendered at ~140 dpi

    def test_equation_candidates(self):
        eqs = self.books["maths"]["pages"][0]["equations"]
        self.assertTrue(any("dy/dx" in e["text"] for e in eqs), eqs)

    def test_two_column_reading_order(self):
        order = self.books["maths"]["pages"][1]["readingOrder"]
        previews = [o.get("preview", o["type"]) for o in order]
        idx = lambda s: next(i for i, p in enumerate(previews) if p.startswith(s))  # noqa: E731
        self.assertLess(idx("1.2 Gradients"), idx("LEFT-A"))
        self.assertLess(idx("LEFT-A"), idx("LEFT-B"))
        self.assertLess(idx("LEFT-B"), idx("figure"))       # right column after left column
        self.assertLess(idx("figure"), idx("RIGHT-A"))       # figure above right column text

    # ── raster + labels + OCR flag ─────────────────────────────────────────
    def test_raster_figure_includes_callout_labels(self):
        f = [x for x in self.figs("science", 1) if x["file"]][0]
        self.assertEqual(f["captionLabel"], "4.3")
        self.assertTrue(f["hasRaster"])
        self.assertIn("burette", f["labels"])
        self.assertIn("conical flask", f["labels"])
        box = next(b["box"] for b in f["labelBoxes"] if b["text"] == "burette")
        self.assertTrue(all(0 <= v <= 1 for v in box))
        self.assertGreater(box[0], 0.8)  # label sits at the right edge of the figure
        self.assertLess(box[1], 0.3)     # near the top
        self.assertFalse(f["needsOcr"])
        self.assertIn("titrate", f["surroundingText"])

    def test_raster_without_text_needs_ocr(self):
        f = [x for x in self.figs("science", 2) if x["file"]][0]
        self.assertTrue(f["needsOcr"])
        self.assertEqual(f["captionLabel"], "4.4")

    # ── overlapping images, tables, decorative filtering, orphans, dupes ───
    def test_overlapping_images_merge_into_one_figure(self):
        f = [x for x in self.figs("general", 1) if x["captionLabel"] == "2.1" and x["kind"] == "figure"]
        self.assertEqual(len(f), 1)
        self.assertGreaterEqual(f[0]["parts"], 2)
        x0, y0, x1, y1 = f[0]["bbox"]
        self.assertLessEqual(x0, 101)
        self.assertGreaterEqual(x1, 479)

    def test_decorative_icons_ignored(self):
        for f in self.figs("general"):
            if f["bbox"]:
                self.assertFalse(f["bbox"][2] < 40 and f["bbox"][3] < 40, f)

    def test_table_detected_with_caption(self):
        page = self.books["general"]["pages"][0]
        self.assertTrue(page["tables"], "table not detected")
        rows = page["tables"][0]["rows"]
        self.assertEqual(rows[0][:2], ["Year", "Price"])
        tfig = [f for f in self.figs("general", 1) if f["captionLabel"] == "2.1" and f["kind"] == "table"]
        self.assertEqual(len(tfig), 1)

    def test_caption_without_figure_is_reported_incomplete(self):
        f = [x for x in self.figs("general", 1) if x["captionLabel"] == "2.2"]
        self.assertEqual(len(f), 1)
        self.assertIsNone(f[0]["file"])
        self.assertEqual(f[0]["quality"], "incomplete")
        self.assertIn("caption_without_region", f[0]["warnings"])

    def test_duplicate_detection(self):
        dupes = [f for f in self.figs("general") if f["duplicateOf"]]
        self.assertEqual(len(dupes), 1, [(f["id"], f["hash"]) for f in self.figs("general")])
        self.assertEqual(dupes[0]["page"], 2)

    def test_summary_counts(self):
        s = self.books["general"]["summary"]
        self.assertEqual(s["captionOnly"], 1)
        self.assertGreaterEqual(s["duplicates"], 1)

    def test_cli_reports_errors_as_json(self):
        import subprocess
        r = subprocess.run([sys.executable, os.path.join(os.path.dirname(HERE), "figure_extractor.py"),
                            "--pdf", os.path.join(self.tmp, "missing.pdf"), "--out", self.tmp],
                           capture_output=True, text=True)
        self.assertEqual(r.returncode, 1)
        self.assertFalse(json.loads(r.stdout)["ok"])


if __name__ == "__main__":
    unittest.main()
