%% =========================================================
%  IPV PROJECT — STEP 1: Data Validation (Single Paper)
%  Checks: Illuminance (C1), PCE (C2), Jsc mismatch (C3)
%  Reference: Khampa et al. 2026, Newton
%
%  Methodology:
%  C1: Ev = 683 * integral(E * V(lam) dlam) must equal 1000 lux ±10%
%  C2: PCE = Pmax(from JV) / E_tot(from SPD) must match reported ±10%
%  C3: Jsc_int = q*integral(EQE*Phi dlam) must match Jsc(JV) ±10%
% =========================================================
clear; clc; close all;

%% ── CHANGE ONLY THIS SECTION ─────────────────────────────
PAPER_LABEL  = 's41';
PCE_reported = 30.3;      % reported PCE (%)
Voc_reported = 0.936;     % fallback Voc if JV doesn't cross zero (V)
E_ref_uWcm2  = 306.5;     % irradiance reported in paper (uW/cm2) — reference only

spd_file = 's41_spd.csv';
eqe_file = 's41_eqe.csv';
jv_file  = 's41_jv.csv';

% SPD unit flag — set based on which axis you digitised from:
%   'uW/cm2/nm'   — most common
%   'mW/m2/nm'    — e.g. Figure S8 left axis
%   'W/m2/nm'     — already SI
%   'photon_flux' — x10^12 cm-2 s-1 nm-1
%   'photon_flux_e13' — x10^13 cm-2 s-1 nm-1
%   'photon_flux_e15' — x10^15 cm-2 s-1 nm-1
%   'au_rescale'     — arbitrary units
SPD_UNITS = 'uW/cm2/nm';   % <-- CHANGE THIS per paper
%% ────────────────────────────────────────────────────────

%% ── Constants ────────────────────────────────────────────
h    = 6.626e-34;          % Planck constant (J·s)
c    = 2.998e8;            % speed of light (m/s)
q    = 1.602e-19;          % elementary charge (C)
K_m  = 683;                % luminous efficacy constant (lm/W)
hc_Jnm = h * c * 1e9;     % h·c in J·nm = 1.9864e-25 J·nm  (used in Check 3)
TOL  = 10.0;               % acceptance threshold (%)
TARGET_LUX = 1000;         % always 1000 lx per project methodology —
                           % do NOT set this to the paper's reported value

%% ── File paths ───────────────────────────────────────────
data_folder = fileparts(mfilename('fullpath'));
f_cie = fullfile(data_folder, 'CIE_sle_photopic.csv');
f_spd = fullfile(data_folder, spd_file);
f_eqe = fullfile(data_folder, eqe_file);
f_jv  = fullfile(data_folder, jv_file);

%% ── Load CIE V(lambda) ───────────────────────────────────
% Standard photopic luminous efficiency function
% V(555 nm) = 1, falls to ~0 outside 380–780 nm
CIE    = readmatrix(f_cie);
wl_cie = CIE(:,1);   % wavelength (nm)
Vl     = CIE(:,2);   % V(lambda), dimensionless 0–1

%% ── Load & resample SPD onto 1 nm integer grid ───────────
spd_raw       = readmatrix(f_spd);
[wl_s_u, ia]  = unique(spd_raw(:,1));          % remove duplicate wavelengths
E_s_u         = max(spd_raw(ia,2), 0);         % clip negatives from digitisation noise
wl_spd        = (ceil(wl_s_u(1)) : 1 : floor(wl_s_u(end)))';
E_raw         = interp1(wl_s_u, E_s_u, wl_spd, 'linear');

%% ── Convert SPD to W/m²/nm ───────────────────────────────
switch SPD_UNITS
    case 'uW/cm2/nm'
        E_raw = E_raw / 100;
        spd_unit_note = 'uW/cm2/nm -> /100 -> W/m2/nm';

    case 'mW/m2/nm'
        E_raw = E_raw / 1000;
        spd_unit_note = 'mW/m2/nm -> /1000 -> W/m2/nm';

    case 'W/m2/nm'
        spd_unit_note = 'W/m2/nm (used directly)';

    case 'photon_flux'
        % Values digitised as 0-10 from axis labelled x10^12 cm-2 s-1 nm-1
        % Step 1: actual flux = digitised_value x 10^12 cm-2 s-1 nm-1
        % Step 2: convert cm-2 to m-2 (x 1e4)
        % Step 3: E(lambda) = Phi(lambda) * h*c / lambda[m]
        Phi_m2 = E_raw * 1e12 * 1e4;             % photons/m2/s/nm
        wl_m   = wl_spd * 1e-9;                   % nm -> m
        E_raw  = Phi_m2 .* (h * c) ./ wl_m;      % W/m2/nm
        spd_unit_note = 'Photon flux (x10^12 cm-2 s-1 nm-1) -> W/m2/nm';
       
    case 'photon_flux_e13'
        Phi_m2 = E_raw * 1e13 * 1e4;
        wl_m   = wl_spd * 1e-9;
        E_raw  = Phi_m2 .* (h * c) ./ wl_m;
        spd_unit_note = 'Photon flux (x10^13 cm-2 s-1 nm-1) -> W/m2/nm';

    case 'photon_flux_e15'
       % Digitised from axis labelled x10^15 cm-2 s-1 nm-1
       % Values on plot are 0-5, meaning actual flux = value x 10^15 cm-2 s-1 nm-1
       Phi_m2 = E_raw * 1e15 * 1e4;             % photons/m2/s/nm
       wl_m   = wl_spd * 1e-9;                   % nm -> m
       E_raw  = Phi_m2 .* (h * c) ./ wl_m;      % W/m2/nm
       spd_unit_note = 'Photon flux (x10^15 cm-2 s-1 nm-1) -> W/m2/nm';

    case 'au_rescale'
       % E_tot_raw computed in W/m2 (before *100 conversion)
       % Scale so that trapz(E_raw_scaled)*100 = E_ref_uWcm2
       E_tot_raw = trapz(wl_spd, E_raw);         % W/m2 (arbitrary scale)
       scale     = (E_ref_uWcm2 / 100) / E_tot_raw;   % target in W/m2 / raw integral
       E_raw     = E_raw * scale;                % W/m2/nm, correctly scaled
       spd_unit_note = sprintf('a.u. rescaled to E_ref = %.1f uW/cm2 -> W/m2/nm', E_ref_uWcm2);
    otherwise

        % Auto-detect fallback
        E_tot_test = trapz(wl_spd, E_raw);
        if     E_tot_test > 1000; E_raw = E_raw/1000; spd_unit_note = 'Auto: mW/m2/nm';
        elseif E_tot_test > 10;   E_raw = E_raw/100;  spd_unit_note = 'Auto: uW/cm2/nm';
        elseif E_tot_test > 0.5;                       spd_unit_note = 'Auto: W/m2/nm';
        else; warning('SPD integral tiny — check units'); spd_unit_note = 'WARNING';
        end
end
%% ── Clip wavelengths below 380 nm ────────────────────────
% Indoor LEDs have negligible emission below 380 nm.
% Clipping avoids integrating digitisation noise in the UV baseline.
mask_uv  = wl_spd >= 380;
wl_spd   = wl_spd(mask_uv);
E_raw    = E_raw(mask_uv);

%% ── Interpolate V(lambda) onto SPD wavelength grid ───────
% Must share the same axis before integration.
% Extrapolation value = 0: V(lambda) = 0 outside the visible range.
V_on_spd = interp1(wl_cie, Vl, wl_spd, 'linear', 0);

%% ── Load & resample EQE onto 1 nm integer grid ───────────
eqe_raw       = readmatrix(f_eqe);
[wl_e_u, ib]  = unique(eqe_raw(:,1));
EQE_u         = eqe_raw(ib,2);
if max(EQE_u) > 1
    EQE_u = EQE_u / 100;   % convert % to fraction if needed
end
wl_eqe   = (ceil(wl_e_u(1)) : 1 : floor(wl_e_u(end)))';
EQE_frac = interp1(wl_e_u, EQE_u, wl_eqe, 'linear');
EQE_frac = max(EQE_frac, 0);   % clip interpolation artefacts below zero

%% ── Load & clean J-V curve ───────────────────────────────
JV   = readmatrix(f_jv);
V_jv = JV(:,1);
J_jv = JV(:,2);

% ── Voltage unit check: mV → V ───────────────────────────
% If max voltage > 5, assume mV
if max(abs(V_jv)) > 5
    V_jv = V_jv / 1000;
end

% ── Sort by ascending voltage ─────────────────────────────
[V_jv, ix] = sort(V_jv);
J_jv = J_jv(ix);

% ── Keep only V >= 0 (photovoltaic quadrant) ─────────────
mask = V_jv >= 0;
V_jv = V_jv(mask);
J_jv = J_jv(mask);

% ── Remove duplicate voltage points ──────────────────────
[V_jv, ~, ic] = unique(V_jv);
J_jv = accumarray(ic, J_jv, [], @mean);

% ── Sign convention: make J positive in power quadrant ────
% Papers differ: some report J > 0, some J < 0 at V > 0.
% Correct approach: check the sign of J at mid-forward-bias voltages.
% If J is mostly negative there, flip — do NOT blindly take abs().
% (abs() would destroy the Voc zero-crossing needed for FF calculation.)
if median(J_jv(V_jv > 0.1 * max(V_jv))) < 0
    J_jv = -J_jv;
end

% ── Current unit check: mA/cm² → uA/cm² ─────────────────
% Indoor Jsc is typically 50–300 uA/cm².
% If max(J) < 5 after sign fix, it is almost certainly in mA/cm².
if max(J_jv) < 5
    J_jv = J_jv * 1000;
    jv_unit_note = 'mA/cm2 detected -> x1000 -> uA/cm2';
else
    jv_unit_note = 'uA/cm2 (used directly)';
end

%% ── Print header ─────────────────────────────────────────
fprintf('==============================================\n');
fprintf(' IPV DATA VALIDATION — %s\n', PAPER_LABEL);
fprintf('==============================================\n');
fprintf('  SPD : %s  [%.0f–%.0f nm, %d pts]\n', ...
    spd_file, wl_spd(1), wl_spd(end), numel(wl_spd));
fprintf('        Units: %s\n', spd_unit_note);
fprintf('  EQE : %s  [%.0f–%.0f nm, %d pts]\n', ...
    eqe_file, wl_eqe(1), wl_eqe(end), numel(wl_eqe));
fprintf('  JV  : %s  [%d pts]  %s\n\n', ...
    jv_file, numel(V_jv), jv_unit_note);

%% ══════════════════════════════════════════════════════════
%  CHECK 1: Illuminance Consistency
%  Ev = 683 * integral(E_lambda(W/m2/nm) * V(lambda) d_lambda)
%  Must equal TARGET_LUX (1000 lx) within ±TOL%
%% ══════════════════════════════════════════════════════════
Ev_extracted = K_m * trapz(wl_spd, E_raw .* V_on_spd);   % lux
dev_lux  = abs(Ev_extracted - TARGET_LUX) / TARGET_LUX * 100;
C1_pass  = dev_lux <= TOL;

fprintf('--- CHECK 1: Illuminance ---\n');
fprintf('  Extracted : %.1f lux\n',  Ev_extracted);
fprintf('  Target    : %.0f lux\n',  TARGET_LUX);
fprintf('  Deviation : %.2f%%  (limit ±%.0f%%)\n', dev_lux, TOL);
fprintf('  Result    : %s\n\n', pf(C1_pass));

%% ── Total irradiance (denominator for Check 2) ───────────
% Integrate E_lambda [W/m²/nm] over wavelength [nm] → E_tot [W/m²]
% Convert: 1 W/m² = 100 uW/cm²
E_tot_Wm2   = trapz(wl_spd, E_raw);      % W/m²
E_tot_uWcm2 = E_tot_Wm2 * 100;          % uW/cm²

fprintf('--- Irradiance (from extracted SPD) ---\n');
fprintf('  E_tot extracted : %.2f uW/cm2\n', E_tot_uWcm2);
fprintf('  E_ref reported  : %.2f uW/cm2\n', E_ref_uWcm2);
fprintf('  Difference      : %.1f%%\n\n', ...
    abs(E_tot_uWcm2 - E_ref_uWcm2) / E_ref_uWcm2 * 100);

%% ── J-V parameter extraction ─────────────────────────────
% Jsc: current density at V = 0
Jsc_jv = interp1(V_jv, J_jv, 0, 'linear', J_jv(1));

% Voc: find the FIRST downward zero-crossing of J(V)
% (J transitions from positive to zero as V approaches Voc)
sc = find(diff(sign(J_jv)) < 0, 1, 'first');
if ~isempty(sc)
    % Linear interpolation between the two points straddling J = 0
    Voc     = V_jv(sc) - J_jv(sc) * (V_jv(sc+1) - V_jv(sc)) / ...
                                     (J_jv(sc+1) - J_jv(sc));
    voc_src = 'zero crossing';
else
    Voc     = Voc_reported;
    voc_src = 'reported fallback (J-V did not reach J = 0)';
end

% Power density P = V * J  [V * uA/cm² = uW/cm²]
P_jv = V_jv .* J_jv;

% Maximum power point
[Pmax_jv, i_mpp] = max(P_jv);
Vmpp_jv = V_jv(i_mpp);
Jmpp_jv = J_jv(i_mpp);

% Fill factor
FF = Pmax_jv / (Jsc_jv * Voc);

% PCE: Pmax [uW/cm²] / E_tot [uW/cm²] × 100%
PCE_calc = Pmax_jv / E_tot_uWcm2 * 100;

fprintf('--- J-V Parameters ---\n');
fprintf('  Jsc  = %.3f uA/cm2\n',      Jsc_jv);
fprintf('  Voc  = %.4f V  (%s)\n',     Voc, voc_src);
fprintf('  Vmpp = %.4f V\n',           Vmpp_jv);
fprintf('  Jmpp = %.3f uA/cm2\n',      Jmpp_jv);
fprintf('  Pmax = %.3f uW/cm2\n',      Pmax_jv);
fprintf('  FF   = %.4f  (%.1f%%)\n\n', FF, FF*100);

%% ══════════════════════════════════════════════════════════
%  CHECK 2: PCE Consistency
%  Compares PCE calculated from extracted data vs reported value.
%  Both numerator (Pmax from JV) and denominator (E_tot from SPD)
%  come from digitised data — no forcing.
%% ══════════════════════════════════════════════════════════
dev_PCE = abs(PCE_calc - PCE_reported) / PCE_reported * 100;
C2_pass = dev_PCE <= TOL;

fprintf('--- CHECK 2: PCE ---\n');
fprintf('  Calculated : %.2f%%\n', PCE_calc);
fprintf('  Reported   : %.2f%%\n', PCE_reported);
fprintf('  Deviation  : %.2f%%  (limit ±%.0f%%)\n', dev_PCE, TOL);
fprintf('  Result     : %s\n\n', pf(C2_pass));

%% ══════════════════════════════════════════════════════════
%  CHECK 3: Integrated Jsc vs Measured Jsc
%
%  Formula:
%    Jsc_int = q * integral[ EQE(lambda) * Phi(lambda) d_lambda ]
%
%  where the photon flux is:
%    Phi(lambda) [photons/m²/s/nm] = E(lambda) [W/m²/nm] * lambda [nm]
%                                    / (h*c [J·nm/nm])
%                                  = E(lambda) * lambda / hc_Jnm
%
%  Integration is only over the overlap of the SPD and EQE ranges.
%  No extrapolation beyond measured data.
%
%  Unit chain:
%    q [C] * Phi [phot/m²/s/nm] * EQE [-] * d_lambda [nm]
%    = q [C] * [phot/m²/s]  →  [A/m²]  * 100  →  [uA/cm²]
%
%  The factor *100 converts A/m² to uA/cm²:
%    1 A/m² = 1 A / 10^4 cm² = 10^-4 A/cm² = 100 uA/cm²  ✓
%% ══════════════════════════════════════════════════════════

% Overlap wavelength range — no extrapolation beyond measured data
wl_lo = max(wl_spd(1),   wl_eqe(1));
wl_hi = min(wl_spd(end), wl_eqe(end));
wl_c  = (wl_lo : 1 : wl_hi)';

% Interpolate both onto the common grid; set to 0 outside measured range
E_c   = interp1(wl_spd, E_raw,    wl_c, 'linear', 0);
EQE_c = interp1(wl_eqe, EQE_frac, wl_c, 'linear', 0);
E_c   = max(E_c,   0);   % clip any interpolation noise
EQE_c = max(EQE_c, 0);

% Photon flux [photons/m²/s/nm]
% wl_c is in nm; E_c is in W/m²/nm; hc_Jnm = h*c in J·nm
% ph_flux = E_c [W/m²/nm] * wl_c [nm] / hc_Jnm [J·nm]
%         = E_c * wl_c / hc_Jnm   [photons/m²/s/nm]  ✓
ph_flux = E_c .* wl_c / hc_Jnm;

% Integrate: Jsc [A/m²] = q * integral(EQE * ph_flux d_lambda)
% Convert to uA/cm² by multiplying by 100
Jsc_int = q * trapz(wl_c, EQE_c .* ph_flux) * 100;   % uA/cm²

dev_Jsc = abs(Jsc_int - Jsc_jv) / Jsc_jv * 100;
C3_pass = dev_Jsc <= TOL;

fprintf('--- CHECK 3: Integrated Jsc ---\n');
fprintf('  Integration range : %.0f–%.0f nm\n', wl_lo, wl_hi);
fprintf('  SPD range         : %.0f–%.0f nm\n', wl_spd(1), wl_spd(end));
fprintf('  EQE range         : %.0f–%.0f nm\n', wl_eqe(1), wl_eqe(end));
fprintf('  Jsc (EQE × SPD)  : %.3f uA/cm2\n',  Jsc_int);
fprintf('  Jsc (J-V)        : %.3f uA/cm2\n',  Jsc_jv);
fprintf('  Mismatch          : %.2f%%  (limit ±%.0f%%)\n', dev_Jsc, TOL);
fprintf('  Result            : %s\n\n', pf(C3_pass));

%% ── Lambda onset 95% ─────────────────────────────────────
% The wavelength below which 95% of total irradiance is integrated.
% Key spectral descriptor per Khampa et al. 2026 (Equation 1).
cum       = cumtrapz(wl_spd, E_raw);      % cumulative irradiance
cum       = cum / cum(end);               % normalise to [0, 1]
[cum_u, ic] = unique(cum, 'stable');
lam95     = interp1(cum_u, wl_spd(ic), 0.95);   % interpolate to 95% point

fprintf('--- Spectral Descriptor ---\n');
fprintf('  lambda_onset,95%%  =  %.1f nm\n\n', lam95);

%% ── Final summary ────────────────────────────────────────
fprintf('==============================================\n');
fprintf(' SUMMARY — %s\n', PAPER_LABEL);
fprintf('==============================================\n');
fprintf('  C1 Illuminance : %.1f lux   dev=%.2f%%    %s\n', Ev_extracted, dev_lux,  pf(C1_pass));
fprintf('  C2 PCE         : calc=%.2f%%  rep=%.2f%%  %s\n', PCE_calc, PCE_reported, pf(C2_pass));
fprintf('  C3 Jsc         : mismatch=%.2f%%           %s\n', dev_Jsc,                pf(C3_pass));
fprintf('  ----------------------------------------\n');
if C1_pass && C2_pass && C3_pass
    fprintf('  OVERALL : APPROVED for locus construction\n');
else
    fprintf('  OVERALL : EXCLUDED — re-check digitised files\n');
end
fprintf('  ----------------------------------------\n');
fprintf('  Jsc   = %.3f uA/cm2\n',  Jsc_jv);
fprintf('  Voc   = %.4f V\n',       Voc);
fprintf('  FF    = %.4f  (%.1f%%)\n', FF, FF*100);
fprintf('  Pmax  = %.3f uW/cm2\n',  Pmax_jv);
fprintf('  E_tot = %.2f uW/cm2  (extracted)\n', E_tot_uWcm2);
fprintf('  E_ref = %.2f uW/cm2  (reported)\n',  E_ref_uWcm2);
fprintf('  lam95 = %.1f nm\n',      lam95);
fprintf('==============================================\n');

%% ── Figures ──────────────────────────────────────────────

% Figure 1 — CIE V(lambda)
figure('Color','w','Position',[30 610 490 320]);
plot(wl_cie, Vl, 'k-', 'LineWidth', 1.8);
xline(555, '--r', 'V_{max} 555 nm', 'LabelHorizontalAlignment','left','FontSize',9);
xlabel('Wavelength (nm)'); ylabel('V(\lambda)');
title('CIE Photopic Luminous Efficiency V(\lambda)');
xlim([360 830]); ylim([0 1.05]); grid on; box on;

% Figure 2 — Extracted SPD with lambda_onset,95%
figure('Color','w','Position',[540 610 490 320]);
plot(wl_spd, E_raw * 100, 'b-', 'LineWidth', 1.8); hold on;
xline(lam95, '--r', sprintf('\\lambda_{95} = %.0f nm', lam95), ...
    'LabelHorizontalAlignment','left','FontSize',9);
xlabel('Wavelength (nm)');
ylabel('Irradiance (\muW cm^{-2} nm^{-1})');
title(sprintf('SPD — %s', PAPER_LABEL));
text(0.05, 0.88, sprintf('E_{tot} = %.1f \\muW/cm^2  (extracted)', E_tot_uWcm2), ...
    'Units','normalized','FontSize',9,'Color','b');
text(0.05, 0.78, sprintf('E_{ref} = %.1f \\muW/cm^2  (reported)',  E_ref_uWcm2), ...
    'Units','normalized','FontSize',9,'Color',[0.5 0.5 0.5]);
xlim([wl_spd(1)-10  wl_spd(end)+10]); grid on; box on;

%% ── Figure 3 — EQE + Cumulative Integrated Jsc (Khampa style) ───────────

% Build cumulative integrated Jsc over the EQE wavelength range
% We need SPD interpolated onto EQE grid for this
wl_eqe_full = wl_eqe;   % already 1 nm grid

% Overlap with SPD
wl_lo_fig = max(wl_spd(1), wl_eqe_full(1));
wl_hi_fig = min(wl_spd(end), wl_eqe_full(end));
wl_cum    = (wl_lo_fig : 1 : wl_hi_fig)';

E_cum   = interp1(wl_spd,     E_raw,    wl_cum, 'linear', 0);
EQE_cum = interp1(wl_eqe_full, EQE_frac, wl_cum, 'linear', 0);
E_cum   = max(E_cum,   0);
EQE_cum = max(EQE_cum, 0);

% Photon flux on the common grid
ph_flux_cum = E_cum .* wl_cum / hc_Jnm;   % photons/m2/s/nm

% Cumulative Jsc: integrate from wl_lo up to each wavelength
Jsc_cumulative = zeros(size(wl_cum));
for k = 2 : numel(wl_cum)
    Jsc_cumulative(k) = q * trapz(wl_cum(1:k), EQE_cum(1:k) .* ph_flux_cum(1:k)) * 100;
end
Jsc_total_fig = Jsc_cumulative(end);   % should match Jsc_int

% ── Plot ─────────────────────────────────────────────────
figure('Color','w','Position',[30 230 520 360]);

yyaxis left
plot(wl_eqe_full, EQE_frac * 100, 'k-', 'LineWidth', 2.0);
ylabel('EQE (%)');
ylim([0 110]);
yticks(0:20:100);

yyaxis right
plot(wl_cum, Jsc_cumulative, 'r-', 'LineWidth', 2.0);
ylabel('Integrated J_{sc} (\muA cm^{-2})');
ylim([0  Jsc_total_fig * 1.15]);

% Annotation: final integrated Jsc value (mimics Khampa label)
text(0.55, 0.55, ...
    sprintf('%.1f \\muA cm^{-2}', Jsc_total_fig), ...
    'Units','normalized','FontSize',11,'Color','r', ...
    'FontWeight','bold');

xlabel('Wavelength (nm)');
title(sprintf('EQE & Integrated J_{sc} — %s', PAPER_LABEL));
xlim([min(wl_eqe_full)-10  max(wl_eqe_full)+10]);

% Style both axes consistently
ax = gca;
ax.YAxis(1).Color = 'k';   % left axis black
ax.YAxis(2).Color = 'r';   % right axis red
grid on; box on;
legend({'EQE', 'Integrated J_{sc}'}, 'Location','northwest','FontSize',9);

% Figure 4 — J-V curve + power density
figure('Color','w','Position',[540 230 490 320]);
yyaxis left
plot(V_jv, J_jv, 'b-o', 'LineWidth', 1.8, 'MarkerSize', 4);
ylabel('J (\muA cm^{-2})'); ylim([0 max(J_jv)*1.15]);
yyaxis right
plot(V_jv, P_jv, 'r--', 'LineWidth', 1.5); hold on;
plot(Vmpp_jv, Pmax_jv, 'rs', 'MarkerSize', 10, 'MarkerFaceColor','r');
ylabel('P (\muW cm^{-2})');
xlabel('Voltage (V)');
title(sprintf('J-V — %s  |  PCE = %.2f%% (calc)  %.2f%% (rep)', ...
    PAPER_LABEL, PCE_calc, PCE_reported));
text(0.04, 0.35, ...
    sprintf('J_{sc}=%.1f \\muA/cm^2\nV_{oc}=%.3f V\nFF=%.3f\nPCE=%.1f%%', ...
    Jsc_jv, Voc, FF, PCE_calc), ...
    'Units','normalized','FontSize',9,'BackgroundColor','w','EdgeColor','k');
grid on; box on;

% Figure 5 — Illuminance integrand (Check 1 visual)
figure('Color','w','Position',[1060 610 490 320]);
area(wl_spd, K_m * E_raw .* V_on_spd, ...
    'FaceColor',[1 0.85 0.2],'EdgeColor','k','LineWidth',1.2);
xlabel('Wavelength (nm)');
ylabel('683 \cdot E_\lambda \cdot V(\lambda)  (lux nm^{-1})');
title(sprintf('Illuminance Integrand [C1] — %s', PAPER_LABEL));
text(0.55, 0.85, sprintf('E_v = %.0f lux', Ev_extracted), ...
    'Units','normalized','FontSize',10,'BackgroundColor','w','EdgeColor','k');
xlim([wl_spd(1)-10  wl_spd(end)+10]); grid on; box on;

% Figure 6 — Jsc integrand (Check 3 visual)
figure('Color','w','Position',[1060 230 490 320]);
integrand_c3 = q * EQE_c .* ph_flux * 100;   % uA/cm²/nm  (same factor as Jsc_int)
area(wl_c, integrand_c3, ...
    'FaceColor',[0.2 0.7 0.3],'EdgeColor','k','LineWidth',1.0);
xlabel('Wavelength (nm)');
ylabel('J_{sc} contribution (\muA cm^{-2} nm^{-1})');
title(sprintf('Jsc Integrand [C3] — %s', PAPER_LABEL));
text(0.05, 0.88, ...
    sprintf('J_{sc,int}=%.1f   J_{sc,JV}=%.1f   mismatch=%.1f%%', ...
    Jsc_int, Jsc_jv, dev_Jsc), ...
    'Units','normalized','FontSize',9,'Color',[0.1 0.5 0.1]);
xlim([wl_c(1)-10  wl_c(end)+10]); grid on; box on;

%% ── Helper function ──────────────────────────────────────
function s = pf(pass)
    if pass; s = 'PASS'; else; s = 'FAIL'; end
end