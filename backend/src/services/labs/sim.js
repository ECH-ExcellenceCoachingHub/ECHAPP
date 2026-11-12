/**
 * Reference science models. The Unity runtime (ECHLabs.Sim, C#) implements the
 * same formulas; both test suites assert the same golden values so the two can
 * never drift apart. The backend uses these to check that a scenario's expected
 * results (often written by AI) are scientifically correct.
 */

const KW = 1e-14;
const G = 9.80665;

// Acids and bases the chemistry lab knows. Ka = null → strong (fully dissociated).
const ACIDS = {
  HCl: { name: 'Hydrochloric acid', ka: null, protons: 1 },
  HNO3: { name: 'Nitric acid', ka: null, protons: 1 },
  CH3COOH: { name: 'Ethanoic (acetic) acid', ka: 1.8e-5, protons: 1 },
};
const BASES = {
  NaOH: { name: 'Sodium hydroxide', strong: true },
  KOH: { name: 'Potassium hydroxide', strong: true },
};

const INDICATORS = {
  phenolphthalein: { low: 8.2, high: 10.0, from: 'colourless', to: 'pink' },
  methyl_orange: { low: 3.1, high: 4.4, from: 'red', to: 'yellow' },
  bromothymol_blue: { low: 6.0, high: 7.6, from: 'yellow', to: 'blue' },
  universal: { low: 3.0, high: 11.0, from: 'red', to: 'purple' },
};

/**
 * pH of a mixture holding `acidMol` of an acid (Ka, or strong) and `baseMol` of a
 * strong monoprotic base in `volumeL` litres. Solves the charge balance
 *   [Na+] + [H+] = [OH-] + [A-]
 * by bisection on pH, which stays exact through the equivalence point.
 */
function mixturePH({ acidMol, acidKa, baseMol, volumeL }) {
  if (!(volumeL > 0)) return 7;
  const ca = Math.max(acidMol, 0) / volumeL;
  const cb = Math.max(baseMol, 0) / volumeL;
  const balance = (pH) => {
    const h = 10 ** -pH;
    const oh = KW / h;
    const a = acidKa == null ? ca : (ca * acidKa) / (acidKa + h);
    return cb + h - oh - a; // decreasing in pH
  };
  let lo = -1;
  let hi = 15;
  for (let i = 0; i < 100; i++) {
    const mid = (lo + hi) / 2;
    if (balance(mid) > 0) lo = mid; else hi = mid;
  }
  return (lo + hi) / 2;
}

/** Acid in the flask titrated by a strong base from the burette. */
function titration({ acid, acidConc, acidVolumeMl, baseConc, baseAddedMl }) {
  const def = ACIDS[acid];
  if (!def) throw new Error(`Unknown acid ${acid}`);
  const acidMol = acidConc * acidVolumeMl / 1000;
  const baseMol = baseConc * baseAddedMl / 1000;
  const pH = mixturePH({ acidMol, acidKa: def.ka, baseMol, volumeL: (acidVolumeMl + baseAddedMl) / 1000 });
  return {
    pH,
    equivalenceVolumeMl: baseConc > 0 ? (acidMol / baseConc) * 1000 : Infinity,
  };
}

/** 0 → indicator's low-pH colour, 1 → high-pH colour (smoothstep across its range). */
function indicatorColorIndex(indicator, pH) {
  const def = INDICATORS[indicator];
  if (!def) return 0;
  const t = Math.min(Math.max((pH - def.low) / (def.high - def.low), 0), 1);
  return t * t * (3 - 2 * t);
}

/** Period of a simple pendulum with the finite-amplitude correction. */
function pendulumPeriod({ lengthM, amplitudeDeg = 0, g = G }) {
  const t0 = 2 * Math.PI * Math.sqrt(lengthM / g);
  const th = (amplitudeDeg * Math.PI) / 180;
  return { theoreticalPeriodS: t0, periodS: t0 * (1 + (th * th) / 16 + (11 * th ** 4) / 3072) };
}

/** Series DC circuit: supply V with internal resistance r and resistors R1..Rn. */
function seriesCircuit({ voltageV, resistorsOhm, internalOhm = 0 }) {
  const total = resistorsOhm.reduce((s, r) => s + r, 0) + internalOhm;
  if (total <= 0) return { currentA: Infinity, voltageV: 0, powerW: Infinity, shortCircuit: true };
  const currentA = voltageV / total;
  const loadV = currentA * resistorsOhm.reduce((s, r) => s + r, 0);
  return { currentA, voltageV: loadV, powerW: currentA * loadV, shortCircuit: false };
}

/** Parallel group resistance. */
function parallel(resistorsOhm) {
  return 1 / resistorsOhm.reduce((s, r) => s + 1 / r, 0);
}

module.exports = { KW, G, ACIDS, BASES, INDICATORS, mixturePH, titration, indicatorColorIndex, pendulumPeriod, seriesCircuit, parallel };
