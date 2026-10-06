/**
 * Turns the AI's proposed outline (or bookmarks / headings when the AI is not
 * available) into a clean chapter → lesson structure with valid,
 * non-overlapping page ranges.
 */

const TARGET_LESSON_PAGES = 6;
const MAX_LESSON_PAGES = 14;

function normalizeOutline(raw, pageCount) {
  const chapters = (Array.isArray(raw?.chapters) ? raw.chapters : [])
    .filter(c => c && c.title)
    .map(c => ({
      title: String(c.title).trim().slice(0, 200),
      summary: String(c.summary || '').trim(),
      pageStart: clampPage(c.pageStart, pageCount),
      lessons: (Array.isArray(c.lessons) ? c.lessons : [])
        .filter(l => l && l.title)
        .map(l => ({ title: String(l.title).trim().slice(0, 200), pageStart: clampPage(l.pageStart, pageCount) })),
    }))
    .filter(c => c.pageStart != null)
    .sort((a, b) => a.pageStart - b.pageStart);

  // Drop chapters that start on the same page as the previous one (duplicates)
  const unique = [];
  for (const c of chapters) {
    if (unique.length && unique[unique.length - 1].pageStart === c.pageStart) continue;
    unique.push(c);
  }

  unique.forEach((c, i) => {
    c.index = i;
    c.pageEnd = i + 1 < unique.length ? Math.max(c.pageStart, unique[i + 1].pageStart - 1) : pageCount;
    c.selected = true;
    c.lessons = fitLessons(c, pageCount);
  });

  return {
    bookTitle: String(raw?.bookTitle || '').trim(),
    subject: String(raw?.subject || '').trim(),
    level: ['beginner', 'intermediate', 'advanced'].includes(raw?.level) ? raw.level : 'intermediate',
    description: String(raw?.description || '').trim(),
    chapters: unique,
  };
}

/** Make lesson page ranges valid inside their chapter; split/fill as needed. */
function fitLessons(chapter, pageCount) {
  let lessons = chapter.lessons
    .map(l => ({ ...l, pageStart: l.pageStart == null ? null : Math.min(Math.max(l.pageStart, chapter.pageStart), chapter.pageEnd) }))
    .filter(l => l.pageStart != null)
    .sort((a, b) => a.pageStart - b.pageStart);

  // Merge lessons that share a start page
  const merged = [];
  for (const l of lessons) {
    const prev = merged[merged.length - 1];
    if (prev && prev.pageStart === l.pageStart) {
      if (prev.title.length + l.title.length < 160) prev.title = `${prev.title} & ${l.title}`;
      continue;
    }
    merged.push(l);
  }
  lessons = merged;

  if (!lessons.length) {
    lessons = splitRange(chapter.pageStart, chapter.pageEnd, chapter.title);
  } else if (lessons[0].pageStart > chapter.pageStart) {
    // Chapter introduction before the first section
    lessons.unshift({ title: `${stripNumber(chapter.title)}: Introduction`, pageStart: chapter.pageStart });
  }

  lessons.forEach((l, i) => {
    l.pageEnd = i + 1 < lessons.length ? Math.max(l.pageStart, lessons[i + 1].pageStart - 1) : chapter.pageEnd;
  });

  // Very long lessons are split so each generation request stays focused
  const out = [];
  for (const l of lessons) {
    const len = l.pageEnd - l.pageStart + 1;
    if (len > MAX_LESSON_PAGES) {
      out.push(...splitRange(l.pageStart, l.pageEnd, l.title));
    } else {
      out.push(l);
    }
  }
  return out.map(l => ({ title: l.title, pageStart: l.pageStart, pageEnd: Math.min(l.pageEnd, pageCount) }));
}

function splitRange(start, end, title) {
  const len = end - start + 1;
  const parts = Math.max(1, Math.round(len / TARGET_LESSON_PAGES));
  const size = Math.ceil(len / parts);
  const out = [];
  for (let i = 0; i < parts; i++) {
    const s = start + i * size;
    if (s > end) break;
    out.push({
      title: parts === 1 ? title : `${stripNumber(title)} (Part ${i + 1})`,
      pageStart: s,
      pageEnd: Math.min(end, s + size - 1),
    });
  }
  return out;
}

function stripNumber(title) {
  return String(title).replace(/^(chapter|unit|module|part)\s+[0-9ivxlc]+\s*[:.\-–]?\s*/i, '').trim() || title;
}

function clampPage(v, pageCount) {
  const n = Number(v);
  if (!Number.isFinite(n)) return null;
  return Math.min(Math.max(1, Math.round(n)), pageCount);
}

/** Outline without AI: bookmarks → headings → fixed windows. */
function heuristicOutline({ fileName, pageCount, bookmarks, headings }) {
  let chapters = [];
  if (bookmarks.length >= 2) {
    const top = bookmarks.filter(b => b.depth === 0);
    const tops = top.length >= 2 ? top : bookmarks.filter(b => b.depth <= 1);
    chapters = tops.map((b, i) => {
      const next = tops[i + 1]?.page ?? pageCount + 1;
      return {
        title: b.title,
        pageStart: b.page,
        lessons: bookmarks.filter(x => x.depth === b.depth + 1 && x.page >= b.page && x.page < next)
          .map(x => ({ title: x.title, pageStart: x.page })),
        next,
      };
    });
    // Bookmarks without children: use numbered section headings (1.1, 1.2 …) inside the chapter
    for (const c of chapters) {
      if (!c.lessons.length) c.lessons = numberedSections(headings, c.pageStart, c.next);
    }
  } else {
    const chapterHeads = headings.filter(h => /^(chapter|unit|module|part)\s+[0-9ivxlc]+/i.test(h.text));
    if (chapterHeads.length >= 2) {
      chapters = chapterHeads.map((h, i) => {
        const next = chapterHeads[i + 1]?.page ?? pageCount + 1;
        return {
          title: h.text,
          pageStart: h.page,
          lessons: numberedSections(headings, h.page, next),
        };
      });
    } else {
      const per = Math.max(8, Math.ceil(pageCount / 10));
      for (let s = 1; s <= pageCount; s += per) {
        chapters.push({ title: `Part ${chapters.length + 1}`, pageStart: s, lessons: [] });
      }
    }
  }
  return normalizeOutline({
    bookTitle: fileName.replace(/\.[^.]+$/, '').replace(/[_-]+/g, ' '),
    chapters,
  }, pageCount);
}

function numberedSections(headings, from, to) {
  return headings
    .filter(x => x.page >= from && x.page < to && /^\d+\.\d+\s/.test(x.text) && !/^\d+\.\d+\.\d+/.test(x.text))
    .map(x => ({ title: x.text, pageStart: x.page }));
}

module.exports = { normalizeOutline, heuristicOutline };
