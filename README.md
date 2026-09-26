# Nonlinear PWM Buck Converter Simulator

A MATLAB toolkit for simulating, analyzing, and visualizing the nonlinear
dynamics of a PWM-controlled buck converter. It includes a cycle-by-cycle
switching model, Poincaré-map based bifurcation analysis, Lyapunov exponent
estimation, two-parameter stability maps, and an interactive GUI.

## Features

- **Cycle-accurate simulation** of a closed-loop, current/voltage-mode buck
  converter, including inductor DCR, diode drop, and ramp-based PWM.
- **Steady-state theory** (ideal duty cycle, ripple, critical inductance,
  lossy/closed-loop operating point) for validating the simulation.
- **Bifurcation sweeps** over any single parameter (e.g. `Kp`, `Vin`),
  classifying the resulting orbit (period-1, period-n, chaotic) and
  optionally estimating the largest Lyapunov exponent (LLE).
- **Two-parameter stability maps** over a grid of two parameters.
- **Verification** against ideal/lossy theoretical predictions.
- **Plotting utilities** for time-domain response and phase-portrait
  animation.
- **Interactive GUI** (`BuckConverter_GUI.m`) for changing parameters and
  running simulations/sweeps without touching code.

## File structure

| File                    | Purpose                                             |
|-------------------------|------------------------------------------------------|
| `buckParameters.m`      | Default parameters, validation, and parameter setter |
| `buckTheory.m`          | Closed-form steady-state predictions                 |
| `buckSimulate.m`        | Cycle-by-cycle ODE-based switching simulation        |
| `buckAnalyze.m`         | Poincaré section, orbit classification, LLE          |
| `buckSweep.m`           | One-parameter bifurcation sweep                      |
| `buckStabilityMap.m`    | Two-parameter stability/operating-regime map          |
| `buckVerify.m`          | Compares simulated vs. theoretical performance       |
| `buckPlotResults.m`     | Time-domain plots and phase-plane animation          |
| `buckConverterMain.m`   | Scripted end-to-end study (nominal run + sweeps)      |
| `BuckConverter_GUI.m`   | Interactive GUI front-end                             |

## Requirements

- MATLAB R2016a or later (uses `uifigure`/`uigridlayout` for the GUI, so the
  GUI itself needs a version that supports App Designer-style UI components;
  the simulation/analysis functions are compatible with older releases).
- Parallel Computing Toolbox is optional but used by `buckStabilityMap.m`
  (`parfor`) if available.

## Usage

**Scripted study:**
```matlab
results = buckConverterMain;
```

**Interactive GUI:**
```matlab
BuckConverter_GUI
```

**Programmatic example:**
```matlab
p  = buckParameters('defaults');
x0 = [p.Vref/p.R; p.Vref];
sim = buckSimulate('run', p, x0, 700);
analysis = buckAnalyze(p, sim);
theory = buckTheory(p);
verification = buckVerify(p, sim);
```

## License

This project is licensed under the MIT License
code) — see `LICENSE`.
