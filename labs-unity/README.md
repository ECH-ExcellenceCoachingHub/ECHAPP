# ECH Labs: 3D/VR virtual laboratories (Unity 6)

ECH Labs is a set of interactive science and tech experiments. Each one runs in four modes:

- desktop (mouse and keyboard)
- touch (phone or tablet)
- a phone VR viewer (Cardboard-style headset)
- a native VR headset (Meta Quest, Pico or PC VR through OpenXR)

All four modes use the same rooms, the same science and the same lesson content.

```
backend/src/services/labs/      ← single source of truth: catalog.json, scenario DSL validator, science (sim.js), scoring
labs-unity/
  Assets/ECHLabs/Sim/           ← pure C# science (titration pH, circuits/MNA, pendulum, microscope)  [no UnityEngine]
  Assets/ECHLabs/Core/          ← expression language, LabWorld (equipment state + behaviour), ScenarioRuntime, Scoring  [no UnityEngine]
  Assets/ECHLabs/Runtime/       ← Unity: LabSession, rigs (Desktop/Touch/Stereo/XR), views, HUD (UI Toolkit), Net, Bridge, Quality
  Assets/ECHLabs/Editor/        ← automation: ProjectSetup, PrefabFactory, SceneBuilder, LightingBaker, ScreenshotQA, BuildCli
  Assets/ECHLabs/Rendering/     ← shaders (Liquid, HudSurface, Reticle), URP tiers, post FX
  Layouts/*.json                ← room layouts the SceneBuilder turns into scenes
  DotnetTests/                  ← headless tests of Sim + Core (`dotnet test`), incl. a bot student playing each lab
```

## How a lab runs

1. The Flutter app calls `POST /api/labs/session`.
   - The backend returns a short-lived **lab token**. It is signed with a separate secret, so it can't be used as an account login.
2. The app launches the Unity engine for the device:

   | Device | How the lab opens |
   |---|---|
   | Web | Iframe (`#token=…` in the URL fragment) |
   | Windows | `labs/ECHLabs.exe --token=…` |
   | Android / iOS | Embedded Unity library (next phase; until then the WebGL lab opens in the browser) |
   | Headset | 6-digit pairing code |

3. `LabSession` downloads the scenario JSON, loads the room scene and spawns equipment at the room's `SlotAnchor`s.
4. Every input becomes an **Intent** (`Pour naoh → burette1`, `Rotate burette1 = 0.08`…):

   | Mode | What counts as "select" |
   |---|---|
   | Desktop | Mouse click |
   | Touch | Tap |
   | Phone VR viewer | 1.2 s gaze dwell, or the viewer button |
   | VR headset | Controller trigger |

5. Intents go to `ScenarioRuntime`, which:
   - applies them to `LabWorld` (sandbox physics and chemistry)
   - judges them against the current step
   - checks hazards
   - logs everything for the lab notebook
6. Progress autosaves every 15 s and goes through an offline queue on disk.
7. On completion, the backend recomputes the score, then:
   - awards XP and badges once (on the first pass)
   - marks the lesson complete in `Enrollment`

## Building everything (no manual Editor work)

You need Unity **6000.6.8f1** with these modules: Android (with SDK, NDK and OpenJDK), Windows IL2CPP, and Web. Sign Unity Hub into your Unity ID once.

```powershell
.\tools\labs\build-labs.ps1            # compile → configure → CC0 textures → prefabs → scenes → bake → QA renders
.\tools\labs\build-labs.ps1 -Step qa   # re-render QA screenshots (labs-unity/QA/*.png)
.\tools\labs\build-labs.ps1 -Step windows|webgl|android|quest|ios
.\tools\labs\build-labs.ps1 -Step test
```

Each step is an `-executeMethod` entry point:

- **`ProjectSetup.Run`**: sets up the project.
  - URP Low/Medium/Ultra tiers, with SSAO on Medium and Ultra
  - post-processing profile and layers
  - player settings for every platform
  - XR loaders: OpenXR and Cardboard, never started at launch
  - TMP resources
  - copies the backend catalog and the built-in scenarios
- **`PrefabFactory.BuildAll`**: builds all 30 equipment types from code.
  - Glassware is lathe-revolved at real dimensions, with an exact volume-to-height curve for the liquid.
  - Instruments are bevelled, with displays, knobs, particles and colliders.
- **`SceneBuilder.BuildAll`**: builds `Bootstrap.unity` (session, rigs, HUD) and one scene per `Layouts/*.json`.
  - architecture, benches, fume hood, sink, PPE station, windows
  - LED panels with baked area lights
  - probes, slot anchors, spawn point and QA shots
- **`LightingBaker.BakeAll`**: bakes lighting (GPU progressive lightmapper, falling back to CPU).
- **`ScreenshotQA.Run`**: places a real scenario mid-experiment and renders every QA shot.

## Adding a new experiment

Usually you don't need Unity at all:

1. Write a scenario JSON. Use the existing files in `backend/src/services/labs/scenarios/` as models, or let the AI builder draft it with `POST /api/labs/scenarios/generate {lessonId}`.
2. Validate it with `POST /api/labs/scenarios/validate`. The validator checks:
   - rooms, slots and equipment types
   - which intents each equipment supports
   - every expression
   - the step order
   - the science: expected results are recomputed with `sim.js`
3. Publish it: `POST /api/labs/scenarios/:id/status {status:'published'}` (admin only).
4. Attach it to a lesson: `PUT /api/labs/lessons/:lessonId/lab {scenarioId, required}`.

Only a **new kind of equipment** or a **new room** needs code. In that case, add:

- the catalog entry
- an `IEquipmentLogic` in `Core/EquipmentLogics.cs`, with tests
- a view in `Runtime/Equipment`
- a builder in `PrefabFactory`, or a layout JSON for a room

## Tests

- **End-to-end autoplay in a real player build:**
  `Builds\Windows\ECHLabs.exe --scenario=<id> --autoplay=<folder>`
  - A bot student plays every step through the real runtime and HUD.
  - It saves a screenshot per step plus `summary.txt` (score, hazards, fps), then quits.
  - Real mouse and keyboard input is ignored, and saved progress is cleared first.

- `dotnet test labs-unity/DotnetTests`: the C# science and runtime. A bot student completes the titration, Ohm's law and pendulum labs and gets the expected scores.
- `cd backend && node --test test/labs.test.js`: the expression language, the science golden values (the same numbers as the C# tests), the validator, scoring, token isolation, the AI repair loop, the HTTP flow and headset pairing.
