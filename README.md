# IPV Spectral Locus Validation

MATLAB implementation of the spectral projection and PCE-λonset,95% locus 
construction framework for indoor photovoltaics (IPV), developed as a 
course project at Simon Fraser University.

## What This Does

This code validates and reproduces the spectral locus benchmarking 
framework introduced by Khampa et al. (2026). Given digitised SPD, EQE, 
and J-V data from a published IPV paper, it:

**Step 1 — Data Validation** (`step1_validation.m`)
- C1: Illuminance consistency (must equal 1000 lux ±10%)
- C2: PCE consistency (calculated vs reported ±10%)
- C3: Integrated Jsc vs measured Jsc (±10%)

**Step 2 — Spectral Projection** (`step2_locus.m`)
- Projects the measured J-V curve onto 4 corner reference LEDs
- (5700K/3000K × 644/660/702/720 nm)
- Constructs the PCE-λonset,95% locus quadrilateral

## How to Run

1. Place all CSV files in the same folder as the `.m` files
2. Open `step1_validation.m` and set the paper-specific variables 
   at the top (SPD file, EQE file, JV file, reported PCE, SPD units)
3. Run Step 1 — all 3 checks must pass before proceeding
4. Open `step2_locus.m` and set the same paper-specific variables
5. Run Step 2 — generates the 4-panel figure set including the locus

## Files

| File | Description |
|------|-------------|
| `step1_validation.m` | Data validation (Checks 1–3) |
| `step2_locus.m` | Spectral projection & locus construction |
| `CIE_sle_photopic.csv` | CIE V(λ) photopic luminous efficiency function |
| `LED_spectra.csv` | 4 corner reference LED spectra |
| `*_spd.csv` | Digitised SPD data per paper |
| `*_eqe.csv` | Digitised EQE data per paper |
| `*_jv.csv` | Digitised J-V data per paper |

## Requirements

- MATLAB R2020a or later
- No additional toolboxes required

## Acknowledgements

This code implements the framework from:

> Khampa, W., Le, L., Passatorntaschakorn, W., Loftus, J., Jailani, J.M.,
> Sandoval Giron, F., Wongratanaphisan, D., Patel, C., & Pecunia, V.
> "A universal design and benchmarking framework for indoor photovoltaics"
> *Newton*, 2026. DOI: 10.1016/j.newton.2026.100437

All credit for the methodology belongs to the authors above.
This repository contains independent MATLAB validation code developed 
as a course project.
