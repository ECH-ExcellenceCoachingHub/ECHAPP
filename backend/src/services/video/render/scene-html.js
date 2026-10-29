const { pathToFileURL } = require('url');
const katex = require('katex');
const { parse: parseExpression } = require('../../../utils/mathExpression');

/**
 * Deterministic HTML for every frame of every scene (1280×720).
 *
 * framesFor(scene)          → list of frame states (progressive reveals)
 * renderFrame(scene, state, ctx) → full HTML document for one frame
 *
 * Exact content (formulas, numbers, labels, plotted curves) is produced here
 * by code — never by an image/video model.
 *
 * Motion: the element that appears in a frame state carries a CSS entrance
 * animation (rise / write-on / pop / pulse). The renderer samples those
 * animations at fixed times, so every video renders identically.
 *
 * Layouts (layoutOf):
 *   none  — opaque slide (default)
 *   split — content on the left, licensed photo/clip in a framed panel on the right
 *   full  — licensed photo/clip fills the frame; text sits on a dark scrim
 * For split/full the page is transparent where the media shows; FFmpeg puts
 * the (Ken Burns-animated) photo or clip underneath.
 */

const W = 1280;
const H = 720;
/** Media panel of the split layout (px). */
const PANEL = { x: 712, y: 156, w: 508, h: 400, r: 18 };
/** Entrance animations finish within this time; the renderer samples it at ANIM_FPS. */
const ANIM_SECONDS = 0.6;
const C = {
  green: '#16A34A', greenLight: '#DCFCE7', greenDark: '#14532D',
  orange: '#EA580C', amberLight: '#FEF3C7', blue: '#2563EB', blueLight: '#EFF6FF',
  purple: '#4F46E5', text: '#111827', muted: '#6B7280', border: '#E5E7EB', bg: '#F8FAF9',
};
const SERIES = [C.blue, C.orange, C.purple];

const KATEX_CSS = pathToFileURL(require.resolve('katex/dist/katex.min.css')).href;

function esc(s) {
  return String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function hostOf(url) {
  try { return new URL(url).host.replace(/^www\./, ''); } catch (_) { return ''; }
}

function tex(latex, display = true) {
  try {
    return katex.renderToString(latex, { throwOnError: true, displayMode: display, output: 'html' });
  } catch (_) {
    return `<code>${esc(latex)}</code>`;
  }
}

/** LaTeX that is really a sentence (\text{...} with hardly any maths) reads better as text. */
function isProseLatex(latex) {
  if (!latex) return false;
  const textChars = (latex.match(/\\text\{[^}]*\}/g) || []).join('').length;
  const rest = latex.replace(/\\text\{[^}]*\}/g, '').replace(/[\s{}]/g, '');
  return textChars > 0 && rest.length < 4;
}

function mathOrText(step) {
  return step.latex && !isProseLatex(step.latex) ? tex(step.latex) : `<div class="plain-math">${esc(step.text || step.latex)}</div>`;
}

/** Inline maths for short labels written like "y = x^2 - 4". */
function labelHtml(label) {
  const s = String(label || '');
  if (/[\^_\\]/.test(s)) {
    try { return katex.renderToString(s, { throwOnError: true, displayMode: false }); } catch (_) { /* plain */ }
  }
  return esc(s);
}

// ─── Frame plans ─────────────────────────────────────────────────────────────

function range(n) { return Array.from({ length: n }, (_, i) => i); }

/** Frame states of a scene; the first one also animates the heading in. */
function framesFor(scene) {
  const states = baseFrames(scene);
  states[0] = { ...states[0], first: true };
  return states;
}

function baseFrames(scene) {
  switch (scene.type) {
    case 'title': return [{ k: 0 }];
    case 'media': return range((scene.points || []).length + 1).map(i => ({ reveal: i }));
    case 'check': return range(scene.choices.length + 1).map(i => ({ reveal: i, think: i === scene.choices.length }));
    case 'check_answer': return [{ answer: true }];
    case 'credits': return [{ k: 0 }];
    case 'bullets':
    case 'summary': return range(Math.max(1, scene.bullets.length)).map(i => ({ reveal: i + 1 }));
    case 'formula': return range(scene.steps.length).map(i => ({ reveal: i + 1 }));
    case 'graph': return [0.2, 0.4, 0.6, 0.8, 1, 1].map((p, i) => ({ progress: p, showPoints: i === 5 }));
    case 'figure': return [{ highlight: -1 }, ...scene.highlightLabels.map((_, i) => ({ highlight: i }))];
    case 'worked_example': return [{ reveal: 0 }, ...scene.steps.map((_, i) => ({ reveal: i + 1 })), ...(scene.answer ? [{ reveal: scene.steps.length, answer: true }] : [])];
    case 'table':
    case 'ledger': return range(Math.max(1, scene.rows.length)).map(i => ({ reveal: i + 1 }));
    case 'timeline': return range(scene.events.length).map(i => ({ reveal: i + 1 }));
    case 'flow': return range(scene.steps.length).map(i => ({ reveal: i + 1 }));
    case 'dialogue': return range(scene.lines.length).map(i => ({ reveal: i + 1 }));
    case 'experiment': return range(Math.max(1, scene.items.length)).map(i => ({ reveal: i + 1 }));
    default: return [{ k: 0 }];
  }
}

// ─── Graph plotting (deterministic) ──────────────────────────────────────────

function niceStep(span) {
  const raw = span / 8;
  const mag = Math.pow(10, Math.floor(Math.log10(raw)));
  const n = raw / mag;
  return (n < 1.5 ? 1 : n < 3 ? 2 : n < 7 ? 5 : 10) * mag;
}

function fmt(n) {
  const r = Math.round(n * 1000) / 1000;
  return Math.abs(r) < 1e-9 ? '0' : String(r);
}

/** Sample each function; auto y-range if not given. */
function sampleGraph(graph, samples = 400) {
  const fns = graph.functions.map(f => ({ ...f, fn: parseExpression(f.expression) }));
  const series = fns.map(f => {
    const pts = [];
    for (let i = 0; i <= samples; i++) {
      const x = graph.xMin + (i / samples) * (graph.xMax - graph.xMin);
      let y;
      try { y = f.fn.evaluate({ x }); } catch (_) { y = NaN; }
      pts.push({ x, y: Number.isFinite(y) ? y : null });
    }
    return { label: f.label, pts };
  });
  let { yMin, yMax } = graph;
  if (yMin == null || yMax == null) {
    const ys = series.flatMap(s => s.pts.map(p => p.y)).filter(y => y != null).concat(graph.points.map(p => p.y));
    const sorted = ys.slice().sort((a, b) => a - b);
    // ignore extreme 2% (asymptotes) when auto-scaling
    const lo = sorted[Math.floor(sorted.length * 0.02)] ?? -10;
    const hi = sorted[Math.ceil(sorted.length * 0.98) - 1] ?? 10;
    const pad = (hi - lo || 2) * 0.12;
    yMin = Math.min(lo - pad, 0 - pad * 0.2);
    yMax = Math.max(hi + pad, 0 + pad * 0.2);
  }
  return { series, yMin, yMax };
}

function plotSvg(graph, { progress = 1, showPoints = true, width = 860, height = 500 } = {}) {
  const { series, yMin, yMax } = sampleGraph(graph);
  const m = { l: 56, r: 24, t: 20, b: 44 };
  const pw = width - m.l - m.r;
  const ph = height - m.t - m.b;
  const X = (x) => m.l + ((x - graph.xMin) / (graph.xMax - graph.xMin)) * pw;
  const Y = (y) => m.t + (1 - (y - yMin) / (yMax - yMin)) * ph;
  const out = [`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">`];

  const xs = niceStep(graph.xMax - graph.xMin);
  const ysStep = niceStep(yMax - yMin);
  for (let x = Math.ceil(graph.xMin / xs) * xs; x <= graph.xMax + 1e-9; x += xs) {
    out.push(`<line x1="${X(x)}" y1="${m.t}" x2="${X(x)}" y2="${m.t + ph}" stroke="#EEF2F7"/>`);
    out.push(`<text x="${X(x)}" y="${m.t + ph + 22}" font-size="15" text-anchor="middle" fill="${C.muted}">${fmt(x)}</text>`);
  }
  for (let y = Math.ceil(yMin / ysStep) * ysStep; y <= yMax + 1e-9; y += ysStep) {
    out.push(`<line x1="${m.l}" y1="${Y(y)}" x2="${m.l + pw}" y2="${Y(y)}" stroke="#EEF2F7"/>`);
    out.push(`<text x="${m.l - 10}" y="${Y(y) + 5}" font-size="15" text-anchor="end" fill="${C.muted}">${fmt(y)}</text>`);
  }
  // axes through the origin when visible
  const ax = Math.min(Math.max(0, yMin), yMax);
  const ay = Math.min(Math.max(0, graph.xMin), graph.xMax);
  out.push(`<line x1="${m.l}" y1="${Y(ax)}" x2="${m.l + pw}" y2="${Y(ax)}" stroke="${C.text}" stroke-width="2"/>`);
  out.push(`<line x1="${X(ay)}" y1="${m.t}" x2="${X(ay)}" y2="${m.t + ph}" stroke="${C.text}" stroke-width="2"/>`);
  out.push(`<text x="${m.l + pw - 4}" y="${Y(ax) - 8}" font-size="18" font-style="italic" text-anchor="end" fill="${C.text}">x</text>`);
  out.push(`<text x="${X(ay) + 10}" y="${m.t + 16}" font-size="18" font-style="italic" fill="${C.text}">y</text>`);

  out.push(`<clipPath id="plot"><rect x="${m.l}" y="${m.t}" width="${pw}" height="${ph}"/></clipPath>`);
  series.forEach((s, si) => {
    const limit = Math.round(s.pts.length * progress);
    let d = '';
    let pen = false;
    for (let i = 0; i < limit; i++) {
      const p = s.pts[i];
      if (p.y == null || p.y < yMin - (yMax - yMin) * 2 || p.y > yMax + (yMax - yMin) * 2) { pen = false; continue; }
      d += `${pen ? 'L' : 'M'}${X(p.x).toFixed(1)},${Y(p.y).toFixed(1)} `;
      pen = true;
    }
    out.push(`<path d="${d}" fill="none" stroke="${SERIES[si % SERIES.length]}" stroke-width="4" stroke-linecap="round" clip-path="url(#plot)"/>`);
  });
  if (showPoints) {
    for (const p of graph.points) {
      if (p.x < graph.xMin || p.x > graph.xMax || p.y < yMin || p.y > yMax) continue;
      out.push(`<circle cx="${X(p.x)}" cy="${Y(p.y)}" r="8" fill="${C.green}" stroke="#fff" stroke-width="3"/>`);
      out.push(`<text x="${X(p.x) + 12}" y="${Y(p.y) - 12}" font-size="17" font-weight="700" fill="${C.greenDark}">${esc(p.label || `(${fmt(p.x)}, ${fmt(p.y)})`)}</text>`);
    }
  }
  out.push('</svg>');
  return { svg: out.join(''), legend: series.map((s, i) => ({ label: s.label, color: SERIES[i % SERIES.length] })) };
}

// ─── Scene bodies ────────────────────────────────────────────────────────────

function list(items, reveal, cls = '') {
  return `<ul class="list ${cls}">${items.map((b, i) => `<li class="${i < reveal ? (i === reveal - 1 ? 'on current' : 'on') : 'off'}"><span class="dot"></span><span>${esc(b)}</span></li>`).join('')}</ul>`;
}

function tableHtml(scene, reveal, ledger) {
  const numeric = (v) => /^[-(]?[$£€]?\s?\d[\d,]*(\.\d+)?\)?%?$/.test(String(v).trim());
  return `<table class="tbl ${ledger ? 'ledger' : ''}"><thead><tr>${scene.columns.map(c => `<th>${esc(c)}</th>`).join('')}</tr></thead><tbody>${
    scene.rows.map((r, i) => `<tr class="${i < reveal ? (i === reveal - 1 ? 'on current' : 'on') : 'off'}">${r.map(v => `<td class="${numeric(v) ? 'num' : ''}">${esc(v)}</td>`).join('')}</tr>`).join('')
  }</tbody></table>`;
}

const PHASE = {
  apparatus: ['Apparatus & materials', '🧪'], safety: ['Safety precautions', '⚠️'], setup: ['Set-up', '🔧'],
  procedure: ['Procedure', '📋'], observation: ['Expected observations (from the textbook)', '👁️'],
  explanation: ['Scientific explanation', '💡'], conclusion: ['Conclusion', '✅'], questions: ['Questions for you', '❓'],
};

const LETTERS = 'ABCD';

function choicesHtml(scene, state) {
  return `<div class="choices">${scene.choices.map((c, i) => {
    let cls;
    if (state.answer) cls = i === scene.answerIndex ? 'on correct' : 'on wrong';
    else cls = i < state.reveal ? (i === state.reveal - 1 ? 'on current' : 'on') : 'off';
    return `<div class="choice ${cls}"><span class="letter">${state.answer && i === scene.answerIndex ? '✓' : LETTERS[i]}</span><span>${esc(c)}</span></div>`;
  }).join('')}</div>`;
}

function body(scene, state, ctx) {
  switch (scene.type) {
    case 'title':
      return `<div class="title-wrap"><div class="kicker">${esc(ctx.subjectLabel)}</div><h1 class="big">${esc(scene.heading)}</h1>${scene.subtitle ? `<p class="sub">${esc(scene.subtitle)}</p>` : ''}</div>`;
    case 'media':
      // Without a found asset the scene is shown as plain points.
      return list(scene.points?.length ? scene.points : [scene.heading], Math.max(1, state.reveal));
    case 'check':
      return `<div class="check"><div class="q">${esc(scene.question)}</div>${choicesHtml(scene, state)}${state.think ? '<div class="think current">⏸&nbsp; Pause and choose your answer</div>' : ''}</div>`;
    case 'check_answer':
      return `<div class="check"><div class="q">${esc(scene.question)}</div>${choicesHtml(scene, state)}${scene.explanation ? `<div class="why current">💡 ${esc(scene.explanation)}</div>` : ''}</div>`;
    case 'credits':
      return `<div class="credits">${scene.items.map(c => `<div class="credit-row"><b>${esc(c.title || (c.kind === 'video' ? 'Video' : 'Photo'))}</b><span>${esc(c.author)} · ${esc(c.providerLabel)} · ${esc(c.license)}${c.sourceUrl ? ` · ${esc(hostOf(c.sourceUrl))}` : ''}</span></div>`).join('')}</div>`;
    case 'bullets':
    case 'summary':
      return list(scene.bullets, state.reveal, scene.type === 'summary' ? 'summary' : '');
    case 'formula':
      return `<div class="formula-steps">${scene.steps.map((s, i) => `<div class="fstep ${i < state.reveal ? (i === state.reveal - 1 ? 'on current' : 'on past') : 'off'}"><div class="fmath">${mathOrText(s)}</div>${s.explanation ? `<div class="fnote">${esc(s.explanation)}</div>` : ''}</div>`).join('')}</div>`;
    case 'graph': {
      const { svg, legend } = plotSvg(scene.graph, { progress: state.progress, showPoints: state.showPoints });
      return `<div class="graph-wrap">${svg}<div class="legend">${legend.map(l => `<div><span style="background:${l.color}"></span>${labelHtml(l.label)}</div>`).join('')}</div></div>`;
    }
    case 'figure': {
      const fig = ctx.figures.get(scene.figureId);
      if (!fig?.localUrl) return list([scene.heading || 'Figure unavailable'], 1);
      const maxW = 1100; const maxH = 470;
      const ar = (fig.widthPx || 4) / (fig.heightPx || 3);
      const w = Math.min(maxW, maxH * ar); const h = w / ar;
      const boxes = (fig.labelBoxes || []);
      const overlays = scene.highlightLabels.map((label, i) => {
        const b = boxes.find(x => x.text.toLowerCase() === label.toLowerCase());
        if (!b) return '';
        const [x0, y0, x1, y1] = b.box;
        const active = i === state.highlight;
        const done = i < state.highlight;
        return `<div class="hl ${active ? 'active' : done ? 'done' : 'hidden'}" style="left:${(x0 * 100 - 1.2).toFixed(2)}%;top:${(y0 * 100 - 1.5).toFixed(2)}%;width:${((x1 - x0) * 100 + 2.4).toFixed(2)}%;height:${((y1 - y0) * 100 + 3).toFixed(2)}%"></div>`;
      }).join('');
      const current = state.highlight >= 0 ? scene.highlightLabels[state.highlight] : null;
      return `<div class="figure-wrap"><div class="figure-box" style="width:${w.toFixed(0)}px;height:${h.toFixed(0)}px"><img src="${fig.localUrl}"/>${overlays}</div>
        <div class="fig-caption">${current ? `<b class="pill">${esc(current)}</b> ` : ''}${esc(fig.caption || '')}${fig.page ? ` <span class="muted">· textbook p. ${fig.page}</span>` : ''}</div></div>`;
    }
    case 'worked_example': {
      const steps = scene.steps.map((s, i) => `<div class="wstep ${i < state.reveal ? (i === state.reveal - 1 && !state.answer ? 'on current' : 'on') : 'off'}"><span class="num">${i + 1}</span><div>${s.latex && !isProseLatex(s.latex) ? tex(s.latex, false) : esc(s.text || s.latex)}${s.latex && s.text && !isProseLatex(s.latex) ? `<div class="fnote">${esc(s.text)}</div>` : ''}</div></div>`).join('');
      return `<div class="worked">${scene.problem ? `<div class="problem"><b>Problem.</b> ${esc(scene.problem)}</div>` : ''}<div class="wsteps">${steps}</div>${state.answer ? `<div class="answer">Answer: ${esc(scene.answer)}</div>` : ''}</div>`;
    }
    case 'table': return tableHtml(scene, state.reveal, false);
    case 'ledger': return tableHtml(scene, state.reveal, true);
    case 'timeline':
      return `<div class="timeline">${scene.events.map((e, i) => `<div class="tl ${i < state.reveal ? (i === state.reveal - 1 ? 'on current' : 'on') : 'off'}"><div class="tl-dot"></div><div class="tl-label">${esc(e.label)}</div><div class="tl-detail">${esc(e.detail)}</div></div>`).join('')}</div>`;
    case 'flow':
      return `<div class="flow">${scene.steps.map((e, i) => `${i ? `<div class="arrow ${i < state.reveal ? 'on' : 'off'}">➜</div>` : ''}<div class="node ${i < state.reveal ? (i === state.reveal - 1 ? 'on current' : 'on') : 'off'}"><div class="node-label">${esc(e.label)}</div><div class="node-detail">${esc(e.detail)}</div></div>`).join('')}</div>`;
    case 'dialogue':
      return `<div class="dialogue">${scene.lines.map((l, i) => `<div class="bubble ${i % 2 ? 'right' : 'left'} ${i < state.reveal ? (i === state.reveal - 1 ? 'on current' : 'on') : 'off'}"><b>${esc(l.speaker)}</b><div>${esc(l.text)}</div>${l.translation ? `<div class="muted small">${esc(l.translation)}</div>` : ''}</div>`).join('')}</div>`;
    case 'experiment': {
      const [label, icon] = PHASE[scene.phase] || PHASE.procedure;
      const numbered = ['procedure', 'setup'].includes(scene.phase);
      return `<div class="exp exp-${scene.phase}"><div class="phase"><span>${icon}</span>${esc(label)}</div>${
        numbered
          ? `<ol class="list steps">${scene.items.map((t, i) => `<li class="${i < state.reveal ? (i === state.reveal - 1 ? 'on current' : 'on') : 'off'}"><span class="num">${i + 1}</span><span>${esc(t)}</span></li>`).join('')}</ol>`
          : list(scene.items, state.reveal)
      }</div>`;
    }
    default:
      return '';
  }
}

const CSS = `
*{box-sizing:border-box;margin:0;padding:0}
html,body{width:${W}px;height:${H}px;overflow:hidden}
body{font-family:"Segoe UI","Noto Sans","DejaVu Sans",Arial,sans-serif;color:${C.text};background:linear-gradient(135deg,#FFFFFF 0%,${C.bg} 60%,#EEF7F1 100%);position:relative}
.frame{position:absolute;inset:0;padding:44px 64px 64px 64px;display:flex;flex-direction:column}
.brand{position:absolute;top:22px;left:64px;font-size:15px;color:${C.muted};letter-spacing:.3px}
.brand b{color:${C.green}}
.disclosure{position:absolute;top:16px;right:24px;background:${C.amberLight};color:#92400E;border:2px solid #F59E0B;border-radius:10px;padding:6px 14px;font-size:14px;font-weight:700;max-width:520px;text-align:right}
h2.heading{margin-top:26px;font-size:40px;line-height:1.15;font-weight:800;letter-spacing:-.5px}
h2.heading:after{content:"";display:block;width:84px;height:6px;background:${C.green};border-radius:3px;margin-top:12px}
.content{flex:1;display:flex;align-items:center;justify-content:center;min-height:0;padding-top:16px;overflow:hidden}
.content>*{flex-shrink:0}
.footer{position:absolute;left:64px;right:64px;bottom:20px;display:flex;justify-content:space-between;font-size:14px;color:${C.muted}}
.dots span{display:inline-block;width:9px;height:9px;border-radius:50%;background:#D1D5DB;margin-left:6px}
.dots span.on{background:${C.green}}
.labels{position:absolute;right:64px;bottom:48px;display:flex;gap:8px}
.labels span{background:${C.blueLight};color:${C.blue};padding:4px 10px;border-radius:8px;font-size:15px;font-weight:600}
.title-wrap{text-align:center;max-width:1000px}
.kicker{display:inline-block;background:${C.greenLight};color:${C.greenDark};font-weight:700;padding:6px 16px;border-radius:999px;font-size:18px;text-transform:uppercase;letter-spacing:1px}
h1.big{font-size:60px;line-height:1.1;margin:22px 0 14px;font-weight:800;letter-spacing:-1px}
.sub{font-size:26px;color:${C.muted}}
.list{list-style:none;width:100%;max-width:1060px}
.list li{display:flex;gap:18px;align-items:flex-start;font-size:30px;line-height:1.3;margin:14px 0;padding:12px 18px;border-radius:14px;transition:none}
.list li .dot{flex:0 0 14px;height:14px;margin-top:12px;border-radius:50%;background:${C.green}}
.list li.off{opacity:0}
.list li.on{opacity:.55}
.list li.current{opacity:1;background:#fff;box-shadow:0 6px 24px rgba(17,24,39,.08);border-left:6px solid ${C.green}}
.list.summary li.on{opacity:1}
.list .num{flex:0 0 40px;height:40px;border-radius:50%;background:${C.green};color:#fff;font-weight:800;display:flex;align-items:center;justify-content:center;font-size:20px}
.formula-steps{width:100%;max-width:1080px;display:flex;flex-direction:column;gap:12px}
.fstep{background:#fff;border-radius:16px;padding:12px 26px;border:2px solid ${C.border};display:flex;align-items:center;justify-content:space-between;gap:24px}
.fstep.off{opacity:0}
.fstep.past{opacity:.5}
.fstep.current{border-color:${C.green};box-shadow:0 8px 28px rgba(22,163,74,.15)}
.fmath{font-size:30px}
.fmath .katex-display{margin:6px 0}
.fnote{font-size:19px;color:${C.muted};max-width:420px}
.plain-math{font-family:"Cambria Math","STIX Two Math","DejaVu Serif",serif;font-size:34px}
.graph-wrap{display:flex;gap:24px;align-items:center;background:#fff;border-radius:18px;padding:14px;border:2px solid ${C.border}}
.legend div{display:flex;align-items:center;gap:10px;font-size:22px;margin:8px 0;font-family:"Cambria Math","DejaVu Serif",serif}
.legend span{width:28px;height:6px;border-radius:3px;display:inline-block}
.figure-wrap{display:flex;flex-direction:column;align-items:center;gap:12px}
.figure-box{position:relative;background:#fff;border-radius:12px;box-shadow:0 10px 30px rgba(17,24,39,.12);overflow:hidden}
.figure-box img{width:100%;height:100%;display:block}
.hl{position:absolute;border-radius:8px;border:4px solid ${C.green}}
.hl.active{box-shadow:0 0 0 9999px rgba(15,23,42,.35),0 0 18px rgba(22,163,74,.9);background:rgba(22,163,74,.12)}
.hl.done{border-color:rgba(22,163,74,.6)}
.hl.hidden{display:none}
.fig-caption{font-size:20px;max-width:1100px;text-align:center}
.pill{background:${C.green};color:#fff;padding:3px 12px;border-radius:999px}
.muted{color:${C.muted}}
.small{font-size:16px}
.worked{width:100%;max-width:1100px}
.problem{font-size:24px;background:${C.blueLight};border-left:6px solid ${C.blue};padding:14px 20px;border-radius:12px;margin-bottom:14px}
.wstep{display:flex;gap:16px;align-items:center;font-size:26px;margin:8px 0;padding:6px 12px;border-radius:12px}
.wstep .num{flex:0 0 38px;height:38px;border-radius:50%;background:${C.border};display:flex;align-items:center;justify-content:center;font-weight:800;font-size:18px}
.wstep.off{opacity:0}
.wstep.on{opacity:.6}
.wstep.current{opacity:1;background:#fff;box-shadow:0 6px 20px rgba(17,24,39,.08)}
.wstep.current .num{background:${C.green};color:#fff}
.answer{margin-top:14px;font-size:30px;font-weight:800;color:${C.greenDark};background:${C.greenLight};padding:12px 22px;border-radius:14px;display:inline-block}
.tbl{border-collapse:separate;border-spacing:0;font-size:24px;background:#fff;border-radius:14px;overflow:hidden;box-shadow:0 8px 24px rgba(17,24,39,.08);min-width:720px}
.tbl th{background:${C.text};color:#fff;text-align:left;padding:12px 22px}
.tbl td{padding:11px 22px;border-top:1px solid ${C.border}}
.tbl td.num{text-align:right;font-variant-numeric:tabular-nums}
.tbl tr.off td{color:transparent}
.tbl tr.current td{background:${C.greenLight}}
.tbl.ledger th{background:${C.greenDark}}
.timeline{display:flex;gap:18px;width:100%;max-width:1150px;position:relative;align-items:flex-start;padding-top:20px;border-top:5px solid ${C.border}}
.tl{flex:1;position:relative}
.tl-dot{position:absolute;top:-34px;left:0;width:24px;height:24px;border-radius:50%;background:${C.green};border:4px solid #fff}
.tl-label{font-size:26px;font-weight:800;color:${C.greenDark}}
.tl-detail{font-size:19px;margin-top:6px}
.tl.off{opacity:0}.tl.on{opacity:.6}.tl.current{opacity:1}
.flow{display:flex;align-items:center;gap:10px;flex-wrap:wrap;justify-content:center;max-width:1150px}
.node{background:#fff;border:3px solid ${C.border};border-radius:16px;padding:14px 18px;width:230px;min-height:120px}
.node-label{font-size:23px;font-weight:800}
.node-detail{font-size:17px;color:${C.muted};margin-top:6px}
.node.off,.arrow.off{opacity:0}
.node.current{border-color:${C.green};box-shadow:0 8px 24px rgba(22,163,74,.18)}
.arrow{font-size:34px;color:${C.green}}
.dialogue{width:100%;max-width:1000px;display:flex;flex-direction:column;gap:12px}
.bubble{max-width:70%;background:#fff;border-radius:18px;padding:12px 18px;font-size:24px;box-shadow:0 4px 16px rgba(17,24,39,.08)}
.bubble.right{align-self:flex-end;background:${C.greenLight}}
.bubble.off{opacity:0}
.exp{width:100%;max-width:1080px}
.phase{display:inline-flex;gap:12px;align-items:center;font-size:24px;font-weight:800;background:#fff;border:2px solid ${C.border};border-radius:999px;padding:6px 18px;margin-bottom:8px}
.exp-safety .phase{background:${C.amberLight};border-color:#F59E0B;color:#92400E}

/* ── motion: entrance animations (sampled deterministically by the renderer) ── */
@keyframes rise{from{opacity:0;transform:translateY(22px)}to{opacity:1;transform:none}}
@keyframes pop{0%{opacity:0;transform:scale(.82)}70%{opacity:1;transform:scale(1.04)}100%{opacity:1;transform:none}}
@keyframes write{from{clip-path:inset(0 100% 0 0)}to{clip-path:inset(0 0 0 0)}}
@keyframes grow{from{width:0}to{width:84px}}
@keyframes slidein{from{opacity:0;transform:translateX(-46px)}to{opacity:1;transform:none}}
@keyframes pulse{0%{opacity:0;transform:scale(1.35)}60%{opacity:1;transform:scale(.97)}100%{opacity:1;transform:none}}
@keyframes fadein{from{opacity:0}to{opacity:1}}
.first h2.heading{animation:rise .45s cubic-bezier(.2,.8,.2,1) both}
.first h2.heading:after{animation:grow .45s .15s ease-out both}
.list li.current,.tl.current,.bubble.current,.tbl tr.current td,.wstep.current .num{animation:rise .45s cubic-bezier(.2,.8,.2,1) both}
.fstep.current .fmath,.wstep.current>div{animation:write .55s linear both}
.fstep.current{animation:fadein .2s both}
.node.current,.choice.current,.think.current{animation:pop .45s cubic-bezier(.2,.8,.2,1) both}
.hl.active{animation:pulse .5s cubic-bezier(.2,.8,.2,1) both}
.answer{animation:pop .45s both}
.first .kicker{animation:pop .45s both}
.first h1.big{animation:rise .5s .08s cubic-bezier(.2,.8,.2,1) both}
.first .sub{animation:fadein .35s .25s both}

/* ── check questions ── */
.check{width:100%;max-width:1060px;display:flex;flex-direction:column;gap:16px}
.q{font-size:32px;font-weight:800;line-height:1.25}
.choices{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.choice{display:flex;align-items:center;gap:16px;background:#fff;border:3px solid ${C.border};border-radius:16px;padding:14px 18px;font-size:24px;min-height:74px}
.choice .letter{flex:0 0 42px;height:42px;border-radius:50%;background:${C.blueLight};color:${C.blue};font-weight:800;display:flex;align-items:center;justify-content:center;font-size:20px}
.choice.off{opacity:0}
.choice.current{border-color:${C.blue}}
.choice.correct{border-color:${C.green};background:${C.greenLight};animation:pulse .5s both}
.choice.correct .letter{background:${C.green};color:#fff}
.choice.wrong{opacity:.4}
.think{align-self:center;background:${C.text};color:#fff;font-weight:700;font-size:22px;padding:10px 22px;border-radius:999px}
.why{font-size:22px;background:#fff;border-left:6px solid ${C.green};border-radius:12px;padding:12px 18px;animation:rise .45s .15s both}
.credits{width:100%;max-width:1060px;display:flex;flex-direction:column;gap:10px}
.credit-row{display:flex;flex-direction:column;background:#fff;border-radius:12px;padding:12px 18px;font-size:21px;box-shadow:0 4px 16px rgba(17,24,39,.06)}
.credit-row span{color:${C.muted};font-size:17px;margin-top:2px}

/* ── split layout: media panel on the right ── */
.split .content{padding-right:${W - PANEL.x + 24}px;justify-content:flex-start}
.split .list li{font-size:25px;margin:8px 0;padding:10px 14px}
.split .exp,.split .list{max-width:100%}
.bgmask{position:absolute;inset:0;z-index:-1}
.panel-credit{position:absolute;left:${PANEL.x}px;top:${PANEL.y + PANEL.h + 10}px;width:${PANEL.w}px;font-size:13px;color:${C.muted};text-align:right}

/* ── full layout: media fills the frame ── */
.full{color:#fff}
.full .brand,.full .footer{color:rgba(255,255,255,.85)}
.full .brand b{color:#4ADE80}
.full .dots span{background:rgba(255,255,255,.35)}
.full .dots span.on{background:#4ADE80}
.scrim{position:absolute;inset:0}
.scrim.title{background:linear-gradient(180deg,rgba(2,6,23,.45) 0%,rgba(2,6,23,.55) 50%,rgba(2,6,23,.75) 100%)}
.scrim.media{background:linear-gradient(180deg,rgba(2,6,23,.45) 0%,rgba(2,6,23,0) 22%,rgba(2,6,23,0) 42%,rgba(2,6,23,.82) 100%)}
.full .title-wrap{position:absolute;left:0;right:0;top:50%;transform:translateY(-50%);margin:0 auto}
.full .kicker{background:#4ADE80;color:#052e16}
.full .sub{color:rgba(255,255,255,.88)}
.full h1.big{text-shadow:0 4px 24px rgba(0,0,0,.45)}
.lower{position:absolute;left:64px;right:64px;bottom:64px}
.lt-bar{display:inline-block;background:${C.green};padding:10px 22px 12px;border-radius:12px;box-shadow:0 10px 30px rgba(0,0,0,.35)}
.lt-bar h2{font-size:36px;font-weight:800;letter-spacing:-.4px;color:#fff}
.first .lt-bar{animation:slidein .5s cubic-bezier(.2,.8,.2,1) both}
.chips{display:flex;flex-wrap:wrap;gap:12px;margin-top:14px;max-width:1100px}
.chip{background:rgba(255,255,255,.95);color:${C.text};font-size:24px;font-weight:600;padding:10px 18px;border-radius:12px;box-shadow:0 8px 22px rgba(0,0,0,.25)}
.chip.off{opacity:0}
.chip.current{animation:pop .45s cubic-bezier(.2,.8,.2,1) both}
.full-credit{position:absolute;right:64px;bottom:44px;font-size:13px;color:rgba(255,255,255,.8);text-shadow:0 1px 4px rgba(0,0,0,.6)}
.full .lower{bottom:72px}
`;

/**
 * How a scene is laid out, given the stock media found for it.
 * @returns {'none'|'split'|'full'}
 */
function layoutOf(scene, asset) {
  if (!asset) return 'none';
  if (scene.type === 'media' || scene.type === 'title') return 'full';
  if (scene.type === 'bullets' || scene.type === 'experiment') return 'split';
  return 'none';
}

function panelMask() {
  const { x, y, w, h, r } = PANEL;
  const hole = `M${x + r} ${y}H${x + w - r}A${r} ${r} 0 0 1 ${x + w} ${y + r}V${y + h - r}A${r} ${r} 0 0 1 ${x + w - r} ${y + h}H${x + r}A${r} ${r} 0 0 1 ${x} ${y + h - r}V${y + r}A${r} ${r} 0 0 1 ${x + r} ${y}Z`;
  return `<svg class="bgmask" xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}"><defs>
<linearGradient id="bgg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".6" stop-color="${C.bg}"/><stop offset="1" stop-color="#EEF7F1"/></linearGradient>
<filter id="sh" x="-10%" y="-10%" width="120%" height="120%"><feDropShadow dx="0" dy="10" stdDeviation="12" flood-color="#111827" flood-opacity=".18"/></filter></defs>
<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="none" stroke="#fff" stroke-width="10" filter="url(#sh)"/>
<path fill="url(#bgg)" fill-rule="evenodd" d="M0 0H${W}V${H}H0Z ${hole}"/>
<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="none" stroke="#fff" stroke-width="6"/></svg>`;
}

/** Full HTML document for one frame. */
function renderFrame(scene, state, ctx) {
  const asset = ctx.media?.get(scene.n) || null;
  const layout = layoutOf(scene, asset);
  const disclosure = scene.disclosure ? `<div class="disclosure">${esc(scene.disclosure)}</div>` : '';
  const pages = scene.sourcePages?.length ? `Source: textbook p. ${scene.sourcePages.join(', ')}` : '';
  const dots = Array.from({ length: ctx.totalScenes }, (_, i) => `<span class="${i < scene.n ? 'on' : ''}"></span>`).join('');
  const labels = scene.onScreenLabels?.length && layout !== 'full' ? `<div class="labels">${scene.onScreenLabels.map(l => `<span>${esc(l)}</span>`).join('')}</div>` : '';
  const brand = `<div class="brand"><b>ECH</b> · ${esc(ctx.lessonTitle)}</div>`;
  const footer = `<div class="footer"><span>${esc(pages)}</span><span class="dots">${dots}</span></div>`;
  const cls = [layout === 'none' ? '' : layout, state.first ? 'first' : ''].join(' ');
  const bodyBg = layout === 'none' ? '' : '<style>html,body{background:transparent!important}</style>';

  let inner;
  if (layout === 'full' && scene.type === 'title') {
    inner = `<div class="scrim title"></div>${brand}${disclosure}${body(scene, state, ctx)}<div class="full-credit">${esc(asset.credit)}</div>${footer}`;
  } else if (layout === 'full') {
    const chips = (scene.points || []).map((p, i) => `<div class="chip ${i < state.reveal ? (i === state.reveal - 1 ? 'on current' : 'on') : 'off'}">${esc(p)}</div>`).join('');
    inner = `<div class="scrim media"></div>${brand}${disclosure}<div class="lower"><div class="lt-bar"><h2>${esc(scene.heading || '')}</h2></div><div class="chips">${chips}</div></div><div class="full-credit">${esc(asset.credit)}</div>${footer}`;
  } else {
    const heading = scene.type === 'title' ? '' : `<h2 class="heading">${esc(scene.heading || '')}</h2>`;
    const panel = layout === 'split' ? `${panelMask()}<div class="panel-credit">${esc(asset.credit)}</div>` : '';
    inner = `${panel}${brand}${disclosure}${heading}<div class="content">${body(scene, state, ctx)}</div>${labels}${footer}`;
  }
  return `<!doctype html><html><head><meta charset="utf-8"><link rel="stylesheet" href="${KATEX_CSS}"><style>${CSS}</style>${bodyBg}</head>
<body><div class="frame ${cls}">${inner}</div></body></html>`;
}

module.exports = { framesFor, renderFrame, layoutOf, plotSvg, sampleGraph, W, H, PANEL, ANIM_SECONDS, esc };
