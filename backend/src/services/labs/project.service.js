/**
 * Student "My experiments": a student designs their own experiment in a lab room
 * (equipment + settings + their own procedure) and runs it in the 3D lab.
 *
 * The app edits a small project spec; compileProject() turns it into a normal
 * scenario (slots, simulation variables, safety hazards, scoring, ids) that
 * passes validateScenario(), so the Unity engine plays it unchanged.
 *
 * The builder kit (what each room offers, the settings each item has, the actions
 * and readings that make sense) is defined here so the app stays generic.
 */
const catalog = require('./catalog.json');
const sim = require('./sim');
const { validateScenario } = require('./validator');
const { SUBJECT_TO_ENV, slugify } = require('./generator.service');

const ENV_TO_SUBJECT = Object.fromEntries(Object.entries(SUBJECT_TO_ENV).map(([s, e]) => [e, s]));

const o = (value, label) => ({ value, label });
/** Liquids a bottle/beaker/tube can start with (ids match Unity Sim/Mixtures.cs recipes). */
const SOLUTIONS = [
  o('water', 'Distilled water'),
  o('HCl', 'Hydrochloric acid (HCl)'), o('HNO3', 'Nitric acid (HNO₃)'), o('H2SO4', 'Sulfuric acid (H₂SO₄)'), o('CH3COOH', 'Ethanoic acid / vinegar (CH₃COOH)'),
  o('NaOH', 'Sodium hydroxide (NaOH)'), o('KOH', 'Potassium hydroxide (KOH)'), o('NH3', 'Ammonia solution (NH₃)'), o('CaOH2', 'Limewater (Ca(OH)₂)'),
  o('NaCl', 'Sodium chloride (NaCl)'), o('KI', 'Potassium iodide (KI)'), o('AgNO3', 'Silver nitrate (AgNO₃)'), o('BaCl2', 'Barium chloride (BaCl₂)'),
  o('CuSO4', 'Copper(II) sulfate (CuSO₄)'), o('FeSO4', 'Iron(II) sulfate (FeSO₄)'), o('FeCl3', 'Iron(III) chloride (FeCl₃)'), o('MgSO4', 'Magnesium sulfate (MgSO₄)'),
  o('ZnSO4', 'Zinc sulfate (ZnSO₄)'), o('Na2CO3', 'Sodium carbonate (Na₂CO₃)'), o('NaHCO3', 'Sodium hydrogencarbonate (NaHCO₃)'), o('Na2S2O3', 'Sodium thiosulfate (Na₂S₂O₃)'),
  o('H2O2', 'Hydrogen peroxide (H₂O₂)'), o('glucose_sol', 'Glucose solution'), o('sucrose_sol', 'Sucrose (sugar) solution'), o('starch_sol', 'Starch solution (1%)'), o('ethanol', 'Ethanol'),
];
/** Solids and food samples (a spatula / small piece at a time). */
const SUBSTANCES = [
  o('Mg', 'Magnesium ribbon'), o('Zn', 'Zinc granules'), o('Fe', 'Iron filings'), o('Cu', 'Copper turnings'), o('CaCO3', 'Marble chips (CaCO₃)'),
  o('CuO', 'Copper(II) oxide powder'), o('MnO2', 'Manganese(IV) oxide (catalyst)'), o('NaCl_s', 'Salt (NaCl)'), o('CuSO4_s', 'Copper sulfate crystals'),
  o('NaHCO3', 'Sodium hydrogencarbonate (baking soda)'), o('Na2CO3_s', 'Sodium carbonate powder'), o('NH4NO3', 'Ammonium nitrate (gets cold)'),
  o('glucose', 'Glucose powder'), o('sucrose', 'Sugar (sucrose)'), o('starch', 'Starch powder'),
  o('milk', 'Milk'), o('egg_white', 'Egg white'), o('bread', 'Bread'), o('apple_juice', 'Apple juice'), o('honey', 'Honey'), o('vegetable_oil', 'Vegetable oil'),
  o('potato', 'Potato (chopped)'), o('liver', 'Liver (chopped)'),
];
/** Dropping-bottle reagents (about 1 mL per use). */
const REAGENTS = [
  o('universal', 'Universal indicator'), o('phenolphthalein', 'Phenolphthalein'), o('methyl_orange', 'Methyl orange'), o('bromothymol_blue', 'Bromothymol blue'), o('litmus', 'Litmus'),
  o('iodine', 'Iodine solution (starch test)'), o('benedicts', "Benedict's reagent (sugar test)"), o('biuret', 'Biuret reagent (protein test)'), o('ethanol', 'Ethanol (fat test)'),
  o('CaOH2', 'Limewater (CO₂ test)'), o('AgNO3', 'Silver nitrate (halide test)'), o('BaCl2', 'Barium chloride (sulfate test)'), o('NaOH', 'Sodium hydroxide (dilute)'), o('HCl', 'Hydrochloric acid (dilute)'),
  o('amylase', 'Amylase (enzyme)'), o('lipase', 'Lipase (enzyme)'), o('pepsin', 'Pepsin (enzyme)'), o('catalase_sol', 'Catalase (enzyme)'),
];
const INDICATORS = Object.entries(sim.INDICATORS).map(([value, i]) => ({ value, label: `${value.replace(/_/g, ' ')} (${i.from} → ${i.to})` }));
const STAINS = [o('iodine', 'Iodine solution'), o('methylene_blue', 'Methylene blue'), o('eosin', 'Eosin')];
const SPECIMENS = [o('onion', 'Onion epidermis'), o('cheek', 'Cheek cells'), o('leaf', 'Leaf (Elodea)'), o('blood', 'Blood smear'), o('pond_water', 'Pond water'), o('hair', 'Human hair'), o('root_tip', 'Root tip (mitosis)'), o('pollen', 'Pollen grains')];
const MATERIALS = [o('aluminium', 'Aluminium'), o('steel', 'Steel'), o('brass', 'Brass'), o('copper', 'Copper'), o('lead', 'Lead'), o('wood', 'Wood'), o('acrylic', 'Acrylic plastic')];

const num = (key, label, unit, min, max, def, step) => ({ key, label, unit, type: 'number', min, max, default: def, step });
const sel = (key, label, options, def) => ({ key, label, type: 'select', options, default: def });
const conc = num('conc', 'Concentration', 'mol/dm³', 0.01, 2, 0.1, 0.01);
const startTemp = num('temperature', 'Starting temperature', '°C', 0, 90, 20, 1);

/** Anything with simulated contents. */
const VESSELS = ['beaker', 'test_tube', 'conical_flask', 'measuring_cylinder', 'evaporating_dish'];
const LIQUID_INTO = ['burette', 'conical_flask', 'beaker', 'pipette', 'test_tube', 'measuring_cylinder', 'evaporating_dish'];
const HEATERS = ['hot_plate', 'bunsen_burner', 'water_bath'];
const DIP_INTO = [...VESSELS, 'water_bath'];

const pour = (into = LIQUID_INTO) => ({ key: 'pour', label: 'Pour into…', intent: 'Pour', into, text: 'Pour some of the {label} into the {intoLabel}.' });
const place = (into, text = 'Place the {label} in/on the {intoLabel}.') => ({ key: 'place', label: 'Place in / on…', intent: 'Grab', into, until: '{id}.placedIn == {intoQ}', text });
const look = (text = 'Observe the {label} closely and note what you see.') => ({ key: 'look', label: 'Observe', intent: 'Inspect', text });
const toggleOn = (text) => ({ key: 'on', label: 'Switch on', intent: 'Toggle', until: '{id}.on', text });
const toggleOff = (text) => ({ key: 'off', label: 'Switch off', intent: 'Toggle', until: '!{id}.on', text });
const contentsReadings = [];

/**
 * Per equipment type: where it goes (place), settings, actions and readings.
 * Action/reading templates: {id} = this item, {into} = receiver id, {intoQ} = quoted receiver id,
 * {v} = value chosen, {lo}/{hi} = accepted range, {n} = a count, {pend} = the first pendulum.
 * Model variables have fixed names (titr, circ, pm, mic, fw) — see autoVariables().
 */
const KIT = {
  // ── Safety ──
  goggles: { place: 'ppe', max: 1, params: [], actions: [{ key: 'wear', label: 'Put on', intent: 'Grab', until: '{id}.worn', text: 'Put on the safety goggles.' }] },
  labcoat: { place: 'ppe', max: 1, params: [], actions: [{ key: 'wear', label: 'Put on', intent: 'Grab', until: '{id}.worn', text: 'Put on the lab coat.' }] },
  gloves: { place: 'ppe', max: 1, params: [], actions: [{ key: 'wear', label: 'Put on', intent: 'Grab', until: '{id}.worn', text: 'Put on the gloves.' }] },

  // ── Containers ──
  reagent_bottle: {
    place: 'shelf', max: 6,
    params: [sel('solution', 'Solution', SOLUTIONS, 'NaOH'), conc, num('volume', 'Volume in bottle', 'mL', 50, 1000, 500, 10)],
    actions: [pour()],
  },
  beaker: {
    place: 'bench', max: 4,
    params: [sel('solution', 'Contains', SOLUTIONS, 'water'), conc, num('volume', 'Volume', 'mL', 0, 250, 100, 5), startTemp],
    actions: [pour(), place([...HEATERS, 'balance']), { key: 'stir', label: 'Stir', intent: 'Rotate', text: 'Stir the {label}.' }, look()],
  },
  test_tube: {
    place: 'bench', max: 8,
    params: [sel('solution', 'Contains', SOLUTIONS, 'water'), conc, num('volume', 'Volume', 'mL', 0, 20, 5, 1), startTemp],
    actions: [pour(), place([...HEATERS, 'balance']), { key: 'shake', label: 'Shake', intent: 'Rotate', text: 'Shake the {label} gently.' }, look()],
  },
  measuring_cylinder: {
    place: 'bench', max: 2,
    params: [sel('solution', 'Contains', SOLUTIONS, 'water'), conc, num('volume', 'Volume', 'mL', 0, 100, 50, 1)],
    actions: [pour(), place(['balance']), look('Read the {label} at eye level, at the bottom of the meniscus.')],
    readings: [{ key: 'volume', label: 'Volume (scale)', unit: 'mL', truth: '{id}.reading', tolerance: 0.5 }],
  },
  evaporating_dish: {
    place: 'bench', max: 2,
    params: [sel('solution', 'Contains', SOLUTIONS, 'NaCl'), conc, num('volume', 'Volume', 'mL', 0, 60, 20, 1)],
    actions: [pour(), place(['hot_plate', 'bunsen_burner', 'balance']), look()],
  },
  pipette: {
    place: 'bench', max: 1,
    params: [sel('solution', 'Solution', SOLUTIONS, 'HCl'), conc, num('volume', 'Volume', 'mL', 0, 25, 0, 1)],
    actions: [{ key: 'pour', label: 'Run into…', intent: 'Pour', into: ['conical_flask', 'beaker', 'test_tube'], text: 'Run the pipette into the {intoLabel}.' }],
  },
  burette: {
    place: 'bench', max: 1,
    params: [sel('solution', 'Solution', SOLUTIONS, 'NaOH'), conc, num('volume', 'Capacity', 'mL', 25, 50, 50, 1)],
    actions: [
      { key: 'endpoint', label: 'Open the tap until the colour changes', intent: 'Rotate', needsModel: 'titr', until: 'titr.colorIndex >= 0.35', text: 'Open the tap and add solution drop by drop while swirling, until the colour changes.' },
      { key: 'tap', label: 'Turn the tap', intent: 'Rotate', text: 'Turn the burette tap.' },
      { key: 'read', label: 'Read the scale', intent: 'Inspect', text: 'Read the burette scale at eye level.' },
    ],
    readings: [{ key: 'reading', label: 'Burette reading', unit: 'cm³', truth: '{id}.reading', tolerance: 0.05 }],
  },
  conical_flask: {
    place: 'bench', max: 2,
    params: [sel('solution', 'Contains', SOLUTIONS, 'HCl'), conc, num('volume', 'Volume', 'mL', 0, 250, 25, 1), startTemp],
    actions: [
      { key: 'tile', label: 'Place on…', intent: 'Grab', into: ['white_tile', ...HEATERS, 'balance'], text: 'Place the {label} on the {intoLabel}.' },
      pour(), { key: 'swirl', label: 'Swirl', intent: 'Rotate', text: 'Swirl the {label}.' }, look('Observe the colour of the solution in the {label}.'),
    ],
  },

  // ── Chemicals ──
  solid_jar: {
    place: 'shelf', max: 6,
    params: [sel('substance', 'Solid / sample', SUBSTANCES, 'Mg')],
    actions: [{ key: 'add', label: 'Add a spatula to…', intent: 'Pour', into: VESSELS, text: 'Add a small amount of {label} to the {intoLabel}.' }],
  },
  dropper_bottle: {
    place: 'shelf', max: 6,
    params: [sel('reagent', 'Reagent', REAGENTS, 'universal')],
    actions: [{ key: 'add', label: 'Add drops to…', intent: 'Pour', into: VESSELS, text: 'Add a few drops of {label} to the {intoLabel}.' }],
  },
  indicator: {
    place: 'shelf', max: 3,
    params: [sel('name', 'Indicator', INDICATORS, 'phenolphthalein')],
    actions: [{ key: 'add', label: 'Add drops to…', intent: 'Pour', into: ['conical_flask', 'beaker', 'test_tube'], text: 'Add 2–3 drops of {label} to the {intoLabel}.' }],
  },
  funnel: { place: 'bench', max: 1, params: [], actions: [{ key: 'place', label: 'Put in the burette', intent: 'Grab', text: 'Place the funnel in the top of the burette.' }] },
  white_tile: { place: 'bench', max: 1, params: [], actions: [{ key: 'look', label: 'Select', intent: 'Select', text: 'Find the white tile.' }] },
  retort_stand: { place: 'bench', max: 1, params: [], actions: [{ key: 'look', label: 'Select', intent: 'Select', text: 'Check the retort stand and clamp.' }] },
  splint: {
    place: 'bench', max: 3,
    params: [sel('mode', 'Splint', [o('lit', 'Lit (burning)'), o('glowing', 'Glowing')], 'lit')],
    actions: [{ key: 'test', label: 'Hold at the mouth of…', intent: 'Grab', into: VESSELS, until: '{id}.tested', text: 'Hold the {label} at the mouth of the {intoLabel} and watch what happens.' }],
  },
  delivery_tube: {
    place: 'bench', max: 2, params: [],
    actions: [
      { key: 'fit', label: 'Fit the bung into…', intent: 'Grab', into: VESSELS, until: '{id}.from == {intoQ}', text: 'Fit the bung and delivery tube into the {intoLabel}.' },
      { key: 'lead', label: 'Lead the tube into…', intent: 'Connect', into: VESSELS, until: '{id}.to == {intoQ}', text: 'Put the end of the delivery tube into the {intoLabel}.' },
    ],
    readings: [{ key: 'gas', label: 'Gas collected (gas syringe)', unit: 'cm³', truth: '{id}.gasPassedMl', tolerance: 2 }],
  },

  // ── Heat ──
  bunsen_burner: {
    place: 'bench', max: 1, params: [],
    actions: [
      { key: 'light', label: 'Light it', intent: 'Toggle', until: '{id}.lit', text: 'Light the Bunsen burner.' },
      { key: 'off', label: 'Turn it off', intent: 'Toggle', until: '!{id}.lit', text: 'Turn off the Bunsen burner.' },
      { key: 'air', label: 'Set the air hole', intent: 'Rotate', value: { label: 'Air hole (0 closed → 1 open)', unit: '', min: 0, max: 1, step: 0.05, default: 1, spread: 0.1 }, text: 'Turn the collar to set the air hole to {v}.' },
    ],
  },
  hot_plate: {
    place: 'bench', max: 2,
    params: [num('powerW', 'Starting power', 'W', 0, 400, 200, 10)],
    actions: [
      toggleOn('Switch on the hot plate.'), toggleOff('Switch off the hot plate.'),
      { key: 'power', label: 'Set the power', intent: 'Rotate', value: { label: 'Power', unit: 'W', min: 0, max: 400, step: 10, default: 200, spread: 5 }, until: 'between({id}.powerW, {lo}, {hi})', text: 'Set the hot plate to {v} W.' },
    ],
    readings: [
      { key: 'energy', label: 'Energy supplied (joulemeter)', unit: 'J', truth: '{id}.energyJ', tolerance: 300 },
      { key: 'power', label: 'Power setting', unit: 'W', truth: '{id}.powerW', tolerance: 1 },
    ],
  },
  water_bath: {
    place: 'bench', max: 2,
    params: [num('setpointC', 'Set temperature', '°C', 5, 100, 37, 1)],
    actions: [
      toggleOn('Switch on the water bath.'),
      { key: 'set', label: 'Set the temperature', intent: 'Rotate', value: { label: 'Temperature', unit: '°C', min: 5, max: 100, step: 1, default: 37, spread: 0.5 }, until: 'between({id}.setpointC, {lo}, {hi})', text: 'Set the water bath to {v} °C.' },
    ],
    readings: [{ key: 'temp', label: 'Water bath temperature', unit: '°C', truth: '{id}.reading', tolerance: 0.5 }],
  },

  // ── Measuring ──
  thermometer: {
    place: 'bench', max: 3, params: [],
    actions: [{ key: 'dip', label: 'Put into…', intent: 'Connect', into: DIP_INTO, until: '{id}.in == {intoQ}', text: 'Put the thermometer into the {intoLabel}.' }],
    readings: [{ key: 'temp', label: 'Temperature', unit: '°C', truth: '{id}.reading', tolerance: 0.5 }],
  },
  ph_meter: {
    place: 'bench', max: 1, params: [],
    actions: [{ key: 'dip', label: 'Dip into…', intent: 'Connect', into: VESSELS, until: '{id}.in == {intoQ}', text: 'Dip the pH probe into the {intoLabel}.' }],
    readings: [{ key: 'ph', label: 'pH', unit: '', truth: '{id}.reading', tolerance: 0.1 }],
  },
  balance: {
    place: 'bench', max: 1, params: [],
    actions: [{ key: 'tare', label: 'Zero (tare)', intent: 'Toggle', text: 'Press TARE to zero the balance.' }],
    readings: [{ key: 'mass', label: 'Mass', unit: 'g', truth: '{id}.reading', tolerance: 0.02 }],
  },
  stopwatch: {
    place: 'bench', max: 1, params: [],
    actions: [
      { key: 'timeN', label: 'Time a number of swings', intent: 'Toggle', needsType: 'pendulum', count: { label: 'Number of swings', min: 1, max: 50, default: 10 }, until: '{pend}.oscillations >= {n} && !{id}.running', text: 'Start the stopwatch, count {n} complete swings, then stop it.' },
      { key: 'start', label: 'Start', intent: 'Toggle', until: '{id}.running', text: 'Start the stopwatch.' },
      { key: 'stop', label: 'Stop', intent: 'Toggle', until: '!{id}.running', text: 'Stop the stopwatch.' },
      { key: 'reset', label: 'Reset', intent: 'Select', until: '{id}.elapsedS == 0', text: 'Reset the stopwatch to zero.' },
    ],
    readings: [{ key: 'time', label: 'Stopwatch time', unit: 's', truth: '{id}.elapsedS', tolerance: 0.2 }],
  },
  metre_rule: { place: 'bench', max: 1, params: [], actions: [{ key: 'measure', label: 'Measure with it', intent: 'Inspect', text: 'Use the metre rule to measure.' }] },

  // ── Electricity ──
  power_supply: {
    place: 'bench', max: 1,
    params: [num('maxVoltage', 'Maximum voltage', 'V', 3, 24, 12, 1)],
    actions: [
      { key: 'on', label: 'Switch on', intent: 'Toggle', until: '{id}.on', text: 'Switch on the power supply.' },
      { key: 'off', label: 'Switch off', intent: 'Toggle', until: '!{id}.on', text: 'Switch off the power supply.' },
      { key: 'volts', label: 'Set the voltage', intent: 'Rotate', value: { label: 'Voltage', unit: 'V', min: 0, max: 24, step: 0.5, default: 6, spread: 0.1, maxFrom: 'maxVoltage' }, until: 'between({id}.voltageV, {lo}, {hi})', text: 'Turn the voltage knob to {v} V.' },
    ],
    readings: [{ key: 'volts', label: 'Supply voltage (display)', unit: 'V', truth: '{id}.voltageV', tolerance: 0.1 }],
  },
  battery: {
    place: 'bench', max: 4,
    params: [sel('voltage', 'Voltage', [1.5, 3, 4.5, 6, 9, 12].map((v) => ({ value: v, label: `${v} V` })), 3)],
    actions: [{ key: 'connect', label: 'Connect to…', intent: 'Connect', into: ['breadboard'], until: '{id}.connected', text: 'Connect the {label} to the circuit.' }],
  },
  switch: {
    place: 'bench', max: 2, params: [],
    actions: [
      { key: 'connect', label: 'Connect to…', intent: 'Connect', into: ['breadboard'], until: '{id}.connected', text: 'Connect the switch into the circuit.' },
      { key: 'close', label: 'Close (on)', intent: 'Toggle', until: '{id}.closed', text: 'Close the switch.' },
      { key: 'open', label: 'Open (off)', intent: 'Toggle', until: '!{id}.closed', text: 'Open the switch.' },
    ],
  },
  breadboard: {
    place: 'bench', max: 1,
    params: [sel('layout', 'How are the components joined?', [o('series', 'In series (one loop)'), o('parallel', 'In parallel (side by side)')], 'series')],
    actions: [{ key: 'look', label: 'Check the circuit', intent: 'Inspect', text: 'Check your circuit on the board.' }],
  },
  resistor: {
    place: 'bench', max: 4,
    params: [num('ohms', 'Resistance', 'Ω', 1, 1000, 47, 1)],
    actions: [
      { key: 'connect', label: 'Connect to…', intent: 'Connect', into: ['breadboard'], until: '{id}.connected', text: 'Connect the {label} to the circuit board.' },
      { key: 'remove', label: 'Disconnect', intent: 'Release', until: '!{id}.connected', text: 'Disconnect the {label}.' },
    ],
  },
  variable_resistor: {
    place: 'bench', max: 1,
    params: [num('maxOhms', 'Maximum resistance', 'Ω', 10, 200, 100, 10)],
    actions: [
      { key: 'connect', label: 'Connect to…', intent: 'Connect', into: ['breadboard'], until: '{id}.connected', text: 'Connect the rheostat into the circuit.' },
      { key: 'set', label: 'Set the resistance', intent: 'Rotate', value: { label: 'Resistance', unit: 'Ω', min: 1, max: 200, step: 1, default: 50, spread: 1, maxFrom: 'maxOhms' }, until: 'between({id}.ohms, {lo}, {hi})', text: 'Slide the rheostat to {v} Ω.' },
    ],
    readings: [{ key: 'ohms', label: 'Rheostat setting', unit: 'Ω', truth: '{id}.ohms', tolerance: 0.5 }],
  },
  bulb: {
    place: 'bench', max: 3,
    params: [sel('ratedVoltage', 'Rated voltage', [2.5, 6, 12].map((v) => ({ value: v, label: `${v} V` })), 6), num('ratedPower', 'Rated power', 'W', 0.3, 24, 3, 0.1)],
    actions: [{ key: 'connect', label: 'Connect to…', intent: 'Connect', into: ['breadboard'], until: '{id}.connected', text: 'Connect the {label} to the circuit.' }, look('Look at how brightly the {label} glows.')],
  },
  led: {
    place: 'bench', max: 3,
    params: [sel('colour', 'Colour', ['red', 'yellow', 'green', 'blue', 'white'].map((c) => o(c, c)), 'red')],
    actions: [{ key: 'connect', label: 'Connect to…', intent: 'Connect', into: ['breadboard'], until: '{id}.connected', text: 'Connect the {label} to the circuit.' }, look('Is the {label} lit?')],
  },
  ammeter: {
    place: 'bench', max: 1, params: [],
    actions: [{ key: 'connect', label: 'Connect in series', intent: 'Connect', into: ['breadboard'], until: '{id}.connected', text: 'Connect the ammeter in series.' }],
    readings: [{ key: 'reading', label: 'Ammeter reading (current)', unit: 'A', truth: '{id}.reading', tolerance: 0.003 }],
  },
  voltmeter: {
    place: 'bench', max: 1, params: [],
    actions: [{ key: 'connect', label: 'Connect in parallel', intent: 'Connect', into: ['breadboard'], until: '{id}.connected', text: 'Connect the voltmeter in parallel across the components.' }],
    readings: [{ key: 'reading', label: 'Voltmeter reading (voltage)', unit: 'V', truth: '{id}.reading', tolerance: 0.05 }],
  },

  // ── Forces & motion ──
  pendulum: {
    place: 'bench', max: 1,
    params: [num('lengthM', 'String length', 'm', 0.2, 2, 0.8, 0.05), num('massKg', 'Bob mass', 'kg', 0.01, 1, 0.05, 0.01)],
    actions: [
      { key: 'release', label: 'Pull aside & release', intent: 'Release', value: { label: 'Release angle', unit: '°', min: 2, max: 30, step: 1, default: 8, spread: 2 }, until: '{id}.swinging', text: 'Pull the bob aside to about {v}° and release it.' },
      { key: 'stop', label: 'Stop the bob', intent: 'Grab', until: '!{id}.swinging', text: 'Stop the bob.' },
    ],
    readings: [
      { key: 'length', label: 'Length (measure with the metre rule)', unit: 'm', truth: '{id}.lengthM', tolerance: 0.005 },
      { key: 'swings', label: 'Number of complete swings', unit: 'swings', truth: '{id}.oscillations', tolerance: 0 },
    ],
  },
  spring: {
    place: 'bench', max: 2,
    params: [num('springConstant', 'Spring constant (hidden from you!)', 'N/m', 5, 200, 25, 1), num('naturalLengthCm', 'Unstretched length', 'cm', 3, 30, 10, 0.5), num('elasticLimitN', 'Elastic limit', 'N', 1, 50, 6, 0.5)],
    actions: [
      { key: 'hang', label: 'Hang masses', intent: 'Rotate', value: { label: 'Total mass', unit: 'g', min: 0, max: 1000, step: 50, default: 100, spread: 1 }, until: 'between({id}.massG, {lo}, {hi})', text: 'Hang {v} g of slotted masses on the spring.' },
      { key: 'unload', label: 'Remove all masses', intent: 'Release', until: '{id}.massG == 0', text: 'Take all the masses off the spring.' },
    ],
    readings: [
      { key: 'ext', label: 'Extension', unit: 'cm', truth: '{id}.extensionCm', tolerance: 0.1 },
      { key: 'len', label: 'Length of spring', unit: 'cm', truth: '{id}.lengthCm', tolerance: 0.1 },
      { key: 'force', label: 'Force (weight)', unit: 'N', truth: '{id}.forceN', tolerance: 0.02 },
    ],
  },
  ramp: {
    place: 'bench', max: 1,
    params: [num('lengthM', 'Ramp length', 'm', 0.5, 2, 1, 0.1), num('frictionCoeff', 'Friction', '', 0, 0.3, 0.04, 0.01), num('trolleyMassKg', 'Trolley mass', 'kg', 0.1, 2, 0.5, 0.1)],
    actions: [
      { key: 'angle', label: 'Set the angle', intent: 'Rotate', value: { label: 'Ramp angle', unit: '°', min: 0, max: 40, step: 1, default: 10, spread: 0.5 }, until: 'between({id}.angleDeg, {lo}, {hi})', text: 'Raise the ramp to {v}°.' },
      { key: 'go', label: 'Let the trolley go', intent: 'Release', until: '{id}.atBottom', text: 'Release the trolley from the top and let it roll down.' },
      { key: 'reset', label: 'Back to the top', intent: 'Grab', until: '!{id}.atBottom && !{id}.running', text: 'Put the trolley back at the top.' },
    ],
    readings: [
      { key: 'time', label: 'Time to roll down', unit: 's', truth: '{id}.timeS', tolerance: 0.05 },
      { key: 'dist', label: 'Distance travelled', unit: 'm', truth: '{id}.distanceM', tolerance: 0.01 },
    ],
  },
  light_gate: {
    place: 'bench', max: 1, params: [],
    actions: [{ key: 'connect', label: 'Set up at…', intent: 'Connect', into: ['ramp'], until: '{id}.connected', text: 'Set up the light gate at the bottom of the ramp.' }],
    readings: [
      { key: 'speed', label: 'Speed through the gate', unit: 'm/s', truth: '{id}.reading', tolerance: 0.005 },
      { key: 'gate', label: 'Time to pass the gate (5 cm card)', unit: 's', truth: '{id}.gateTimeS', tolerance: 0.0005 },
    ],
  },
  metal_block: {
    place: 'bench', max: 4,
    params: [sel('material', 'Material', MATERIALS, 'aluminium'), num('volumeCm3', 'Volume', 'cm³', 1, 60, 20, 1)],
    actions: [place(['balance', 'measuring_cylinder', 'beaker'], 'Put the {label} on/in the {intoLabel}.')],
  },

  // ── Light ──
  light_box: { place: 'bench', max: 1, params: [], actions: [toggleOn('Switch on the light box.')] },
  convex_lens: {
    place: 'bench', max: 1,
    params: [num('focalLengthCm', 'Focal length', 'cm', 5, 50, 15, 1)],
    actions: [{ key: 'u', label: 'Move the object', intent: 'Rotate', value: { label: 'Object distance', unit: 'cm', min: 5, max: 100, step: 1, default: 30, spread: 0.5 }, until: 'between({id}.objectDistanceCm, {lo}, {hi})', text: 'Put the object {v} cm from the lens.' }],
  },
  screen: {
    place: 'bench', max: 1, params: [],
    actions: [
      { key: 'focus', label: 'Move until the image is sharp', intent: 'Rotate', until: '{id}.sharp', text: 'Move the screen until the image is sharp.' },
      { key: 'move', label: 'Move to a distance', intent: 'Rotate', value: { label: 'Screen distance', unit: 'cm', min: 5, max: 150, step: 0.5, default: 30, spread: 0.5 }, until: 'between({id}.distanceCm, {lo}, {hi})', text: 'Move the screen to {v} cm from the lens.' },
    ],
    readings: [
      { key: 'v', label: 'Image distance (lens to screen)', unit: 'cm', truth: '{id}.distanceCm', tolerance: 0.5 },
      { key: 'h', label: 'Image height', unit: 'cm', truth: '{id}.imageHeightCm', tolerance: 0.1 },
    ],
  },

  // ── Biology ──
  microscope: {
    place: 'scope', max: 1, params: [],
    actions: [
      { key: 'light', label: 'Switch on the light', intent: 'Toggle', until: '{id}.lightOn', text: 'Switch on the microscope light.' },
      { key: 'objective', label: 'Change objective', intent: 'Type', choices: ['4x', '10x', '40x', '100x'], until: '{id}.objective == {objNum}', text: 'Turn the nosepiece to the {v} objective.' },
      { key: 'focus', label: 'Focus until sharp', intent: 'Rotate', needsModel: 'mic', until: 'mic.focusQuality >= 0.8', text: 'Turn the fine focus knob until the image is sharp.' },
      { key: 'look', label: 'Look and observe', intent: 'Inspect', text: 'Look down the eyepiece and observe.' },
    ],
    readings: [{ key: 'mag', label: 'Total magnification', unit: '×', truth: 'mic.magnification', tolerance: 0, needsModel: 'mic' }],
  },
  slide: {
    place: 'prep', max: 3,
    params: [sel('specimen', 'Specimen', SPECIMENS, 'onion')],
    actions: [
      { key: 'stage', label: 'Place on the microscope', intent: 'Grab', into: ['microscope'], until: '{id}.onStage', text: 'Place the {label} slide on the microscope stage.' },
      { key: 'cover', label: 'Add a coverslip', intent: 'Select', until: '{id}.coverslip', text: 'Lower a coverslip onto the {label} slide.' },
      { key: 'look', label: 'Inspect', intent: 'Inspect', text: 'Look at the {label} slide.' },
    ],
  },
  stain: {
    place: 'shelf', max: 2,
    params: [sel('name', 'Stain', STAINS, 'iodine')],
    actions: [{ key: 'add', label: 'Add drops to…', intent: 'Pour', into: ['slide'], until: '{into}.stained', text: 'Add a drop of {label} to the {intoLabel} slide.' }],
  },
  potato_cylinder: {
    place: 'bench', max: 6,
    params: [num('massG', 'Starting mass', 'g', 0.5, 10, 2.5, 0.01), num('lengthMm', 'Starting length', 'mm', 10, 60, 30, 1)],
    actions: [place([...VESSELS, 'balance'], 'Put the {label} into the {intoLabel}.')],
    readings: [
      { key: 'mass', label: 'Mass (blot dry first)', unit: 'g', truth: '{id}.massG', tolerance: 0.02 },
      { key: 'len', label: 'Length', unit: 'mm', truth: '{id}.lengthMm', tolerance: 1 },
      { key: 'pct', label: 'Change in mass', unit: '%', truth: '{id}.changePct', tolerance: 1 },
    ],
  },
  pondweed: {
    place: 'bench', max: 2, params: [],
    actions: [place(['beaker', 'test_tube', 'measuring_cylinder'], 'Put the {label} in the {intoLabel} of water.'), { key: 'count', label: 'Start counting bubbles', intent: 'Select', text: 'Start counting the bubbles from the {label}.' }],
    readings: [
      { key: 'rate', label: 'Bubbles per minute', unit: 'bubbles/min', truth: '{id}.bubblesPerMin', tolerance: 2 },
      { key: 'count', label: 'Bubbles counted', unit: 'bubbles', truth: '{id}.bubbleCount', tolerance: 1 },
    ],
  },
  lamp: {
    place: 'bench', max: 1,
    params: [num('distanceCm', 'Starting distance', 'cm', 5, 60, 20, 1)],
    actions: [
      toggleOn('Switch on the lamp.'), toggleOff('Switch off the lamp.'),
      { key: 'move', label: 'Move the lamp', intent: 'Rotate', value: { label: 'Distance', unit: 'cm', min: 5, max: 60, step: 1, default: 20, spread: 0.5 }, until: 'between({id}.distanceCm, {lo}, {hi})', text: 'Move the lamp to {v} cm away.' },
    ],
    readings: [{ key: 'd', label: 'Lamp distance', unit: 'cm', truth: '{id}.distanceCm', tolerance: 0.5 }],
  },
  scalpel: { place: 'bench', max: 1, params: [], actions: [{ key: 'use', label: 'Cut', intent: 'Grab', text: 'Carefully cut with the scalpel, away from your fingers.' }] },
  forceps: { place: 'bench', max: 1, params: [], actions: [{ key: 'use', label: 'Pick up', intent: 'Grab', text: 'Use the forceps to pick up the sample.' }] },

  // ── Computing (unchanged) ──
  workstation: {
    place: 'desk', max: 2,
    params: [{ key: 'os', label: 'System', type: 'text', default: 'Python 3' }],
    actions: [{ key: 'cmd', label: 'Run a command / line of code', intent: 'Type', command: true, until: "{id}.lastCommand == {cmd}", text: 'Run: {v}' }],
  },
  firewall: {
    place: 'firewall', max: 1,
    params: [{ key: 'policy', label: 'Default policy', type: 'select', options: [{ value: 'deny', label: 'Deny all by default' }, { value: 'allow', label: 'Allow all by default' }], default: 'deny' }],
    actions: [{ key: 'cmd', label: 'Add a rule / command', intent: 'Type', command: true, until: "{id}.lastCommand == {cmd}", text: 'On the firewall, run: {v}' }],
    readings: [
      { key: 'blocked', label: 'Threats blocked', unit: '', truth: 'fw.blockedThreats', tolerance: 0, needsModel: 'fw' },
      { key: 'risky', label: 'Risky ports left open', unit: '', truth: 'fw.riskyAllowed', tolerance: 0, needsModel: 'fw' },
    ],
  },
  server_rack: { place: 'rack', max: 3, params: [], actions: [{ key: 'look', label: 'Inspect', intent: 'Inspect', text: 'Inspect the {label}.' }] },
  network_switch: {
    place: 'switch', max: 1, params: [num('ports', 'Ports', '', 4, 48, 8, 4)],
    actions: [{ key: 'look', label: 'Inspect the ports', intent: 'Inspect', text: 'Inspect the switch ports.' }],
  },
  patch_cable: {
    place: 'shelf', max: 6,
    params: [sel('color', 'Colour', ['blue', 'yellow', 'green', 'red', 'grey'].map((c) => ({ value: c, label: c })), 'blue')],
    actions: [{ key: 'connect', label: 'Plug into…', intent: 'Connect', into: ['network_switch', 'server_rack'], until: '{id}.connected', text: 'Plug the {label} into the {intoLabel}.' }],
  },
  wall_display: { place: 'wall', max: 1, params: [], actions: [{ key: 'look', label: 'Look at the output', intent: 'Inspect', text: 'Look at the output on the big screen.' }] },
};

const bench = (...ids) => ids.flatMap((b) => [`${b}.center`, `${b}.left`, `${b}.right`]);

/** Which items each room offers, and where each "place" goes. */
const ROOMS = {
  ChemLab: {
    items: ['goggles', 'labcoat', 'gloves', 'reagent_bottle', 'solid_jar', 'dropper_bottle', 'indicator', 'beaker', 'test_tube', 'conical_flask', 'measuring_cylinder', 'evaporating_dish',
      'burette', 'pipette', 'funnel', 'white_tile', 'retort_stand', 'bunsen_burner', 'hot_plate', 'water_bath', 'thermometer', 'ph_meter', 'balance', 'stopwatch', 'splint', 'delivery_tube'],
    places: { bench: [...bench('benchA', 'benchB', 'benchC'), 'fumehood.center'], shelf: ['shelf.1', 'shelf.2', 'shelf.3'] },
    tips: [
      'Real chemists always wear goggles and a lab coat — add them and make putting them on your first steps.',
      'Every container really reacts: try metals or marble chips in acid, precipitation tests, indicators, neutralisation (measure the temperature rise!) and thiosulfate + acid timing.',
      'Test the gas: a lit splint pops with hydrogen, a glowing splint relights in oxygen, and carbon dioxide turns limewater milky (use a delivery tube).',
      'For a titration: acid in the conical flask, alkali in the burette, an indicator and a white tile. Rinse the burette first.',
    ],
  },
  PhysicsLab: {
    items: ['goggles', 'power_supply', 'battery', 'switch', 'breadboard', 'resistor', 'variable_resistor', 'bulb', 'led', 'ammeter', 'voltmeter',
      'pendulum', 'stopwatch', 'metre_rule', 'spring', 'ramp', 'light_gate', 'metal_block', 'balance', 'measuring_cylinder', 'beaker', 'hot_plate', 'thermometer',
      'light_box', 'convex_lens', 'screen'],
    places: { bench: [...bench('benchA', 'benchB', 'benchC'), 'optics.rail'], shelf: ['shelf.1', 'shelf.2'] },
    tips: [
      'Circuits: choose series or parallel on the circuit board. Put the ammeter in series and the voltmeter across the components, then switch on.',
      'A filament bulb is not ohmic — plot current against voltage and see. An LED needs a resistor in series.',
      'Forces: hang masses on a spring (Hooke\'s law), roll a trolley down a ramp through a light gate, or find densities with a balance and a measuring cylinder.',
      'Light: move the object and the screen until the image is sharp, then check 1/f = 1/u + 1/v.',
      'Heating: a hot plate shows the energy supplied — with a balance and thermometer you can find the specific heat capacity of water.',
    ],
  },
  BioLab: {
    items: ['gloves', 'labcoat', 'goggles', 'microscope', 'slide', 'stain', 'test_tube', 'beaker', 'measuring_cylinder', 'dropper_bottle', 'solid_jar',
      'water_bath', 'hot_plate', 'thermometer', 'ph_meter', 'balance', 'stopwatch', 'potato_cylinder', 'pondweed', 'lamp', 'scalpel', 'forceps', 'splint', 'delivery_tube'],
    places: { bench: bench('benchA', 'benchB'), shelf: ['shelf.1', 'shelf.2'], scope: ['scope.station'], prep: ['prep.station', 'benchA.left', 'benchA.right'] },
    tips: [
      'Food tests: iodine (starch → blue-black), Benedict\'s + a hot water bath (sugar → brick red), biuret (protein → purple), ethanol then water (fat → cloudy white).',
      'Enzymes: amylase + starch with iodine in a water bath — time how long until the blue-black colour goes. Try different temperatures.',
      'Osmosis: potato cylinders in sugar solutions of different strengths — weigh them before and after.',
      'Photosynthesis: pondweed in hydrogencarbonate solution — count bubbles with the lamp at different distances.',
      'Microscopes: stain the specimen, add a coverslip, then start at the lowest objective.',
    ],
  },
  CyberSOC: {
    items: ['workstation', 'firewall', 'wall_display'],
    places: { desk: ['desk.main', 'desk.right'], firewall: ['desk.left', 'rack.1'], wall: ['wall.screen'] },
    tips: ['Each "command" you add becomes a button on the computer. Write them in the order an analyst would run them.', 'Firewall rules look like "deny port 23" or "allow port 443", then "apply".'],
  },
  ServerRoom: {
    items: ['server_rack', 'network_switch', 'patch_cable', 'workstation'],
    places: { rack: ['rack.1', 'rack.2', 'rack.3'], switch: ['patch.panel'], shelf: ['shelf.1'], desk: ['desk.main'] },
    tips: ['Plug cables into the switch, then test the network from the computer with commands like "ping 192.168.1.1".'],
  },
  CodingBench: {
    items: ['workstation', 'wall_display'],
    places: { desk: ['desk.main', 'desk.left', 'desk.right'], wall: ['wall.screen'] },
    tips: ['Each line of code you add becomes a button. Use the "output" box to show what your program prints.', 'Finish with a question that checks you understand what your program does.'],
  },
};

const MAX_STEPS = 30;
const MAX_PROJECTS = 30;

/** Kit for the app: per room, the items with settings, actions and readings. */
function builderKit() {
  const rooms = {};
  for (const [env, room] of Object.entries(ROOMS)) {
    rooms[env] = {
      title: catalog.environments[env].title,
      subject: ENV_TO_SUBJECT[env],
      tips: room.tips,
      items: room.items.map((type) => {
        const k = KIT[type];
        return {
          type,
          title: catalog.equipment[type].title,
          category: catalog.equipment[type].category,
          max: Math.min(k.max, capacity(env, k.place, type)),
          params: k.params,
          actions: k.actions.map(({ until, ...a }) => a),
          readings: (k.readings || []).map(({ truth, ...r }) => r),
        };
      }),
    };
  }
  return { rooms, limits: { steps: MAX_STEPS, projects: MAX_PROJECTS }, calcOps: ['+', '-', '*', '/'] };
}

const SMALL_PER_SLOT = 4;
const isSmall = (type) => !!(catalog.equipment[type] && catalog.equipment[type].small);

function capacity(env, place, type) {
  if (place === 'ppe') return 3;
  if (place === 'shelf') return 6;
  const slots = (ROOMS[env].places[place] || []).length;
  return isSmall(type) ? slots * SMALL_PER_SLOT : slots;
}

// ─── Compile ──────────────────────────────────────────────────────────────────

class ProjectError extends Error {
  constructor(errors) { super(errors[0]); this.errors = errors; }
}

const str = (v, max) => String(v == null ? '' : v).trim().slice(0, max);
const isNum = (v) => typeof v === 'number' && Number.isFinite(v);

/** A literal for the expression language (it has no escapes). */
function quote(text) {
  if (!text.includes("'")) return `'${text}'`;
  if (!text.includes('"')) return `"${text}"`;
  throw new ProjectError([`A command cannot contain both ' and " quotes: ${text}`]);
}

function assignSlots(env, equipment, errors) {
  const room = ROOMS[env];
  const used = new Map(); // slot → item types placed there
  let shelfIdx = 0;
  // Large items first so they get whole slots; small ones then share.
  const order = [...equipment].sort((x, y) => Number(isSmall(x.type)) - Number(isSmall(y.type)));
  for (const eq of order) {
    const place = KIT[eq.type].place;
    if (place === 'ppe') { eq.slot = 'ppe.rack'; continue; }
    if (place === 'shelf' && room.places.shelf) {
      eq.slot = room.places.shelf[shelfIdx++ % room.places.shelf.length];
      continue;
    }
    const options = [...(room.places[place] || []), ...(place !== 'bench' && room.places.bench ? room.places.bench : [])];
    const small = isSmall(eq.type);
    const fits = (slot) => {
      const here = used.get(slot) || [];
      if (!here.length) return true;
      return small && here.length < SMALL_PER_SLOT && here.every(isSmall);
    };
    // Small items prefer a slot that already has small items (keeps benches tidy).
    const free = (small && options.find((sl) => (used.get(sl) || []).length && fits(sl))) || options.find(fits);
    if (!free) { errors.push(`There is no room left in the ${catalog.environments[env].title} for the ${eq.label || catalog.equipment[eq.type].title}. Remove an item.`); continue; }
    used.set(free, [...(used.get(free) || []), eq.type]);
    eq.slot = free;
  }
}

function autoVariables(equipment) {
  const first = (type) => equipment.find((e) => e.type === type);
  const vars = {};
  const flask = first('conical_flask');
  const burette = first('burette');
  if (flask && burette && sim.ACIDS[flask.init.solution] && sim.BASES[burette.init.solution]) {
    const ind = first('indicator');
    vars.titr = { model: 'chem.titration', inputs: { flask: flask.id, burette: burette.id }, params: ind && ind.init.name ? { indicator: ind.init.name } : {} };
  }
  const board = first('breadboard');
  if (board) vars.circ = { model: 'phys.circuit', inputs: { circuit: board.id }, params: { internalOhm: 0 } };
  const pend = first('pendulum');
  if (pend) vars.pm = { model: 'phys.pendulum', inputs: { pendulum: pend.id }, params: {} };
  const scope = first('microscope');
  if (scope) vars.mic = { model: 'bio.microscope', inputs: { microscope: scope.id }, params: { idealFocus: 0.62 } };
  const fw = first('firewall');
  if (fw) vars.fw = { model: 'net.firewall', inputs: { firewall: fw.id }, params: {} };
  return vars;
}

function autoHazards(equipment, vars) {
  const of = (type) => equipment.filter((e) => e.type === type);
  const hazards = [];
  const goggles = of('goggles')[0];
  // Only reagent bottles track "poured"; beakers and pipettes are filled from them.
  const liquids = of('reagent_bottle').filter((e) => e.init.solution && e.init.solution !== 'water');
  if (goggles && liquids.length) {
    hazards.push({ id: 'noGoggles', when: `!${goggles.id}.worn && (${liquids.map((l) => `${l.id}.poured`).join(' || ')})`, message: 'Stop! You are pouring chemicals without your goggles on.', severity: 'warn', penalty: 15 });
  }
  const gloves = of('gloves')[0];
  const stains = of('stain');
  if (gloves && stains.length) {
    hazards.push({ id: 'noGloves', when: `!${gloves.id}.worn && (${stains.map((s) => `${s.id}.dropsAdded > 0`).join(' || ')})`, message: 'Stains mark your skin — put your gloves on first.', severity: 'warn', penalty: 10 });
  }
  const burner = of('bunsen_burner')[0];
  if (burner && goggles) hazards.push({ id: 'flameNoGoggles', when: `${burner.id}.lit && !${goggles.id}.worn`, message: 'Never light a Bunsen burner without goggles.', severity: 'warn', penalty: 10 });
  const board = of('breadboard')[0];
  if (board) hazards.push({ id: 'short', when: `${board.id}.shortCircuit`, message: 'Short circuit! The ammeter must be in series with a resistor. Switch off and reconnect.', severity: 'warn', penalty: 15 });
  if (vars.titr) hazards.push({ id: 'overshoot', when: 'titr.pH > 11.5', message: 'You went past the end point. Next time slow down to single drops near the end.', severity: 'warn', penalty: 5 });
  return hazards;
}

function fill(template, ctx) {
  return template.replace(/\{(\w+)\}/g, (m, k) => (ctx[k] != null ? String(ctx[k]) : m));
}

/**
 * Turns a project spec into a validated scenario.
 * spec: { title, environment, aim, hypothesis, conclusion, durationMin,
 *         equipment: [{ id, type, label, init }],
 *         steps: [{ kind:'action', target, action, into, value, count, command, output, instruction, hint }
 *                 | { kind:'measure', instruction, label, unit, reading:{ item, key } | truth, tolerance }
 *                 | { kind:'calc', instruction, label, unit, a, op, b, tolerance }
 *                 | { kind:'info', instruction }
 *                 | { kind:'checkpoint', prompt, choices, answerIndex, explanation }] }
 * @returns {{ ok, scenario?, errors }}
 */
function compileProject(spec, { slug } = {}) {
  try {
    return { ok: true, ...compile(spec, slug) };
  } catch (e) {
    if (e instanceof ProjectError) return { ok: false, errors: e.errors };
    throw e;
  }
}

function compile(spec, slug) {
  const errors = [];
  if (!spec || typeof spec !== 'object') throw new ProjectError(['Nothing to save']);
  const env = String(spec.environment || '');
  if (!ROOMS[env]) throw new ProjectError(['Choose a lab room']);
  const room = ROOMS[env];
  const title = str(spec.title, 120);
  if (title.length < 3) errors.push('Give your experiment a title');
  const aim = str(spec.aim, 400);
  const hypothesis = str(spec.hypothesis, 400);

  // Equipment
  const rawEq = Array.isArray(spec.equipment) ? spec.equipment.slice(0, 40) : [];
  if (!rawEq.length) errors.push('Add at least one piece of equipment');
  const equipment = [];
  const counts = {};
  for (const e of rawEq) {
    const type = String(e && e.type || '');
    if (!room.items.includes(type)) { errors.push(`"${type}" is not available in the ${catalog.environments[env].title}`); continue; }
    counts[type] = (counts[type] || 0) + 1;
    if (counts[type] > KIT[type].max) { errors.push(`You can use at most ${KIT[type].max} × ${catalog.equipment[type].title}`); continue; }
    const id = /^[A-Za-z][A-Za-z0-9_]{0,39}$/.test(String(e.id || '')) ? String(e.id) : `${type.replace(/_/g, '')}${counts[type]}`;
    if (equipment.some((x) => x.id === id)) { errors.push(`Two items share the id "${id}"`); continue; }
    const init = {};
    for (const p of KIT[type].params) {
      let v = e.init && e.init[p.key] !== undefined ? e.init[p.key] : p.default;
      if (p.type === 'number') {
        v = Number(v);
        if (!Number.isFinite(v)) v = p.default;
        v = Math.min(Math.max(v, p.min), p.max);
      } else if (p.type === 'select') {
        const match = p.options.find((o) => String(o.value) === String(v));
        v = match ? match.value : p.default;
      } else v = str(v, 60) || p.default;
      init[p.key] = v;
    }
    const item = { id, type, label: str(e.label, 60) || undefined, init };
    if (!item.label) delete item.label;
    equipment.push(item);
  }
  assignSlots(env, equipment, errors);
  const byId = new Map(equipment.map((e) => [e.id, e]));
  const labelOf = (e) => e.label || catalog.equipment[e.type].title.replace(/\s*\(.*\)$/, '');
  const variables = autoVariables(equipment);

  // Steps
  const rawSteps = Array.isArray(spec.steps) ? spec.steps : [];
  if (!rawSteps.length) errors.push('Add at least one step to your procedure');
  if (rawSteps.length > MAX_STEPS) errors.push(`Use at most ${MAX_STEPS} steps`);
  const steps = [];
  const recordKeys = new Set();
  const commands = new Map(); // terminal id → commands (in order)
  rawSteps.slice(0, MAX_STEPS).forEach((s, i) => {
    const n = i + 1;
    const where = `Step ${n}`;
    const id = `s${n}`;
    const instruction = str(s && s.instruction, 400);
    const hint = str(s && s.hint, 300);
    const base = { id, instruction, hints: hint ? [hint] : [], points: 10 };
    const kind = s && s.kind;

    if (kind === 'info') {
      if (!instruction) errors.push(`${where}: write what to observe or note`);
      steps.push({ ...base, kind: 'info', title: 'Observe', points: 5 });
      return;
    }

    if (kind === 'checkpoint') {
      const choices = (Array.isArray(s.choices) ? s.choices : []).map((c) => str(c, 200)).filter(Boolean).slice(0, 6);
      const prompt = str(s.prompt, 400);
      const answerIndex = Number(s.answerIndex);
      if (!prompt) errors.push(`${where}: write the question`);
      if (choices.length < 2) errors.push(`${where}: a question needs at least 2 answers`);
      if (!(answerIndex >= 0 && answerIndex < choices.length)) errors.push(`${where}: choose the correct answer`);
      const question = { prompt: prompt || '?', choices: choices.length >= 2 ? choices : ['A', 'B'], answerIndex: answerIndex >= 0 && answerIndex < choices.length ? answerIndex : 0 };
      const explanation = str(s.explanation, 600);
      if (explanation) question.explanation = explanation;
      steps.push({ ...base, kind: 'checkpoint', title: 'Think about it', instruction: instruction || 'Answer the question.', checkpoint: { question } });
      return;
    }

    if (kind === 'measure' || kind === 'calc') {
      const label = str(s.label, 120);
      const unit = str(s.unit, 20);
      let truth;
      let tolerance = Number(s.tolerance);
      if (kind === 'calc') {
        const operand = (x, side) => {
          if (isNum(x)) return String(x);
          if (typeof x === 'string' && /^-?\d+(\.\d+)?$/.test(x.trim())) return x.trim();
          if (typeof x === 'string' && recordKeys.has(x)) return `record.${x}`;
          errors.push(`${where}: choose the ${side} value of the calculation (a reading from an earlier step or a number)`);
          return '1';
        };
        if (!['+', '-', '*', '/'].includes(s.op)) errors.push(`${where}: choose + − × or ÷`);
        truth = `${operand(s.a, 'first')} ${['+', '-', '*', '/'].includes(s.op) ? s.op : '*'} ${operand(s.b, 'second')}`;
        if (!Number.isFinite(tolerance)) tolerance = 0.1;
      } else if (s.reading && s.reading.item) {
        const item = byId.get(String(s.reading.item));
        const r = item && (KIT[item.type].readings || []).find((x) => x.key === s.reading.key);
        if (!r) { errors.push(`${where}: choose what to read`); truth = '0'; } else {
          if (r.needsModel && !variables[r.needsModel]) errors.push(`${where}: this reading needs a working ${r.needsModel === 'mic' ? 'microscope' : 'firewall'}`);
          truth = fill(r.truth, { id: item.id });
          if (!Number.isFinite(tolerance)) tolerance = r.tolerance;
        }
      } else if (typeof s.truth === 'string' && s.truth.trim()) {
        truth = s.truth.trim().slice(0, 400); // AI drafts and advanced edits; checked by the validator
        if (!Number.isFinite(tolerance)) tolerance = 0.05;
      } else { errors.push(`${where}: choose what to read`); truth = '0'; }
      if (!label) errors.push(`${where}: name the value you record (e.g. "Current")`);
      let key = String(s.key || '').match(/^[A-Za-z][A-Za-z0-9_]{0,39}$/) ? s.key : `r${n}`;
      if (recordKeys.has(key)) key = `r${n}`;
      recordKeys.add(key);
      steps.push({
        ...base, kind: 'measure', title: kind === 'calc' ? 'Calculate' : 'Take a reading',
        instruction: instruction || (kind === 'calc' ? `Calculate the ${label}.` : `Read and record the ${label}.`),
        record: { key, label: label || 'Value', unit, truth, tolerance: Math.max(0, Math.min(tolerance, 1e6)) },
      });
      return;
    }

    if (kind !== 'action') { errors.push(`${where}: unknown kind of step`); return; }
    const target = byId.get(String(s.target || ''));
    if (!target) { errors.push(`${where}: choose the equipment to use`); return; }
    const kit = KIT[target.type];
    // AI drafts may carry a raw intent + until instead of a kit action.
    const action = kit.actions.find((a) => a.key === s.action) || (s.intent && { key: 'raw', intent: String(s.intent), until: typeof s.until === 'string' ? s.until : undefined, text: '' });
    if (!action) { errors.push(`${where}: choose what to do with the ${labelOf(target)}`); return; }
    const step = { ...base, kind: 'action', title: str(s.title, 80) || (action.label ? action.label.replace(/…$/, '').slice(0, 80) : 'Do it'), focus: target.id, expect: { intent: action.intent, target: target.id } };
    const ctx = { id: target.id, label: labelOf(target) };

    if (action.into || s.into) {
      const into = byId.get(String(s.into || ''));
      if (!into || (action.into && !action.into.includes(into.type))) { errors.push(`${where}: choose where the ${labelOf(target)} goes`); return; }
      step.expect.into = into.id;
      ctx.into = into.id;
      ctx.intoQ = `'${into.id}'`;
      ctx.intoLabel = labelOf(into);
    }
    if (action.value) {
      const max = action.value.maxFrom ? Number(target.init[action.value.maxFrom]) : action.value.max;
      let v = Number(s.value);
      if (!Number.isFinite(v)) v = action.value.default;
      if (v < action.value.min || v > max) { errors.push(`${where}: choose a value between ${action.value.min} and ${max} ${action.value.unit}`); v = Math.min(Math.max(v, action.value.min), max); }
      const lo = Math.round((v - action.value.spread) * 1000) / 1000;
      const hi = Math.round((v + action.value.spread) * 1000) / 1000;
      step.expect.value = { min: lo, max: hi };
      Object.assign(ctx, { v, lo, hi });
    } else if (s.value && typeof s.value === 'object' && isNum(s.value.min) && isNum(s.value.max)) {
      step.expect.value = { min: s.value.min, max: s.value.max };
    }
    if (action.count) {
      const c = Math.round(Number(s.count));
      const nCount = Number.isFinite(c) ? Math.min(Math.max(c, action.count.min), action.count.max) : action.count.default;
      const pend = equipment.find((e) => e.type === action.needsType);
      if (!pend) { errors.push(`${where}: add a pendulum to time its swings`); return; }
      Object.assign(ctx, { n: nCount, pend: pend.id });
    }
    if (action.needsModel && !variables[action.needsModel]) {
      errors.push(`${where}: "${action.label}" needs ${action.needsModel === 'titr' ? 'an acid in the conical flask and an alkali in the burette' : 'the right equipment'}`);
      return;
    }
    if (action.choices) {
      const v = action.choices.includes(s.command) ? s.command : action.choices[0];
      ctx.v = v;
      ctx.objNum = parseFloat(v);
      commands.set(target.id, [...(commands.get(target.id) || []), v]);
      step.expect = { intent: 'Type', target: target.id };
    }
    if (action.command) {
      const cmd = str(s.command, 80);
      if (!cmd) { errors.push(`${where}: write the command or line of code`); return; }
      ctx.v = cmd;
      ctx.cmd = quote(cmd);
      const list = commands.get(target.id) || [];
      if (!list.includes(cmd)) list.push(cmd);
      commands.set(target.id, list);
      const output = str(s.output, 400);
      if (output) step.success = output;
    }
    if (action.until) step.until = fill(action.until, ctx);
    step.instruction = instruction || fill(action.text || '', ctx) || `Use the ${labelOf(target)}.`;
    steps.push(step);
  });

  // Terminals and microscope show the commands used in the procedure as buttons.
  for (const [id, list] of commands) {
    const eq = byId.get(id);
    eq.init.commands = [...new Set([...(eq.init.commands || []), ...list])].slice(0, 20);
  }
  for (const eq of equipment) {
    if (eq.type === 'microscope' && !eq.init.commands) eq.init.commands = ['4x', '10x', '40x'];
    if ((eq.type === 'workstation' || eq.type === 'firewall') && !eq.init.commands) eq.init.commands = ['help'];
  }

  if (errors.length) throw new ProjectError(errors);

  const hazards = autoHazards(equipment, variables);
  const subject = ENV_TO_SUBJECT[env];
  const scenario = {
    id: slug || `my-${slugify(title).slice(0, 50)}`,
    version: 1,
    title,
    summary: str([aim && `Aim: ${aim}`, hypothesis && `Hypothesis: ${hypothesis}`].filter(Boolean).join(' · ') || `My own experiment in the ${catalog.environments[env].title}.`, 600),
    subject,
    level: 'secondary',
    environment: env,
    difficulty: Math.min(5, Math.max(1, Math.ceil(steps.length / 5))),
    tags: ['my experiment'],
    durationMin: Math.min(120, Math.max(5, Math.round(Number(spec.durationMin) || steps.length * 2))),
    objectives: [aim || `Investigate: ${title}`].map((o) => o.slice(0, 200)),
    equipment,
    variables,
    steps,
    hazards,
    results: [],
    scoring: hazards.length ? { accuracy: 0, procedure: 80, safety: 20 } : { accuracy: 0, procedure: 100, safety: 0 },
    passScore: 60,
    xp: 0,
  };
  const result = validateScenario(scenario);
  if (!result.ok) throw new ProjectError(result.errors);
  return { scenario: result.value, errors: [] };
}

/**
 * The reverse: an AI-generated or published scenario as an editable project spec
 * (used for "Build it with AI" and "Remix this lab").
 */
function specFromScenario(def) {
  const kitAction = (eqType, step) => {
    const kit = KIT[eqType];
    if (!kit || !step.expect) return null;
    return kit.actions.find((a) => a.intent === step.expect.intent && (!a.into || (step.expect.into != null)) && !a.command && !a.choices && !a.count) || null;
  };
  const byId = new Map((def.equipment || []).map((e) => [e.id, e]));
  // Model variables get fixed names in projects (see autoVariables); rename them in raw expressions.
  const VAR_NAME = { 'chem.titration': 'titr', 'phys.circuit': 'circ', 'phys.pendulum': 'pm', 'bio.microscope': 'mic', 'net.firewall': 'fw' };
  const renames = Object.entries(def.variables || {}).filter(([n, v]) => VAR_NAME[v.model] && VAR_NAME[v.model] !== n).map(([n, v]) => [new RegExp(`\\b${n}\\.`, 'g'), `${VAR_NAME[v.model]}.`]);
  const rx = (e) => (typeof e === 'string' ? renames.reduce((acc, [re, to]) => acc.replace(re, to), e) : e);
  const steps = (def.steps || []).map((s0) => {
    const s = { ...s0, until: rx(s0.until), record: s0.record && { ...s0.record, truth: rx(s0.record.truth) } };
    if (s.kind === 'info') return { kind: 'info', instruction: s.instruction };
    if (s.kind === 'checkpoint' && s.checkpoint && s.checkpoint.question) {
      const q = s.checkpoint.question;
      return { kind: 'checkpoint', prompt: q.prompt, choices: q.choices, answerIndex: q.answerIndex, explanation: q.explanation };
    }
    if (s.kind === 'measure' && s.record) {
      return { kind: 'measure', key: s.record.key, instruction: s.instruction, label: s.record.label, unit: s.record.unit, truth: s.record.truth, tolerance: s.record.tolerance, hint: (s.hints || [])[0] };
    }
    const target = s.expect && byId.get(s.expect.target);
    if (!target) return { kind: 'info', instruction: s.instruction };
    // Commands typed on a terminal: recover the command from "lastCommand == '...'".
    const m = typeof s.until === 'string' && s.until.match(/lastCommand\s*==\s*(['"])(.*?)\1/);
    if (s.expect.intent === 'Type' && m && ['workstation', 'firewall'].includes(target.type)) {
      return { kind: 'action', target: target.id, action: 'cmd', command: m[2], output: s.success || s.say, instruction: s.instruction, hint: (s.hints || [])[0] };
    }
    const a = kitAction(target.type, s);
    const out = { kind: 'action', target: target.id, instruction: s.instruction, hint: (s.hints || [])[0], into: s.expect.into };
    if (a && !s.until) return { ...out, action: a.key, value: s.expect.value ? (s.expect.value.min + s.expect.value.max) / 2 : undefined };
    return { ...out, intent: s.expect.intent, until: s.until, value: s.expect.value };
  });
  const aim = (def.objectives || [])[0] || '';
  return {
    title: def.title,
    environment: def.environment,
    aim,
    hypothesis: '',
    durationMin: def.durationMin,
    equipment: (def.equipment || []).filter((e) => KIT[e.type]).map((e) => ({ id: e.id, type: e.type, label: e.label || e.labelTemplate, init: Object.fromEntries(Object.entries(e.init || {}).filter(([k]) => k !== 'commands' && k !== 'objectives')) })),
    steps,
  };
}

module.exports = { builderKit, compileProject, specFromScenario, KIT, ROOMS, MAX_PROJECTS, MAX_STEPS };
