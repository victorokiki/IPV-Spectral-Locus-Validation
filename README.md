# IPV Spectral Locus Validation

MATLAB implementation of the three-step IPV benchmarking pipeline based on 
the spectral projection and PCE-λonset,95% locus construction framework 
introduced by Khampa et al. (2026, Newton).

## Pipeline Overview

| Step | Script | What It Does |
|------|--------|-------------|
| Step 1 | `ipv_validation.m` | Validates digitised SPD, EQE, and J-V data against three internal consistency checks. Produces Jsc, Voc, FF, PCE, and λonset,95%. Papers that pass all three checks are APPROVED. |
| Step 2 | `spectral_projection_locus.m` | Projects each approved device's J-V curve onto four corner reference LEDs. Produces the PCE-λonset,95% locus quadrilateral. |
| Step 3 | `combined_locus_final.m` | Overlays all approved device loci on a single figure. Performs pairwise dominance analysis across technologies. |

## The Three Validation Checks (Step 1)

- **C1 — Illuminance:** Extracted SPD must yield 1000 lux ± 10%
- **C2 — PCE:** Calculated PCE must match reported PCE ± 10%
- **C3 — Jsc:** EQE × photon flux integral must match J-V Jsc ± 10%

Only papers that pass all three checks proceed to Step 2.

## File Requirements

| File | Description |
|------|-------------|
| `ipv_validation.m` | Step 1 — Data validation |
| `spectral_projection_locus.m` | Step 2 — Spectral projection & locus |
| `combined_locus_final.m` | Step 3 — Combined locus comparison |
| `CIE_sle_photopic.csv` | CIE V(λ) photopic luminous efficiency function |
| `LED_spectra.csv` | 4 corner reference LED spectra (Ref1–Ref4) |
| `*_spd.csv` | Digitised SPD per paper |
| `*_eqe.csv` | Digitised EQE per paper |
| `*_jv.csv` | Digitised J-V per paper |

## Corner Reference LEDs

| Reference | λonset,95% | Description |
|-----------|-----------|-------------|
| Ref 4 | 644 nm | 5700K standard phosphor LED |
| Ref 3 | 660 nm | 3000K full-spectrum LED |
| Ref 2 | 702 nm | 5700K full-spectrum LED |
| Ref 1 | 721 nm | 3000K KSF phosphor LED |

## Devices Validated

| Device | Paper | Technology | Bandgap |
|--------|-------|------------|---------|
| Device A | S3 Chen 2025 | Perovskite | 1.67 eV |
| Device B | S4 Wen 2025 | Perovskite | 1.79 eV |
| Device C | S5 Liu 2024 | Perovskite | 1.56 eV |
| Device D | S8 Li 2024 | Perovskite | 1.52 eV |
| Device E | S12 Wang 2024 | OPV | 1.74 eV |
| Device F | S15 Lu 2024 | Inorganic Se | 1.90 eV |

## How to Run

1. Place all CSV files in the same folder as the `.m` scripts
2. Open `ipv_validation.m` — set paper-specific variables at the top
   (SPD file, EQE file, JV file, reported PCE, SPD units)
3. Run Step 1 — all 3 checks must PASS before proceeding
4. Open `spectral_projection_locus.m` — set the same variables
5. Run Step 2 — generates the 4-panel locus figure
6. Copy the LOCUS COORDINATES from the Step 2 console output
7. Paste into `combined_locus_final.m` device data section
8. Run Step 3 — generates the combined cross-technology comparison

## SPD Unit Flags

| Flag | When to Use |
|------|------------|
| `'uW/cm2/nm'` | Most common — axis labelled µW cm⁻² nm⁻¹ |
| `'mW/m2/nm'` | Axis labelled mW m⁻² nm⁻¹ |
| `'W/m2/nm'` | Already in SI units |
| `'photon_flux'` | Axis labelled ×10¹² cm⁻² s⁻¹ nm⁻¹ |
| `'photon_flux_e13'` | Axis labelled ×10¹³ cm⁻² s⁻¹ nm⁻¹ |
| `'photon_flux_e15'` | Axis labelled ×10¹⁵ cm⁻² s⁻¹ nm⁻¹ |
| `'au_rescale'` | Arbitrary units — requires E_ref_uWcm2 |

## Requirements

- MATLAB R2020a or later
- No additional toolboxes required
- Data digitised using [WebPlotDigitizer](https://automeris.io/WebPlotDigitizer/)

## Acknowledgements

This code implements the framework from:

> Khampa, W., Le, L., Passatorntaschakorn, W., Loftus, J., Jailani, J.M.,
> Sandoval Giron, F., Wongratanaphisan, D., Patel, C., & Pecunia, V.
> "A universal design and benchmarking framework for indoor photovoltaics"
> *Newton*, 2026. DOI: 10.1016/j.newton.2026.100437

All credit for the methodology belongs to the authors above.
This repository contains independent MATLAB validation code developed
as a course project (SEE 894, Simon Fraser University, Spring 2026).
