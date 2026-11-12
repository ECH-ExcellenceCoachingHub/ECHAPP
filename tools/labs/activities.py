#!/usr/bin/env python3
"""
ECH Labs activity library — every built-in lab activity, from Beginner (1) to Expert (5).

    python tools/labs/activities.py      # writes backend/src/services/labs/scenarios/*.json

The backend validator (services/labs/validator.js) checks every file: rooms, slots, equipment
intents, expressions, step order and the science (titration end points are recomputed).
Hints get fewer as difficulty rises: beginners are guided, experts work exam-style.
"""
import json
import os

OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'backend', 'src', 'services', 'labs', 'scenarios')
VERSION = 2  # bump when built-in activities change (seeded databases pick it up)


# ─── Step helpers ─────────────────────────────────────────────────────────────

def act(id, title, instruction, intent, target, into=None, until=None, value=None, hints=(), say=None, focus=None, points=10):
    s = {'id': id, 'kind': 'action', 'title': title, 'instruction': instruction,
         'expect': {'intent': intent, 'target': target}, 'focus': focus or target, 'points': points, 'hints': list(hints)}
    if into: s['expect']['into'] = into
    if value: s['expect']['value'] = {'min': value[0], 'max': value[1]}
    if until: s['until'] = until
    if say: s['say'] = say
    return s


def cmd(id, title, instruction, target, command, hints=(), say=None, points=10):
    """Terminal step: completes when the student runs `command` on `target`."""
    return act(id, title, instruction, 'Type', target, until=f"{target}.lastCommand == '{command}'", hints=hints, say=say, points=points)


def measure(id, title, instruction, key, label, unit, truth, tolerance, hints=(), say=None, focus=None, points=10):
    s = {'id': id, 'kind': 'measure', 'title': title, 'instruction': instruction,
         'record': {'key': key, 'label': label, 'unit': unit, 'truth': truth, 'tolerance': tolerance},
         'points': points, 'hints': list(hints)}
    if focus: s['focus'] = focus
    if say: s['say'] = say
    return s


def quiz(id, prompt, choices, answer, explanation, points=10):
    return {'id': id, 'kind': 'checkpoint', 'title': 'Check your understanding', 'instruction': 'Answer the question.',
            'checkpoint': {'question': {'prompt': prompt, 'choices': choices, 'answerIndex': answer, 'explanation': explanation}},
            'points': points, 'hints': []}


def ppe(*items, hints=True):
    names = {'goggles1': 'safety goggles', 'coat1': 'lab coat', 'gloves1': 'gloves'}
    steps = []
    for i, eid in enumerate(items):
        steps.append(act(f'ppe{i + 1}', 'Safety first', f'Put on your {names[eid]}.', 'Grab', eid,
                         hints=['Select it on the PPE station and choose "Put on".'] if hints else [], points=5))
    return steps


PPE_EQ = {
    'goggles1': {'id': 'goggles1', 'type': 'goggles', 'slot': 'ppe.rack'},
    'coat1': {'id': 'coat1', 'type': 'labcoat', 'slot': 'ppe.rack'},
    'gloves1': {'id': 'gloves1', 'type': 'gloves', 'slot': 'ppe.rack'},
}


def lab(id, title, summary, subject, environment, difficulty, objectives, equipment, steps, *, variables=None,
        hazards=None, results=None, scoring=None, xp=None, duration=None, tags=(), level='secondary'):
    if scoring is None:
        scoring = {'accuracy': 40, 'procedure': 40, 'safety': 20} if results else {'accuracy': 0, 'procedure': 80, 'safety': 20}
    return {
        'id': id, 'version': VERSION, 'title': title, 'summary': summary, 'subject': subject, 'level': level,
        'environment': environment, 'difficulty': difficulty, 'tags': list(tags),
        'durationMin': duration or (5 + difficulty * 5), 'objectives': objectives,
        'equipment': equipment, 'variables': variables or {}, 'steps': steps,
        'hazards': hazards or [], 'results': results or [], 'scoring': scoring,
        'passScore': 60, 'xp': xp or (40 + difficulty * 30),
    }


NO_GOGGLES = lambda after: {'id': 'noGoggles', 'when': f"!goggles1.worn && {after}", 'message': 'Stop! Put on your safety goggles before handling chemicals.', 'severity': 'warn', 'penalty': 15}

LABS = []

# ═════════════════════════════════════ CHEMISTRY ═════════════════════════════

LABS.append(lab(
    'chem-safety-induction', 'Lab Safety Induction', 'Your first visit to the ECH chemistry lab: find the safety equipment, put on your PPE and learn the rules that keep everyone safe.',
    'chemistry', 'ChemLab', 1,
    ['Put on goggles, lab coat and gloves correctly', 'Know the hazard symbols on chemical bottles', 'Know what to do in an emergency'],
    [PPE_EQ['goggles1'], PPE_EQ['coat1'], PPE_EQ['gloves1'],
     {'id': 'acid', 'type': 'reagent_bottle', 'slot': 'shelf.1', 'label': 'HCl — CORROSIVE', 'init': {'solution': 'HCl', 'conc': 1, 'volume': 500}}],
    ppe('goggles1', 'coat1', 'gloves1') + [
        act('inspect', 'Read the label', 'Look closely at the acid bottle and read its hazard label.', 'Inspect', 'acid',
            hints=['Select the bottle on the shelf and choose "Look closer".', 'Corrosive means it can burn skin and eyes.'],
            say='Always read the label before you pick up any chemical.'),
        quiz('q1', 'What does the CORROSIVE symbol warn you about?', ['It can burn skin and eyes', 'It is flammable', 'It is radioactive', 'It is safe to touch'], 0, 'Corrosive substances destroy living tissue on contact, so wear goggles and gloves.'),
        quiz('q2', 'Acid splashes into your eye. What should you do FIRST?', ['Rinse with running water for at least 10 minutes and tell the teacher', 'Rub your eye', 'Wait to see if it hurts', 'Add an alkali to neutralise it'], 0, 'Flush immediately with lots of water (eyewash station) and report it. Never try to neutralise chemicals in an eye.'),
        quiz('q3', 'Where should you eat your snack?', ['Outside the laboratory', 'At your bench if you are careful', 'Inside the fume hood', 'Next to the sink'], 0, 'Never eat or drink in a laboratory: food can be contaminated by chemicals.'),
    ], tags=['safety', 'start here'], xp=60, duration=8))

LABS.append(lab(
    'chem-glassware-tour', 'Know Your Glassware', 'Meet the glassware chemists use every day — burette, pipette, conical flask and beaker — and learn which one to use for accurate measurements.',
    'chemistry', 'ChemLab', 1,
    ['Name common laboratory glassware', 'Choose accurate vs. approximate glassware'],
    [{'id': 'burette1', 'type': 'burette', 'slot': 'benchA.center', 'init': {'solution': 'NaOH', 'conc': 0.1, 'volume': 50}},
     {'id': 'pipette1', 'type': 'pipette', 'slot': 'benchA.right', 'init': {'solution': 'HCl', 'conc': 0.1, 'volume': 25}},
     {'id': 'flask1', 'type': 'conical_flask', 'slot': 'benchB.left', 'init': {'solution': 'HCl', 'conc': 0.1, 'volume': 0}},
     {'id': 'beaker1', 'type': 'beaker', 'slot': 'benchB.center', 'init': {'solution': 'HCl', 'conc': 0.1, 'volume': 100}}],
    [act('see_burette', 'The burette', 'Look closely at the burette. Notice the scale reads from 0.00 at the TOP down to 50.00.', 'Inspect', 'burette1',
         hints=['Select the tall tube on the stand and choose "Read the scale".'], say='A burette delivers a variable, accurately measured volume.'),
     act('see_pipette', 'The pipette', 'Inspect the volumetric pipette.', 'Inspect', 'pipette1', hints=['It is the long thin tube with a bulb in the middle.']),
     act('see_flask', 'The conical flask', 'Inspect the conical flask.', 'Inspect', 'flask1', hints=['Its sloping sides let you swirl without spilling.']),
     act('see_beaker', 'The beaker', 'Inspect the beaker.', 'Inspect', 'beaker1', hints=['Beaker markings are only approximate.']),
     quiz('q1', 'Which glassware measures exactly 25.0 cm³ of a solution?', ['Volumetric pipette', 'Beaker', 'Conical flask', 'Funnel'], 0, 'A volumetric pipette is calibrated to deliver one exact volume.'),
     quiz('q2', 'Why do we titrate into a conical flask rather than a beaker?', ['It can be swirled without splashing', 'It holds more', 'It is cheaper', 'It is easier to clean'], 0, 'The narrow neck and sloped sides keep the liquid inside while you swirl.'),
     ], tags=['equipment'], xp=60, duration=8))

LABS.append(lab(
    'chem-bunsen-burner', 'Lighting a Bunsen Burner Safely', 'Light a Bunsen burner the safe way and change between the yellow safety flame and the hot blue roaring flame.',
    'chemistry', 'ChemLab', 2,
    ['Light a Bunsen burner safely', 'Control the flame with the air hole', 'Explain why the blue flame is hotter'],
    [PPE_EQ['goggles1'], PPE_EQ['coat1'], {'id': 'burner', 'type': 'bunsen_burner', 'slot': 'benchA.center'}],
    ppe('goggles1', 'coat1') + [
        act('close', 'Close the air hole', 'Close the air hole completely before lighting (turn the collar to 0).', 'Rotate', 'burner', value=(0, 0.05), until='burner.airHole <= 0.05',
            hints=['Select the burner and choose "Adjust".', 'Move the slider all the way to the left.'], say='A closed air hole gives a visible yellow flame — the safety flame.'),
        act('light', 'Light it', 'Light the burner.', 'Toggle', 'burner', until='burner.lit', hints=['Choose "Light" on the burner.']),
        quiz('q1', 'Why do we light the burner with the air hole CLOSED?', ['The yellow flame is easy to see', 'It is hotter', 'It uses less gas', 'It is quieter'], 0, 'The yellow safety flame is clearly visible, so nobody touches an invisible flame.'),
        act('open', 'Open the air hole', 'Now open the air hole fully to get the blue roaring flame.', 'Rotate', 'burner', value=(0.9, 1.0), until='burner.airHole >= 0.9',
            hints=['Drag the slider all the way to the right.']),
        quiz('q2', 'Why is the blue flame hotter?', ['More oxygen gives complete combustion', 'Blue things are always hot', 'There is more gas', 'The flame is smaller'], 0, 'With the air hole open, oxygen mixes in and the gas burns completely, releasing more energy.'),
        act('off', 'Turn it off', 'Turn the burner off when you are done.', 'Toggle', 'burner', until='!burner.lit', hints=['Choose "Turn off".']),
    ],
    hazards=[NO_GOGGLES('burner.lit')], tags=['heating', 'safety'], xp=90))

LABS.append(lab(
    'chem-acid-or-alkali', 'Acid or Alkali? Using Indicators', 'Use phenolphthalein to test a solution, then add alkali drop by drop and watch the colour change appear.',
    'chemistry', 'ChemLab', 2,
    ['Use an indicator to test a solution', 'Describe the colour change of phenolphthalein', 'Link colour to pH'],
    [PPE_EQ['goggles1'], PPE_EQ['coat1'],
     {'id': 'phth', 'type': 'indicator', 'slot': 'shelf.1', 'label': 'Phenolphthalein', 'init': {'name': 'phenolphthalein'}},
     {'id': 'burette1', 'type': 'burette', 'slot': 'benchA.center', 'init': {'solution': 'NaOH', 'conc': 0.1, 'volume': 50}},
     {'id': 'naoh', 'type': 'reagent_bottle', 'slot': 'shelf.2', 'label': 'NaOH 0.1 M', 'init': {'solution': 'NaOH', 'conc': 0.1, 'volume': 500}},
     {'id': 'tile1', 'type': 'white_tile', 'slot': 'benchB.center'},
     {'id': 'flask1', 'type': 'conical_flask', 'slot': 'benchB.left', 'label': 'Mystery solution', 'init': {'solution': 'HCl', 'conc': 0.05, 'volume': 20}}],
    ppe('goggles1', 'coat1') + [
        act('drops', 'Add indicator', 'Add a few drops of phenolphthalein to the mystery solution.', 'Pour', 'phth', into='flask1', until='flask1.hasIndicator',
            hints=['Select the small brown dropper bottle, choose "Pour", then select the flask.']),
        quiz('q1', 'The solution stayed colourless. What does that tell you?', ['It is acidic or neutral (pH below 8.2)', 'It is strongly alkaline', 'The indicator is broken', 'It is pure water'], 0, 'Phenolphthalein is colourless below about pH 8.2 and pink above it.'),
        act('rinse', 'Prepare the burette', 'Rinse the burette with sodium hydroxide.', 'Pour', 'naoh', into='burette1', until='burette1.rinsed', hints=['Pour NaOH into the burette once — the first pour is the rinse.']),
        act('fill', 'Fill the burette', 'Fill the burette with sodium hydroxide.', 'Pour', 'naoh', into='burette1', until='burette1.filled', hints=['Pour again to fill it.']),
        act('place', 'Position the flask', 'Put the flask on the white tile under the burette.', 'Grab', 'flask1', into='tile1', hints=['Pick up the flask, then select the white tile.']),
        act('add', 'Add alkali', 'Open the burette tap and add alkali until the solution turns pink.', 'Rotate', 'burette1', until='titr.colorIndex >= 0.35',
            hints=['Turn the tap open. Watch the flask!', 'Close the tap as soon as the pink colour stays.'], focus='flask1'),
        quiz('q2', 'Why did the solution turn pink?', ['Enough alkali was added to raise the pH above 8.2', 'The acid evaporated', 'The tile reflected pink light', 'Phenolphthalein went off'], 0, 'Once all the acid is neutralised, a little extra alkali makes the solution alkaline and the indicator turns pink.'),
    ],
    variables={'titr': {'model': 'chem.titration', 'inputs': {'flask': 'flask1', 'burette': 'burette1'}, 'params': {'indicator': 'phenolphthalein'}}},
    hazards=[NO_GOGGLES('burette1.volumeMl > 0')], tags=['indicators', 'pH'], xp=100))


def titration(id, title, summary, difficulty, acid, acid_conc, base_conc, label, hints_level, tags, extra_steps=()):
    eq = acid_conc * 25 / base_conc
    h = (lambda *x: list(x)) if hints_level >= 2 else (lambda *x: list(x[:1]) if hints_level == 1 else [])
    steps = ppe('goggles1', 'coat1', hints=hints_level >= 1) + [
        act('funnel', 'Prepare the burette', 'Place the funnel in the burette.', 'Grab', 'funnel1', focus='burette1', points=5, hints=h('Pick up the funnel and it goes onto the burette.')),
        act('rinse', 'Prepare the burette', 'Rinse the burette with the sodium hydroxide solution.', 'Pour', 'naoh', into='burette1', until='burette1.rinsed', hints=h('The first pour into an empty burette is the rinse.', 'Rinsing stops water diluting the alkali.')),
        act('fill', 'Fill the burette', 'Fill the burette to just above zero.', 'Pour', 'naoh', into='burette1', until='burette1.filled && burette1.volumeMl >= 49', hints=h('Pour again until it is nearly full.')),
        measure('read0', 'Initial reading', 'Read the burette at eye level and record the initial reading.', 'initialReading', 'Initial burette reading', 'cm³', 'burette1.reading', 0.05, focus='burette1', hints=h('Read the BOTTOM of the meniscus.', 'The scale reads downwards from 0.00.')),
        act('indicator', 'Add indicator', 'Add phenolphthalein to the acid in the flask.', 'Pour', 'phth', into='flask1', until='flask1.hasIndicator', hints=h('Pour the dropper into the flask.')),
        act('tile', 'Position the flask', 'Place the flask on the white tile under the burette.', 'Grab', 'flask1', into='tile1', hints=h('Pick up the flask, then select the tile.')),
        act('titrate', 'Titrate', 'Add alkali while swirling; go drop by drop near the end point and stop at the first permanent pale pink.', 'Rotate', 'burette1', until='titr.colorIndex >= 0.35', focus='flask1',
            points=20, hints=h('Open the tap wide at first, then nearly close it near the end.', 'If the pink fades when swirled you are close.')),
        measure('read1', 'Final reading', 'Record the final burette reading.', 'finalReading', 'Final burette reading', 'cm³', 'burette1.reading', 0.05, focus='burette1', hints=h('Eye level, bottom of the meniscus.')),
        measure('titre', 'Titre', 'Calculate the titre (final − initial).', 'titre', 'Titre', 'cm³', 'record.finalReading - record.initialReading', 0.05, hints=h('Subtract the initial reading from the final reading.')),
        measure('conc', 'Concentration', f'Calculate the concentration of the acid (25.0 cm³ of acid, NaOH {base_conc} mol/dm³, 1:1 ratio).', 'acidConc', 'Acid concentration', 'mol/dm³',
                f'round(record.titre * {base_conc} / 25, 4)', 0.002, hints=h(f'moles NaOH = {base_conc} × titre ÷ 1000', 'concentration = moles ÷ 0.025 dm³')),
    ] + list(extra_steps)
    return lab(id, title, summary, 'chemistry', 'ChemLab', difficulty,
               ['Set up and fill a burette', 'Detect the end point', 'Calculate an unknown concentration'],
               [PPE_EQ['goggles1'], PPE_EQ['coat1'],
                {'id': 'naoh', 'type': 'reagent_bottle', 'slot': 'shelf.1', 'label': f'NaOH {base_conc} M', 'init': {'solution': 'NaOH', 'conc': base_conc, 'volume': 500}},
                {'id': 'phth', 'type': 'indicator', 'slot': 'shelf.2', 'label': 'Phenolphthalein', 'init': {'name': 'phenolphthalein'}},
                {'id': 'burette1', 'type': 'burette', 'slot': 'benchA.center', 'init': {'solution': 'NaOH', 'conc': base_conc, 'volume': 50}},
                {'id': 'funnel1', 'type': 'funnel', 'slot': 'benchA.right'},
                {'id': 'tile1', 'type': 'white_tile', 'slot': 'benchB.center'},
                {'id': 'flask1', 'type': 'conical_flask', 'slot': 'benchB.left', 'label': label, 'init': {'solution': acid, 'conc': acid_conc, 'volume': 25}}],
               steps,
               variables={'titr': {'model': 'chem.titration', 'inputs': {'flask': 'flask1', 'burette': 'burette1'}, 'params': {'indicator': 'phenolphthalein'}}},
               hazards=[NO_GOGGLES('(burette1.volumeMl > 0 || naoh.poured)'),
                        {'id': 'overshoot', 'when': 'titr.pH > 11.5', 'message': 'You overshot the end point — the solution is deep pink.', 'severity': 'warn', 'penalty': 10}],
               results=[{'key': 'titre', 'label': 'Titre', 'unit': 'cm³', 'expected': round(eq, 2), 'tolerancePct': 1.5, 'source': 'record.titre'},
                        {'key': 'acidConc', 'label': 'Acid concentration', 'unit': 'mol/dm³', 'expected': acid_conc, 'tolerancePct': 2, 'source': 'record.acidConc'}],
               tags=tags, xp=40 + difficulty * 35)


LABS.append(titration('chem-titration-vinegar', 'Titration: How Strong Is Vinegar?', 'Vinegar contains ethanoic acid, a WEAK acid. Titrate it with sodium hydroxide and see why phenolphthalein is the right indicator for a weak acid.',
                      4, 'CH3COOH', 0.1, 0.125, 'Vinegar (diluted)', 1, ['titration', 'weak acids'],
                      [quiz('q1', 'Why is phenolphthalein (and not methyl orange) used for ethanoic acid?', ['The end point of a weak acid–strong base titration is alkaline (pH ≈ 8.7)', 'Methyl orange is too expensive', 'Phenolphthalein works for every titration', 'Vinegar is already pink'], 0,
                             'At equivalence the solution contains ethanoate ions, which make it slightly alkaline, so an indicator that changes around pH 8–10 is needed.')]))
LABS.append(titration('chem-titration-challenge', 'Expert Challenge: Unknown Acid Concentration', 'Exam conditions: no step-by-step hints. Find the exact concentration of an unknown hydrochloric acid sample using 0.100 mol/dm³ sodium hydroxide.',
                      5, 'HCl', 0.084, 0.1, 'Unknown HCl', 0, ['titration', 'exam practice']))

# ═════════════════════════════════════ PHYSICS ═══════════════════════════════

CIRCUIT = lambda ohms=47: [
    {'id': 'psu', 'type': 'power_supply', 'slot': 'benchA.left', 'init': {'maxVoltage': 12}},
    {'id': 'board', 'type': 'breadboard', 'slot': 'benchA.center'},
    {'id': 'r1', 'type': 'resistor', 'slot': 'benchB.left', 'label': f'Resistor {ohms} Ω' if ohms else 'Resistor R', 'init': {'ohms': ohms}},
    {'id': 'amm', 'type': 'ammeter', 'slot': 'benchB.center'},
    {'id': 'volt', 'type': 'voltmeter', 'slot': 'benchB.right'},
]
CIRC_VAR = {'circ': {'model': 'phys.circuit', 'inputs': {'circuit': 'board'}, 'params': {}}}
SHORT = {'id': 'short', 'when': 'board.shortCircuit', 'message': 'Short circuit! An ammeter with no resistor in the loop shorts the supply. Switch off and fix it.', 'severity': 'warn', 'penalty': 15}


def build_circuit(hints=True):
    h = (lambda *x: list(x)) if hints else (lambda *x: [])
    return [
        act('place', 'Build the circuit', 'Connect the resistor to the circuit board.', 'Connect', 'r1', into='board', until='r1.connected', hints=h('Select the resistor, choose "Connect", then select the green board.')),
        act('ammeter', 'Build the circuit', 'Connect the ammeter in SERIES.', 'Connect', 'amm', into='board', until='amm.connected', hints=h('An ammeter goes in the same loop as the resistor.')),
        act('voltmeter', 'Build the circuit', 'Connect the voltmeter in PARALLEL across the resistor.', 'Connect', 'volt', into='board', until='volt.connected', hints=h('A voltmeter goes across (side by side with) the resistor.')),
        act('power', 'Power on', 'Switch on the power supply.', 'Toggle', 'psu', until='psu.on', hints=h('Choose "Switch on" on the power supply.')),
    ]


LABS.append(lab(
    'phys-meet-the-meters', 'Meet the Meters: Ammeter & Voltmeter', 'Learn what ammeters and voltmeters measure and how to connect them correctly before you build your first circuit.',
    'physics', 'PhysicsLab', 1,
    ['Know what an ammeter and a voltmeter measure', 'Connect meters in series and in parallel'],
    CIRCUIT(47),
    [act('see_amm', 'The ammeter', 'Look closely at the ammeter.', 'Inspect', 'amm', hints=['Select the meter marked "A".'], say='An ammeter measures current in amperes (A).'),
     act('see_volt', 'The voltmeter', 'Look closely at the voltmeter.', 'Inspect', 'volt', hints=['Select the meter marked "V".'], say='A voltmeter measures potential difference in volts (V).'),
     quiz('q1', 'How must an ammeter be connected?', ['In series, in the same loop as the component', 'In parallel, across the component', 'Directly across the power supply', 'It does not matter'], 0, 'Current must flow THROUGH the ammeter, so it goes in series.'),
     act('place', 'Build the circuit', 'Connect the resistor to the board.', 'Connect', 'r1', into='board', until='r1.connected', hints=['Select the resistor, "Connect", then the board.']),
     act('ammeter', 'Build the circuit', 'Connect the ammeter in series.', 'Connect', 'amm', into='board', until='amm.connected', hints=['Select the ammeter, "Connect", then the board.']),
     act('voltmeter', 'Build the circuit', 'Connect the voltmeter across the resistor.', 'Connect', 'volt', into='board', until='volt.connected', hints=['Select the voltmeter, "Connect", then the board.']),
     quiz('q2', 'An ideal voltmeter has…', ['A very high resistance', 'Zero resistance', 'The same resistance as the circuit', 'No battery'], 0, 'High resistance means almost no current is diverted through the voltmeter.'),
     ], variables=CIRC_VAR, hazards=[SHORT], tags=['circuits', 'start here'], xp=60, duration=8))

LABS.append(lab(
    'phys-ohms-law-two-readings', "Ohm's Law: Does Current Double?", 'Measure the current through a resistor at 3 V and at 9 V. Does tripling the voltage triple the current?',
    'physics', 'PhysicsLab', 3,
    ['Take repeated readings at different voltages', 'Show that I is proportional to V', 'Calculate resistance from a pair of readings'],
    CIRCUIT(100),
    build_circuit() + [
        act('v3', 'First reading', 'Set the supply to 3.0 V.', 'Rotate', 'psu', value=(2.9, 3.1), until='between(psu.voltageV, 2.9, 3.1)', hints=['Choose "Set voltage" and move to 3.0 V.']),
        measure('i3', 'First reading', 'Record the current at 3 V.', 'i3', 'Current at 3 V', 'A', 'amm.reading', 0.002, focus='amm', hints=['Read the ammeter display.']),
        act('v9', 'Second reading', 'Increase the supply to 9.0 V.', 'Rotate', 'psu', value=(8.9, 9.1), until='between(psu.voltageV, 8.9, 9.1)', hints=['Move the slider to 9.0 V.']),
        measure('i9', 'Second reading', 'Record the current at 9 V.', 'i9', 'Current at 9 V', 'A', 'amm.reading', 0.002, focus='amm'),
        measure('ratio', 'Compare', 'Calculate I(9 V) ÷ I(3 V).', 'ratio', 'Current ratio', '', 'record.i9 / record.i3', 0.05, hints=['Divide the second current by the first.']),
        measure('resist', 'Calculate', 'Calculate the resistance R = V ÷ I using the 9 V reading.', 'resistance', 'Resistance', 'Ω', '9 / record.i9', 2, hints=['R = 9 ÷ current at 9 V.']),
        quiz('q1', 'The voltage tripled and the current tripled. This shows that…', ['Current is directly proportional to voltage', 'Resistance tripled', 'The ammeter is faulty', 'Power stayed the same'], 0, "That is Ohm's law: for a fixed resistor, I ∝ V."),
    ],
    variables=CIRC_VAR, hazards=[SHORT],
    results=[{'key': 'ratio', 'label': 'I(9 V) ÷ I(3 V)', 'unit': '', 'expected': 3, 'tolerancePct': 3, 'source': 'record.ratio'},
             {'key': 'resistance', 'label': 'Resistance', 'unit': 'Ω', 'expected': 100, 'tolerancePct': 4, 'source': 'record.resistance'}],
    tags=['circuits', 'Ohm\'s law']))

LABS.append(lab(
    'phys-series-resistors', 'Resistors in Series', 'Connect two resistors one after the other and discover how their resistances combine.',
    'physics', 'PhysicsLab', 4,
    ['Build a series circuit with two resistors', 'Measure total resistance', 'Use R = R₁ + R₂'],
    [{'id': 'psu', 'type': 'power_supply', 'slot': 'benchA.left', 'init': {'maxVoltage': 12}},
     {'id': 'board', 'type': 'breadboard', 'slot': 'benchA.center'},
     {'id': 'r1', 'type': 'resistor', 'slot': 'benchB.left', 'label': 'R₁ = 47 Ω', 'init': {'ohms': 47}},
     {'id': 'r2', 'type': 'resistor', 'slot': 'benchA.right', 'label': 'R₂ = 100 Ω', 'init': {'ohms': 100}},
     {'id': 'amm', 'type': 'ammeter', 'slot': 'benchB.center'},
     {'id': 'volt', 'type': 'voltmeter', 'slot': 'benchB.right'}],
    [act('place1', 'Build the circuit', 'Connect R₁ to the board.', 'Connect', 'r1', into='board', until='r1.connected', hints=['Select R₁, "Connect", then the board.']),
     act('place2', 'Build the circuit', 'Connect R₂ in series with R₁.', 'Connect', 'r2', into='board', until='r2.connected'),
     act('ammeter', 'Build the circuit', 'Add the ammeter in series.', 'Connect', 'amm', into='board', until='amm.connected'),
     act('voltmeter', 'Build the circuit', 'Connect the voltmeter across both resistors.', 'Connect', 'volt', into='board', until='volt.connected'),
     act('power', 'Power on', 'Switch on the power supply.', 'Toggle', 'psu', until='psu.on', hints=['Choose "Switch on".']),
     act('setv', 'Set the voltage', 'Set the supply to 6.0 V.', 'Rotate', 'psu', value=(5.9, 6.1), until='between(psu.voltageV, 5.9, 6.1)', hints=['Choose "Set voltage".']),
     measure('v', 'Readings', 'Record the voltmeter reading.', 'voltage', 'Voltage', 'V', 'volt.reading', 0.05, focus='volt'),
     measure('i', 'Readings', 'Record the ammeter reading.', 'current', 'Current', 'A', 'amm.reading', 0.002, focus='amm'),
     measure('rt', 'Calculate', 'Calculate the total resistance V ÷ I.', 'total', 'Total resistance', 'Ω', 'record.voltage / record.current', 2),
     quiz('q1', 'Two resistors of 47 Ω and 100 Ω in series have a total resistance of…', ['147 Ω', '53 Ω', '32 Ω', '4700 Ω'], 0, 'In series, resistances simply add: R = R₁ + R₂.'),
     ],
    variables=CIRC_VAR, hazards=[SHORT],
    results=[{'key': 'total', 'label': 'Total resistance', 'unit': 'Ω', 'expected': 147, 'tolerancePct': 3, 'source': 'record.total'}],
    tags=['circuits', 'series']))


def pendulum(id, title, summary, difficulty, length, hints, tags):
    h = (lambda *x: list(x)) if hints else (lambda *x: [])
    return lab(id, title, summary, 'physics', 'PhysicsLab', difficulty,
               ['Measure a pendulum accurately', 'Reduce timing error', 'Calculate g'],
               [{'id': 'pend', 'type': 'pendulum', 'slot': 'benchA.center', 'init': {'lengthM': length, 'massKg': 0.05}},
                {'id': 'watch', 'type': 'stopwatch', 'slot': 'benchB.center'},
                {'id': 'rule', 'type': 'metre_rule', 'slot': 'benchA.right'}],
               [measure('measureL', 'Measure the length', 'Measure from the pivot to the centre of the bob.', 'length', 'Length L', 'm', 'pend.lengthM', 0.005, focus='rule', hints=h('Use the metre rule; measure to the CENTRE of the bob.')),
                act('release', 'Start the swing', 'Pull the bob aside (less than 10°) and release it.', 'Release', 'pend', until='pend.swinging && pend.amplitudeDeg <= 10', hints=h('Choose a small angle like 6–8°.')),
                act('time20', 'Time 20 oscillations', 'Time 20 complete oscillations with the stopwatch.', 'Toggle', 'watch', until='pend.oscillations >= 20 && !watch.running', focus='pend', points=20, hints=h('Start as the bob passes the centre; stop after 20 swings there and back.')),
                measure('period', 'Period', 'Calculate the period T = time ÷ 20.', 'period', 'Period T', 's', 'watch.elapsedS / 20', 0.02, hints=h('Divide your stopwatch time by 20.')),
                measure('gcalc', 'Calculate g', 'Calculate g = 4π²L ÷ T².', 'g', 'g', 'm/s²', '4 * 9.8696 * record.length / (record.period * record.period)', 0.1, hints=h('4π² ≈ 39.48')),
                quiz('q1', 'If the pendulum were made 4 times longer, its period would…', ['Double', 'Quadruple', 'Halve', 'Stay the same'], 0, 'T ∝ √L, so 4× the length gives 2× the period.'),
                ],
               variables={'pm': {'model': 'phys.pendulum', 'inputs': {'pendulum': 'pend'}}},
               results=[{'key': 'g', 'label': 'g', 'unit': 'm/s²', 'expected': 9.81, 'tolerancePct': 3, 'source': 'record.g'}],
               scoring={'accuracy': 50, 'procedure': 50, 'safety': 0}, tags=tags)


LABS.append(pendulum('phys-pendulum-length', 'Pendulum: A Shorter String', 'Repeat the pendulum experiment with a 0.50 m string. Does g change? Does the period?', 4, 0.5, True, ['mechanics', 'investigation']))
LABS.append(pendulum('phys-pendulum-challenge', 'Expert Challenge: Measure g Precisely', 'No hints. Use a 1.20 m pendulum and get g within 3% of 9.81 m/s².', 5, 1.2, False, ['mechanics', 'exam practice']))

# ═════════════════════════════════════ BIOLOGY ═══════════════════════════════

SCOPE = {'id': 'scope', 'type': 'microscope', 'slot': 'scope.station', 'init': {'commands': ['4x', '10x', '40x']}}
MIC_VAR = {'mic': {'model': 'bio.microscope', 'inputs': {'microscope': 'scope'}, 'params': {'idealFocus': 0.62}}}


def slide_prep(stain_name, specimen, hints=True):
    h = (lambda *x: list(x)) if hints else (lambda *x: [])
    return [
        act('stain', 'Stain the specimen', f'Add {stain_name} to the {specimen} on the slide.', 'Pour', 'stain1', into='slide1', until='slide1.stained', hints=h('Select the stain dropper, "Pour", then select the slide.')),
        act('cover', 'Coverslip', 'Lower a coverslip onto the slide.', 'Select', 'slide1', until='slide1.coverslip', hints=h('Select the stained slide to add the coverslip.', 'Lower it at an angle to avoid air bubbles.')),
        act('stage', 'Load the slide', 'Place the slide on the microscope stage.', 'Grab', 'slide1', into='scope', until='scope.slideLoaded', hints=h('Pick up the slide, then select the microscope.')),
        act('light', 'Light', 'Switch on the microscope light.', 'Toggle', 'scope', until='scope.lightOn', hints=h('Choose "Light on".')),
        act('focus', 'Focus', 'Focus the image with the fine focus knob.', 'Rotate', 'scope', value=(0.6, 0.64), until='mic.focusQuality >= 0.8', hints=h('Choose "Focus" and move the slider slowly until the image is sharp (around 62%).')),
    ]


LABS.append(lab(
    'bio-microscope-parts', 'Parts of the Microscope', 'Get to know the light microscope: eyepiece, objectives, stage, light and focus knobs.',
    'biology', 'BioLab', 1,
    ['Name the parts of a light microscope', 'Calculate total magnification'],
    [SCOPE],
    [act('look', 'Meet the microscope', 'Look closely at the microscope.', 'Inspect', 'scope', hints=['Select the microscope and choose "Look closer".'], say='The eyepiece magnifies 10×; the objectives on the turret magnify 4×, 10× or 40×.'),
     act('light', 'Light', 'Switch the light on.', 'Toggle', 'scope', until='scope.lightOn', hints=['Choose "Light on".']),
     cmd('turret', 'Objectives', 'Click the 10× objective into place.', 'scope', '10x', hints=['Choose "Run a command" (the turret) and pick 10x.']),
     measure('mag', 'Magnification', 'What is the total magnification now?', 'mag', 'Total magnification', '×', 'mic.magnification', 0, hints=['Total = eyepiece (10×) × objective.']),
     quiz('q1', 'Which part do you use to focus at high power?', ['The fine focus knob', 'The coarse focus knob', 'The light switch', 'The stage clips'], 0, 'At high power only the fine focus knob is used, to avoid crushing the slide.'),
     ], variables=MIC_VAR,
    results=[{'key': 'mag', 'label': 'Magnification', 'unit': '×', 'expected': 100, 'tolerancePct': 1, 'source': 'record.mag'}],
    tags=['microscopy', 'start here'], xp=60, duration=8))

LABS.append(lab(
    'bio-onion-cells', 'Onion Epidermis Cells', 'Prepare a slide of onion skin, stain it with iodine and see real plant cells — cell walls, nuclei and all.',
    'biology', 'BioLab', 2,
    ['Prepare a stained wet-mount slide', 'Focus a microscope at low power', 'Identify plant cell structures'],
    [PPE_EQ['gloves1'], SCOPE,
     {'id': 'slide1', 'type': 'slide', 'slot': 'prep.station', 'label': 'Onion epidermis', 'init': {'specimen': 'onion'}},
     {'id': 'stain1', 'type': 'stain', 'slot': 'benchA.center', 'label': 'Iodine solution', 'init': {'name': 'iodine'}}],
    ppe('gloves1') + slide_prep('iodine', 'onion skin') + [
        measure('mag', 'Magnification', 'Record the total magnification you are using.', 'mag', 'Total magnification', '×', 'mic.magnification', 0, hints=['The 4× objective with a 10× eyepiece.']),
        quiz('q1', 'Which structure do onion cells have that animal cells do NOT?', ['A cell wall', 'A nucleus', 'Cytoplasm', 'A cell membrane'], 0, 'Plant cells have a rigid cellulose cell wall around the membrane.'),
        quiz('q2', 'Why did we stain the cells with iodine?', ['To make the transparent structures visible', 'To kill bacteria', 'To make the slide sticky', 'To magnify the cells'], 0, 'Stains bind to cell structures (like the nucleus) and add contrast.'),
    ],
    variables=MIC_VAR, hazards=[{'id': 'noGloves', 'when': '!gloves1.worn && stain1.dropsAdded > 0', 'message': 'Iodine stains skin — wear gloves.', 'severity': 'warn', 'penalty': 10}],
    results=[{'key': 'mag', 'label': 'Magnification', 'unit': '×', 'expected': 40, 'tolerancePct': 1, 'source': 'record.mag'}],
    tags=['microscopy', 'plant cells']))

LABS.append(lab(
    'bio-cheek-cells', 'Human Cheek Cells', 'Look at your own cells! Stain cheek cells with methylene blue and compare them with plant cells.',
    'biology', 'BioLab', 3,
    ['Prepare an animal cell slide', 'Compare plant and animal cells'],
    [PPE_EQ['gloves1'], SCOPE,
     {'id': 'slide1', 'type': 'slide', 'slot': 'prep.station', 'label': 'Cheek cells', 'init': {'specimen': 'cheek'}},
     {'id': 'stain1', 'type': 'stain', 'slot': 'benchA.center', 'label': 'Methylene blue', 'init': {'name': 'methylene_blue'}}],
    ppe('gloves1') + slide_prep('methylene blue', 'cheek cells') + [
        cmd('mag10', 'Higher power', 'Switch to the 10× objective.', 'scope', '10x', hints=['Use the turret and pick 10x.']),
        act('refocus', 'Refocus', 'Refocus with the fine focus.', 'Rotate', 'scope', value=(0.6, 0.64), until='mic.focusQuality >= 0.8 && scope.objective == 10'),
        quiz('q1', 'Cheek cells look irregular and rounded. Why?', ['Animal cells have no rigid cell wall', 'They were squashed by the coverslip', 'They are dead', 'The stain changed their shape'], 0, 'Without a cell wall, animal cells have flexible, irregular shapes.'),
        quiz('q2', 'What should happen to used cheek swabs?', ['Put in disinfectant / biohazard waste', 'Back in the box', 'In the normal bin', 'Rinsed in the sink'], 0, 'Human samples can carry pathogens, so they are disposed of as biohazard waste.'),
    ],
    variables=MIC_VAR, hazards=[{'id': 'noGloves', 'when': '!gloves1.worn && stain1.dropsAdded > 0', 'message': 'Wear gloves when handling human samples and stains.', 'severity': 'warn', 'penalty': 15}],
    tags=['microscopy', 'animal cells']))

LABS.append(lab(
    'bio-high-power', 'High-Power Microscopy (400×)', 'Move from low power to 400× without losing your specimen — the skill every biologist needs.',
    'biology', 'BioLab', 4,
    ['Change objectives in the correct order', 'Use only fine focus at high power', 'Calculate magnification'],
    [SCOPE, {'id': 'slide1', 'type': 'slide', 'slot': 'prep.station', 'label': 'Onion epidermis', 'init': {'specimen': 'onion'}},
     {'id': 'stain1', 'type': 'stain', 'slot': 'benchA.center', 'label': 'Iodine solution', 'init': {'name': 'iodine'}}],
    slide_prep('iodine', 'onion skin') + [
        cmd('mag10', 'Medium power', 'Switch to 10×.', 'scope', '10x', hints=['Always go 4× → 10× → 40× in order.']),
        act('focus10', 'Refocus', 'Refocus at 10×.', 'Rotate', 'scope', value=(0.6, 0.64), until='mic.focusQuality >= 0.8 && scope.objective == 10'),
        cmd('mag40', 'High power', 'Switch to 40×.', 'scope', '40x'),
        act('focus40', 'Refocus', 'Refocus at 40× — depth of field is very small now.', 'Rotate', 'scope', value=(0.61, 0.63), until='mic.focusQuality >= 0.8 && scope.objective == 40', hints=['Tiny movements only.']),
        measure('mag', 'Magnification', 'Record the total magnification.', 'mag', 'Total magnification', '×', 'mic.magnification', 0),
        measure('size', 'Real size', 'A cell looks 8 mm long at this magnification. What is its real length in micrometres (µm)? (1 mm = 1000 µm)', 'size', 'Real cell length', 'µm', '8 * 1000 / mic.magnification', 0.5,
                hints=['Real size = image size ÷ magnification.']),
    ],
    variables=MIC_VAR,
    results=[{'key': 'mag', 'label': 'Magnification', 'unit': '×', 'expected': 400, 'tolerancePct': 1, 'source': 'record.mag'},
             {'key': 'size', 'label': 'Real cell length', 'unit': 'µm', 'expected': 20, 'tolerancePct': 3, 'source': 'record.size'}],
    scoring={'accuracy': 50, 'procedure': 50, 'safety': 0}, tags=['microscopy', 'magnification']))

LABS.append(lab(
    'bio-magnification-challenge', 'Expert Challenge: Measuring Cells', 'No hints. Calculate magnification and real cell sizes at two different powers.',
    'biology', 'BioLab', 5,
    ['Use I = A × M fluently', 'Convert between mm and µm'],
    [SCOPE, {'id': 'slide1', 'type': 'slide', 'slot': 'prep.station', 'label': 'Onion epidermis', 'init': {'specimen': 'onion'}},
     {'id': 'stain1', 'type': 'stain', 'slot': 'benchA.center', 'label': 'Iodine solution', 'init': {'name': 'iodine'}}],
    slide_prep('iodine', 'onion skin', hints=False) + [
        cmd('mag10', 'Medium power', 'Switch to 10×.', 'scope', '10x'),
        act('focus10', 'Refocus', 'Refocus.', 'Rotate', 'scope', value=(0.6, 0.64), until='mic.focusQuality >= 0.8 && scope.objective == 10'),
        measure('size10', 'Measure', 'A cell image is 25 mm long at this power. Real length in µm?', 'size10', 'Real length at 100×', 'µm', '25 * 1000 / mic.magnification', 1),
        cmd('mag40', 'High power', 'Switch to 40×.', 'scope', '40x'),
        act('focus40', 'Refocus', 'Refocus.', 'Rotate', 'scope', value=(0.61, 0.63), until='mic.focusQuality >= 0.8 && scope.objective == 40'),
        measure('img40', 'Predict', 'How long (mm) will the same cell look at this power?', 'img40', 'Image length at 400×', 'mm', '250 * mic.magnification / 1000', 1),
    ],
    variables=MIC_VAR,
    results=[{'key': 'size10', 'label': 'Real length', 'unit': 'µm', 'expected': 250, 'tolerancePct': 2, 'source': 'record.size10'},
             {'key': 'img40', 'label': 'Image at 400×', 'unit': 'mm', 'expected': 100, 'tolerancePct': 2, 'source': 'record.img40'}],
    scoring={'accuracy': 60, 'procedure': 40, 'safety': 0}, tags=['microscopy', 'exam practice']))

# ═════════════════════════════════════ CYBERSECURITY ═════════════════════════

WS = lambda commands, slot='desk.main', label='Analyst workstation': {'id': 'ws', 'type': 'workstation', 'slot': slot, 'label': label, 'init': {'os': 'ECH-SOC Linux', 'commands': commands}}
SCREEN = {'id': 'screen', 'type': 'wall_display', 'slot': 'wall.screen', 'label': 'Threat map'}

LABS.append(lab(
    'cyber-soc-orientation', 'Welcome to the Security Operations Center', 'Your first shift as a junior security analyst: log in, read the dashboards and learn the CIA triad.',
    'cybersecurity', 'CyberSOC', 1,
    ['Know what a SOC does', 'Explain confidentiality, integrity and availability'],
    [WS(['login', 'show dashboard', 'show alerts', 'logout']), SCREEN],
    [cmd('login', 'Start your shift', 'Log in to your workstation.', 'ws', 'login', hints=['Select the workstation, choose "Run a command", then "login".'], say='A Security Operations Center watches an organisation\'s networks 24/7.'),
     cmd('dash', 'Dashboards', 'Open the security dashboard.', 'ws', 'show dashboard', hints=['Run "show dashboard".']),
     act('map', 'Threat map', 'Look at the live threat map on the wall.', 'Inspect', 'screen', hints=['Select the big screen and choose "Look closer".']),
     quiz('q1', 'Someone reads a student\'s exam results without permission. Which part of the CIA triad is broken?', ['Confidentiality', 'Integrity', 'Availability', 'None'], 0, 'Confidentiality = only authorised people can read information.'),
     quiz('q2', 'The school website is knocked offline. Which part is broken?', ['Availability', 'Confidentiality', 'Integrity', 'Authentication'], 0, 'Availability = systems are there when people need them.'),
     cmd('logout', 'End your shift', 'Log out — never leave a workstation logged in.', 'ws', 'logout', hints=['Run "logout".']),
     ], tags=['start here', 'CIA triad'], xp=60, duration=8))

LABS.append(lab(
    'cyber-password-safety', 'Strong Passwords & MFA', 'Test passwords against a cracking tool and set up multi-factor authentication for a teacher account.',
    'cybersecurity', 'CyberSOC', 2,
    ['Recognise weak passwords', 'Explain why MFA helps'],
    [WS(['test password 123456', 'test password Kigali2024', 'test password correct-horse-battery-staple', 'enable mfa teacher01'])],
    [cmd('t1', 'Test a password', 'Test the password "123456".', 'ws', 'test password 123456', hints=['Run the first test command.'], say='Result: cracked in less than 1 second — it is the most common password in the world.'),
     cmd('t2', 'Test a password', 'Test "Kigali2024".', 'ws', 'test password Kigali2024', say='Result: cracked in about 3 hours — a place plus a year is easy to guess.'),
     cmd('t3', 'Test a passphrase', 'Test the passphrase "correct-horse-battery-staple".', 'ws', 'test password correct-horse-battery-staple', say='Result: centuries to crack — long passphrases are strong AND easy to remember.'),
     quiz('q1', 'Which makes a password strongest?', ['Length — a long passphrase', 'Replacing a with @', 'Adding the year', 'Using your pet\'s name'], 0, 'Every extra character multiplies the number of guesses needed.'),
     cmd('mfa', 'Multi-factor authentication', 'Enable MFA on the teacher01 account.', 'ws', 'enable mfa teacher01', hints=['Run "enable mfa teacher01".']),
     quiz('q2', 'A hacker steals a password but the account has MFA. What happens?', ['They still need the second factor (e.g. the phone code)', 'They get in anyway', 'The account is deleted', 'The password changes itself'], 0, 'MFA means a stolen password alone is not enough.'),
     ], tags=['passwords', 'MFA']))

LABS.append(lab(
    'cyber-phishing-triage', 'Phishing Email Triage', 'Three suspicious emails have been reported by teachers. Investigate them and decide which ones are phishing.',
    'cybersecurity', 'CyberSOC', 2,
    ['Spot the signs of phishing', 'Report and block a phishing campaign'],
    [WS(['login', 'open inbox', 'check sender email-1', 'check link email-1', 'report phishing email-1', 'block sender ech-payments@ech-support.biz', 'mark safe email-2'])],
    [cmd('login', 'Start', 'Log in.', 'ws', 'login', hints=['Run "login".']),
     cmd('inbox', 'Reported emails', 'Open the reported-emails inbox.', 'ws', 'open inbox', say='Email 1: "URGENT: your salary is on hold — confirm your bank details today" from ech-payments@ech-support.biz.'),
     cmd('sender', 'Investigate', 'Check the sender of email 1.', 'ws', 'check sender email-1', hints=['Look at the domain after the @.'], say='The domain ech-support.biz is NOT the school\'s real domain.'),
     cmd('link', 'Investigate', 'Check where the link in email 1 really goes.', 'ws', 'check link email-1', say='The "Login" button points to a fake page that copies the school login.'),
     quiz('q1', 'Which signs show email 1 is phishing?', ['Urgency, a fake domain and a request for bank details', 'It has the school logo', 'It was sent on Monday', 'It is short'], 0, 'Pressure + spoofed sender + asking for credentials or money are classic phishing signs.'),
     cmd('report', 'Act', 'Report email 1 as phishing.', 'ws', 'report phishing email-1'),
     cmd('block', 'Act', 'Block the sender.', 'ws', 'block sender ech-payments@ech-support.biz'),
     cmd('safe', 'Act', 'Email 2 is a genuine message from the head teacher — mark it safe.', 'ws', 'mark safe email-2'),
     ], tags=['phishing', 'email']))

LABS.append(lab(
    'cyber-incident-response', 'Incident Response: Contain the Attack', 'A laptop in the computer lab is sending strange traffic. Follow the incident-response process: identify, contain, eradicate and recover.',
    'cybersecurity', 'CyberSOC', 4,
    ['Follow the incident-response lifecycle', 'Contain an infected host', 'Recover safely'],
    [WS(['login', 'show alerts', 'isolate host lab-pc-07', 'scan host lab-pc-07', 'remove malware lab-pc-07', 'reset password student42', 'reconnect host lab-pc-07', 'write report']),
     {'id': 'fw', 'type': 'firewall', 'slot': 'rack.1', 'label': 'Edge firewall', 'init': {'policy': 'default-deny', 'commands': ['deny malicious-ip 198.51.100.23', 'apply']}}, SCREEN],
    [cmd('login', 'Start', 'Log in.', 'ws', 'login'),
     cmd('alerts', 'Identify', 'Read the alerts.', 'ws', 'show alerts', say='lab-pc-07 is contacting 198.51.100.23 every 30 seconds — typical of malware "calling home".'),
     quiz('q1', 'What should you do FIRST with the infected laptop?', ['Isolate it from the network', 'Delete all its files', 'Turn off the whole school network', 'Ignore it'], 0, 'Containment stops the attack spreading while you investigate.'),
     cmd('isolate', 'Contain', 'Isolate lab-pc-07 from the network.', 'ws', 'isolate host lab-pc-07'),
     act('block', 'Contain', 'Block the attacker\'s server on the edge firewall.', 'Type', 'fw', until='net.blockedThreats >= 1', hints=['Select the firewall in the rack.']),
     act('apply', 'Contain', 'Apply the firewall policy.', 'Type', 'fw', until='fw.applied'),
     cmd('scan', 'Eradicate', 'Scan the laptop.', 'ws', 'scan host lab-pc-07'),
     cmd('remove', 'Eradicate', 'Remove the malware.', 'ws', 'remove malware lab-pc-07'),
     cmd('reset', 'Recover', 'Reset the password of the student who used the laptop.', 'ws', 'reset password student42'),
     cmd('reconnect', 'Recover', 'Reconnect the cleaned laptop.', 'ws', 'reconnect host lab-pc-07'),
     cmd('report', 'Lessons learned', 'Write the incident report.', 'ws', 'write report'),
     ],
    variables={'net': {'model': 'net.firewall', 'inputs': {'firewall': 'fw'}}},
    hazards=[{'id': 'earlyReconnect', 'when': "ws.lastCommand == 'reconnect host lab-pc-07' && !done('remove')", 'message': 'You reconnected an infected laptop! Remove the malware first.', 'severity': 'warn', 'penalty': 25}],
    tags=['incident response']))

LABS.append(lab(
    'cyber-forensics-challenge', 'Expert Challenge: Log Forensics', 'No hints. Analyse the authentication logs, count the failed logins and identify the brute-force attacker.',
    'cybersecurity', 'CyberSOC', 5,
    ['Analyse logs', 'Identify a brute-force attack', 'Recommend controls'],
    [WS(['login', 'grep failed auth.log', 'count failed auth.log', 'top ip auth.log', 'lock account admin'])],
    [cmd('login', 'Start', 'Log in.', 'ws', 'login'),
     cmd('grep', 'Analyse', 'Search the log for failed logins.', 'ws', 'grep failed auth.log', say='auth.log: 48 lines "Failed password for admin from 203.0.113.9" between 02:00 and 02:04.'),
     measure('count', 'Analyse', 'How many failed login attempts were there?', 'failed', 'Failed logins', 'attempts', '48', 0),
     measure('rate', 'Analyse', 'They happened over 4 minutes. How many attempts per minute?', 'rate', 'Attempts per minute', '/min', '48 / 4', 0.1),
     cmd('lock', 'Respond', 'Lock the targeted account.', 'ws', 'lock account admin'),
     quiz('q1', 'Which control best stops this attack in future?', ['Account lockout after a few failed attempts + MFA', 'A bigger monitor', 'Turning off logging', 'Shorter passwords'], 0, 'Lockout and MFA defeat password guessing.'),
     ],
    results=[{'key': 'failed', 'label': 'Failed logins', 'unit': '', 'expected': 48, 'tolerancePct': 1, 'source': 'record.failed'},
             {'key': 'rate', 'label': 'Attempts per minute', 'unit': '/min', 'expected': 12, 'tolerancePct': 1, 'source': 'record.rate'}],
    scoring={'accuracy': 50, 'procedure': 50, 'safety': 0}, tags=['forensics', 'exam practice']))

# ═════════════════════════════════════ NETWORKING ════════════════════════════

NET_WS = lambda commands: {'id': 'ws', 'type': 'workstation', 'slot': 'desk.main', 'label': 'Admin PC', 'init': {'os': 'ECH NetOS', 'commands': commands}}

LABS.append(lab(
    'net-build-a-network', 'Build Your First Network', 'Cable a server to a switch, connect the admin PC and test the connection with ping.',
    'networking', 'ServerRoom', 1,
    ['Know the job of a switch', 'Connect devices with patch cables', 'Test connectivity with ping'],
    [{'id': 'rack1', 'type': 'server_rack', 'slot': 'rack.2', 'label': 'School server'},
     {'id': 'sw', 'type': 'network_switch', 'slot': 'patch.panel', 'label': 'Core switch', 'init': {'ports': 24}},
     {'id': 'cable1', 'type': 'patch_cable', 'slot': 'shelf.1', 'label': 'Blue cable', 'init': {'color': 'blue'}},
     NET_WS(['ping 192.168.1.10', 'ipconfig'])],
    [act('cable', 'Cable the switch', 'Plug the patch cable into the switch.', 'Connect', 'cable1', into='sw', until='cable1.connected', hints=['Select the cable on the shelf, "Connect", then the switch.'], say='A switch connects devices on the same local network (LAN).'),
     act('server', 'Cable the server', 'Look at the server rack you are connecting.', 'Inspect', 'rack1', hints=['Select the tall rack.']),
     cmd('ipc', 'Check settings', 'On the admin PC, check its IP address.', 'ws', 'ipconfig', hints=['Select the PC, "Run a command", "ipconfig".'], say='IPv4 address: 192.168.1.25, subnet mask 255.255.255.0, gateway 192.168.1.1'),
     cmd('ping', 'Test', 'Ping the server at 192.168.1.10.', 'ws', 'ping 192.168.1.10', say='Reply from 192.168.1.10: time=1ms — it works!'),
     quiz('q1', 'What does a successful ping prove?', ['The two devices can reach each other on the network', 'The internet is fast', 'The server is virus-free', 'The cable is blue'], 0, 'Ping sends an echo request and waits for a reply — it tests reachability.'),
     ], tags=['start here', 'LAN'], xp=60, duration=8))

LABS.append(lab(
    'net-ip-addressing', 'IP Addresses & Subnet Masks', 'Read and set IP addresses, and work out how many devices fit on a /24 network.',
    'networking', 'ServerRoom', 2,
    ['Read an IPv4 address and mask', 'Count usable hosts on a /24'],
    [NET_WS(['ipconfig', 'set ip 192.168.1.50/24', 'set gateway 192.168.1.1', 'ping 192.168.1.1'])],
    [cmd('ipc', 'Current settings', 'Show the PC\'s network settings.', 'ws', 'ipconfig', hints=['Run "ipconfig".']),
     cmd('setip', 'Configure', 'Give the PC the address 192.168.1.50 with a /24 mask.', 'ws', 'set ip 192.168.1.50/24', hints=['/24 means the mask 255.255.255.0.']),
     cmd('gw', 'Configure', 'Set the default gateway (the router).', 'ws', 'set gateway 192.168.1.1'),
     cmd('ping', 'Test', 'Ping the gateway.', 'ws', 'ping 192.168.1.1'),
     measure('hosts', 'Calculate', 'How many USABLE host addresses are in a /24 network?', 'hosts', 'Usable hosts', 'hosts', '254', 0, hints=['A /24 has 256 addresses.', 'Subtract the network address and the broadcast address.']),
     quiz('q1', 'What is the default gateway for?', ['Sending traffic to other networks (e.g. the internet)', 'Storing files', 'Naming the PC', 'Printing'], 0, 'The gateway (router) forwards packets that leave the local network.'),
     ], results=[{'key': 'hosts', 'label': 'Usable hosts', 'unit': '', 'expected': 254, 'tolerancePct': 1, 'source': 'record.hosts'}],
    tags=['IPv4', 'subnets']))

LABS.append(lab(
    'net-ping-troubleshoot', 'Troubleshooting: "The Internet Is Down!"', 'Teachers say the internet is down. Use ping and traceroute layer by layer to find the fault.',
    'networking', 'ServerRoom', 3,
    ['Troubleshoot methodically from the bottom up', 'Use ping and traceroute'],
    [NET_WS(['ping 127.0.0.1', 'ping 192.168.1.1', 'ping 8.8.8.8', 'ping google.com', 'traceroute 8.8.8.8', 'set dns 8.8.8.8'])],
    [cmd('lo', 'Step 1', 'Ping the loopback address to test the PC\'s own network stack.', 'ws', 'ping 127.0.0.1', hints=['127.0.0.1 is "this computer".'], say='Reply OK — the network card works.'),
     cmd('gw', 'Step 2', 'Ping the gateway.', 'ws', 'ping 192.168.1.1', say='Reply OK — the LAN works.'),
     cmd('ip', 'Step 3', 'Ping an internet IP address.', 'ws', 'ping 8.8.8.8', say='Reply OK — the internet connection works!'),
     cmd('name', 'Step 4', 'Ping a website by NAME.', 'ws', 'ping google.com', say='Error: could not resolve host google.com'),
     quiz('q1', 'IP addresses work but names do not. What is broken?', ['DNS (name resolution)', 'The cable', 'The router', 'The monitor'], 0, 'DNS turns names into IP addresses; if only names fail, DNS is the problem.'),
     cmd('dns', 'Fix', 'Set a working DNS server.', 'ws', 'set dns 8.8.8.8'),
     cmd('retest', 'Verify', 'Test the website again.', 'ws', 'ping google.com', say='Reply from 142.250.x.x — fixed!'),
     ], tags=['troubleshooting', 'DNS']))

LABS.append(lab(
    'net-subnetting', 'Subnetting a School Network', 'Split 192.168.10.0/24 into four equal subnets for staff, students, Wi-Fi and servers.',
    'networking', 'ServerRoom', 4,
    ['Borrow host bits to make subnets', 'Calculate block size and usable hosts'],
    [NET_WS(['show plan', 'apply vlan staff', 'apply vlan students', 'apply vlan wifi', 'apply vlan servers'])],
    [cmd('plan', 'Plan', 'Open the network plan.', 'ws', 'show plan', say='We need 4 subnets from 192.168.10.0/24.'),
     measure('prefix', 'Calculate', 'Four subnets need 2 extra network bits. What is the new prefix length (/?)', 'prefix', 'New prefix', '/', '26', 0, hints=['24 + 2 = ?']),
     measure('block', 'Calculate', 'How many addresses are in each subnet?', 'block', 'Block size', 'addresses', '64', 0, hints=['2^(32 − 26)']),
     measure('usable', 'Calculate', 'How many usable hosts per subnet?', 'usable', 'Usable hosts', 'hosts', '62', 0, hints=['Block size − 2']),
     measure('third', 'Calculate', 'What is the last octet of the THIRD subnet\'s network address (192.168.10.?)', 'third', 'Third subnet', '', '128', 0, hints=['Subnets start at 0, 64, 128, 192.']),
     cmd('vlan', 'Deploy', 'Apply the staff VLAN.', 'ws', 'apply vlan staff'),
     ],
    results=[{'key': 'usable', 'label': 'Usable hosts per subnet', 'unit': '', 'expected': 62, 'tolerancePct': 1, 'source': 'record.usable'},
             {'key': 'third', 'label': 'Third subnet', 'unit': '', 'expected': 128, 'tolerancePct': 1, 'source': 'record.third'}],
    scoring={'accuracy': 60, 'procedure': 40, 'safety': 0}, tags=['subnetting']))

LABS.append(lab(
    'net-subnetting-challenge', 'Expert Challenge: VLSM Design', 'No hints. Size subnets for 100, 50 and 20 devices from 10.0.0.0/24 using variable-length masks.',
    'networking', 'ServerRoom', 5,
    ['Design a VLSM addressing plan'],
    [NET_WS(['show requirements', 'deploy plan'])],
    [cmd('req', 'Requirements', 'Read the requirements.', 'ws', 'show requirements', say='LAN A: 100 hosts · LAN B: 50 hosts · LAN C: 20 hosts.'),
     measure('a', 'LAN A', 'Smallest prefix for 100 hosts? (/?)', 'a', 'LAN A prefix', '/', '25', 0),
     measure('b', 'LAN B', 'Smallest prefix for 50 hosts? (/?)', 'b', 'LAN B prefix', '/', '26', 0),
     measure('c', 'LAN C', 'Smallest prefix for 20 hosts? (/?)', 'c', 'LAN C prefix', '/', '27', 0),
     measure('cstart', 'LAN C', 'LAN C starts after A (/25) and B (/26). Last octet of its network address?', 'cstart', 'LAN C network', '', '192', 0),
     cmd('deploy', 'Deploy', 'Deploy the plan.', 'ws', 'deploy plan'),
     ],
    results=[{'key': 'a', 'label': 'LAN A', 'unit': '/', 'expected': 25, 'tolerancePct': 1, 'source': 'record.a'},
             {'key': 'b', 'label': 'LAN B', 'unit': '/', 'expected': 26, 'tolerancePct': 1, 'source': 'record.b'},
             {'key': 'c', 'label': 'LAN C', 'unit': '/', 'expected': 27, 'tolerancePct': 1, 'source': 'record.c'},
             {'key': 'cstart', 'label': 'LAN C network', 'unit': '', 'expected': 192, 'tolerancePct': 1, 'source': 'record.cstart'}],
    scoring={'accuracy': 70, 'procedure': 30, 'safety': 0}, tags=['subnetting', 'exam practice']))

# ═════════════════════════════════════ CODING & AI ═══════════════════════════

DEV = lambda commands: {'id': 'ws', 'type': 'workstation', 'slot': 'desk.main', 'label': 'Python workstation', 'init': {'os': 'Python 3', 'commands': commands}}
DISPLAY = {'id': 'screen', 'type': 'wall_display', 'slot': 'wall.screen', 'label': 'Output'}

LABS.append(lab(
    'code-hello-python', 'Hello, Python!', 'Write and run your very first Python program.',
    'coding', 'CodingBench', 1,
    ['Run a Python program', 'Use print()'],
    [DEV(['print("Hello, ECH!")', 'run', 'print(2 + 3)']), DISPLAY],
    [cmd('hello', 'Your first line', 'Type a line that prints "Hello, ECH!".', 'ws', 'print("Hello, ECH!")', hints=['Select the computer, "Run a command", then the print line.'], say='print() shows text on the screen.'),
     cmd('run', 'Run it', 'Run your program.', 'ws', 'run', say='Output: Hello, ECH!'),
     cmd('maths', 'Python can calculate', 'Print 2 + 3.', 'ws', 'print(2 + 3)'),
     measure('out', 'Predict', 'What number does print(2 + 3) show?', 'out', 'Output', '', '5', 0, hints=['Python works out 2 + 3 first.']),
     quiz('q1', 'What does print("2 + 3") show (with the quotes)?', ['2 + 3', '5', 'Error', 'Nothing'], 0, 'Inside quotes it is text (a string), so it is printed exactly as written.'),
     ], results=[{'key': 'out', 'label': 'Output', 'unit': '', 'expected': 5, 'tolerancePct': 1, 'source': 'record.out'}],
    tags=['start here', 'Python'], xp=60, duration=8))

LABS.append(lab(
    'code-variables-maths', 'Variables & Maths', 'Store values in variables and predict the results of Python arithmetic, including // and %.',
    'coding', 'CodingBench', 2,
    ['Create variables', 'Use +, -, *, /, // and %'],
    [DEV(['price = 1500', 'qty = 4', 'total = price * qty', 'print(total)', 'print(17 // 5)', 'print(17 % 5)'])],
    [cmd('v1', 'Variables', 'Store the price of a notebook: price = 1500', 'ws', 'price = 1500', hints=['A variable is a named box that stores a value.']),
     cmd('v2', 'Variables', 'Store the quantity: qty = 4', 'ws', 'qty = 4'),
     cmd('v3', 'Calculate', 'Work out the total.', 'ws', 'total = price * qty'),
     measure('total', 'Predict', 'What will print(total) show (RWF)?', 'total', 'Total', 'RWF', '6000', 0, hints=['1500 × 4']),
     measure('div', 'Predict', 'What does 17 // 5 give?', 'div', '17 // 5', '', '3', 0, hints=['// is whole-number division: how many whole 5s fit in 17?']),
     measure('mod', 'Predict', 'What does 17 % 5 give?', 'mod', '17 % 5', '', '2', 0, hints=['% gives the remainder.']),
     ],
    results=[{'key': 'total', 'label': 'Total', 'unit': 'RWF', 'expected': 6000, 'tolerancePct': 1, 'source': 'record.total'},
             {'key': 'mod', 'label': '17 % 5', 'unit': '', 'expected': 2, 'tolerancePct': 1, 'source': 'record.mod'}],
    tags=['Python', 'variables']))

LABS.append(lab(
    'code-loops', 'Loops: Repeat Without Repeating Yourself', 'Use for-loops and range() to repeat actions and add up numbers.',
    'coding', 'CodingBench', 3,
    ['Use for and range()', 'Trace a loop by hand'],
    [DEV(['for i in range(5): print(i)', 'total = sum(range(1, 11))', 'print(total)'])],
    [cmd('loop', 'Your first loop', 'Run a loop that prints the numbers in range(5).', 'ws', 'for i in range(5): print(i)', hints=['range(5) gives 0, 1, 2, 3, 4.']),
     measure('last', 'Trace', 'What is the LAST number printed?', 'last', 'Last number', '', '4', 0, hints=['range stops BEFORE 5.']),
     cmd('sum', 'Add up', 'Add the numbers 1 to 10 with sum(range(1, 11)).', 'ws', 'total = sum(range(1, 11))'),
     measure('total', 'Predict', 'What is the total?', 'total', 'Sum 1..10', '', '55', 0, hints=['1 + 2 + … + 10']),
     quiz('q1', 'How many times does for i in range(3, 9) repeat?', ['6', '9', '3', '5'], 0, 'range(3, 9) gives 3, 4, 5, 6, 7, 8 → 6 values.'),
     ],
    results=[{'key': 'total', 'label': 'Sum 1..10', 'unit': '', 'expected': 55, 'tolerancePct': 1, 'source': 'record.total'}],
    tags=['Python', 'loops']))

LABS.append(lab(
    'code-ai-training', 'Train an AI Model', 'Load a dataset of student study hours and marks, train a simple model and use it to predict a result.',
    'coding', 'CodingBench', 3,
    ['Know the steps of machine learning', 'Train, evaluate and use a model'],
    [DEV(['load dataset study_hours.csv', 'split train test', 'train linear model', 'evaluate', 'predict hours=6']), DISPLAY],
    [cmd('load', 'Data', 'Load the dataset.', 'ws', 'load dataset study_hours.csv', hints=['Every model starts with data.'], say='200 students: hours studied and exam mark.'),
     cmd('split', 'Split', 'Split into training and test data.', 'ws', 'split train test', say='80% to learn from, 20% kept aside to test fairly.'),
     cmd('train', 'Train', 'Train a linear model.', 'ws', 'train linear model', say='Model learned: mark ≈ 8 × hours + 30'),
     cmd('eval', 'Evaluate', 'Evaluate the model on the test data.', 'ws', 'evaluate', say='Average error: ±6 marks.'),
     measure('pred', 'Predict', 'Using mark ≈ 8 × hours + 30, predict the mark for 6 hours of study.', 'pred', 'Predicted mark', 'marks', '78', 0, hints=['8 × 6 + 30']),
     cmd('predict', 'Check', 'Ask the model.', 'ws', 'predict hours=6'),
     quiz('q1', 'Why do we keep test data separate?', ['To check the model on data it has never seen', 'To make training faster', 'Because it is broken data', 'To save memory'], 0, 'Testing on unseen data shows whether the model really learned or just memorised.'),
     ],
    results=[{'key': 'pred', 'label': 'Prediction', 'unit': 'marks', 'expected': 78, 'tolerancePct': 1, 'source': 'record.pred'}],
    tags=['AI', 'machine learning']))

LABS.append(lab(
    'code-debugging', 'Debugging: Find the Bug', 'A program that decides PASS/FAIL is giving the wrong answer. Read the code, find the bug and fix it.',
    'coding', 'CodingBench', 4,
    ['Read error messages', 'Find and fix a logic bug', 'Test boundary values'],
    [DEV(['run grade.py', 'show code', 'fix: change > to >=', 'test mark=50', 'test mark=49'])],
    [cmd('run', 'Reproduce', 'Run the program with a mark of 50.', 'ws', 'run grade.py', say='mark = 50 → FAIL  (but 50 should PASS!)'),
     cmd('read', 'Read the code', 'Show the code.', 'ws', 'show code', say='if mark > 50: print("PASS") else: print("FAIL")', hints=['Look at the comparison operator.']),
     quiz('q1', 'Why does 50 fail?', ['> 50 is false when the mark is exactly 50', 'The mark is a string', 'print is misspelled', 'Python cannot compare numbers'], 0, '50 > 50 is False. The pass mark should be included: mark >= 50.'),
     cmd('fix', 'Fix', 'Fix the bug.', 'ws', 'fix: change > to >='),
     cmd('t50', 'Test the boundary', 'Test with 50.', 'ws', 'test mark=50', say='PASS ✓'),
     cmd('t49', 'Test the boundary', 'Test with 49.', 'ws', 'test mark=49', say='FAIL ✓'),
     ], tags=['debugging', 'Python']))

LABS.append(lab(
    'code-algorithm-challenge', 'Expert Challenge: Algorithms', 'No hints. Trace a binary search and reason about algorithm speed.',
    'coding', 'CodingBench', 5,
    ['Trace binary search', 'Compare linear and binary search'],
    [DEV(['run binary_search.py', 'show steps'])],
    [cmd('run', 'Run', 'Run binary search for 37 in a sorted list of 64 numbers.', 'ws', 'run binary_search.py'),
     measure('max', 'Reason', 'What is the MAXIMUM number of comparisons binary search needs for 64 items?', 'max', 'Max comparisons', '', '7', 0),
     measure('linear', 'Reason', 'Worst case comparisons for LINEAR search of 64 items?', 'linear', 'Linear worst case', '', '64', 0),
     cmd('steps', 'Verify', 'Show the search steps.', 'ws', 'show steps', say='Checked 32 → 48 → 40 → 36 → 38 → 37 ✓ (6 comparisons)'),
     quiz('q1', 'Binary search only works if the list is…', ['Sorted', 'Short', 'Numbers only', 'Even in length'], 0, 'Halving the search space relies on the order of the items.'),
     ],
    results=[{'key': 'max', 'label': 'Binary max', 'unit': '', 'expected': 7, 'tolerancePct': 1, 'source': 'record.max'},
             {'key': 'linear', 'label': 'Linear worst case', 'unit': '', 'expected': 64, 'tolerancePct': 1, 'source': 'record.linear'}],
    scoring={'accuracy': 60, 'procedure': 40, 'safety': 0}, tags=['algorithms', 'exam practice']))


# ─── Existing hand-written labs: add difficulty/tags ──────────────────────────

EXISTING = {
    'chem-titration-hcl-naoh': (3, ['titration']),
    'phys-ohms-law': (2, ["Ohm's law", 'circuits']),
    'phys-pendulum': (3, ['mechanics']),
    'cyber-firewall-basics': (3, ['firewalls']),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for lab_def in LABS:
        with open(os.path.join(OUT, lab_def['id'] + '.json'), 'w', encoding='utf8') as f:
            json.dump(lab_def, f, ensure_ascii=False, indent=2)
            f.write('\n')
    for id, (difficulty, tags) in EXISTING.items():
        p = os.path.join(OUT, id + '.json')
        with open(p, encoding='utf8') as f:
            d = json.load(f)
        d.update({'difficulty': difficulty, 'tags': tags, 'version': max(d.get('version', 1), VERSION)})
        with open(p, 'w', encoding='utf8') as f:
            json.dump(d, f, ensure_ascii=False, indent=2)
            f.write('\n')
    print(f'wrote {len(LABS)} activities + updated {len(EXISTING)} existing')


if __name__ == '__main__':
    main()
