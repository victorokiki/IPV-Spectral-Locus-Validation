%% =========================================================
%  IPV PROJECT — STEP 2: Spectral Projection & Locus Construction
%  ---------------------------------------------------------
%  TO RUN FOR A DIFFERENT PAPER: change ONLY the lines
%  marked  <-- CHANGE THIS
%
%  Implements spectral projection (Note S8, Khampa et al. 2026):
%    J_t(V) = J_s(V) + integral[ R(lambda)*(E_s - E_t) d_lambda ]
%    R(lambda) = EQE(lambda) * q * lambda[m] / (h*c)   [A/W]
%
%  Equal-illuminance condition:
%    Corner spectra are rescaled so their TOTAL IRRADIANCE equals
%    the source total irradiance.
%    Scaling to equal lux is wrong — full-spectrum LEDs require much
%    more total irradiance than KSF LEDs to reach the same lux value,
%    which produces large spurious delta_JL values.
%
%  Corner LED column order in LED_spectra.csv:
%    Col 2 — 5700K (644nm)  [Ref 4]
%    Col 3 — 3000K (660nm)  [Ref 3]
%    Col 4 — 5700K (702nm)  [Ref 2]
%    Col 5 — 3000K (720nm)  [Ref 1]
% =========================================================
clear; clc; close all;

%% ── 0. CHANGE THESE LINES FOR EACH PAPER ────────────────
paper_label = 's41';          % <-- CHANGE THIS
paper_info  = 's5';  % <-- CHANGE THIS

data_folder = fileparts(mfilename('fullpath'));
f_cie = fullfile(data_folder, 'CIE_sle_photopic.csv');
f_led = fullfile(data_folder, 'LED_spectra.csv');

f_spd = fullfile(data_folder, 's41_spd.csv');   % <-- CHANGE THIS
f_eqe = fullfile(data_folder, 's41_eqe.csv');   % <-- CHANGE THIS
f_jv  = fullfile(data_folder, 's41_jv.csv');    % <-- CHANGE THIS

% SPD unit flag — must match what you used in Step 1 for this paper
%   'uW/cm2/nm'       — most common
%   'mW/m2/nm'        — e.g. Figure S8 left axis
%   'W/m2/nm'         — already SI
%   'photon_flux'     — x10^12 cm-2 s-1 nm-1
%   'photon_flux_e13' — x10^13 cm-2 s-1 nm-1
%   'photon_flux_e15' — x10^15 cm-2 s-1 nm-1
%   'au_rescale'      — arbitrary units (requires E_ref_uWcm2)
SPD_UNITS    = 'uW/cm2/nm';   % <-- CHANGE THIS per paper
E_ref_uWcm2  = 98;        % <-- only needed for au_rescale
locus_color = [0.89 0.47 0.20];   % <-- CHANGE THIS (colour for this technology)
%   OPV        = [0.89 0.47 0.20]  orange
%   Perovskite = [0.12 0.47 0.71]  blue
%   DSSC       = [0.17 0.63 0.17]  green
%   a-Si:H     = [0.58 0.40 0.74]  purple
%   Se         = [0.84 0.15 0.16]  red
%% ─────────────────────────────────────────────────────────

%% ── 1. Physical constants ─────────────────────────────────
h_p = 6.626e-34;   % J·s
c_l = 3.000e8;     % m/s
q   = 1.602e-19;   % C

%% ── 2. Load CIE V(lambda) ────────────────────────────────
CIE    = readmatrix(f_cie);
wl_cie = CIE(:,1);
Vl     = CIE(:,2);

%% ── 3. Load and prepare source SPD ──────────────────────
SPD_raw      = readmatrix(f_spd);
[wl_s_u, ia] = unique(SPD_raw(:,1));
E_s_u        = max(SPD_raw(ia,2), 0);
wl_spd       = (ceil(wl_s_u(1)) : 1 : floor(wl_s_u(end)))';
E_s          = max(interp1(wl_s_u, E_s_u, wl_spd, 'linear'), 0);

switch SPD_UNITS
    case 'uW/cm2/nm'
        E_s = E_s / 100;
    case 'mW/m2/nm'
        E_s = E_s / 1000;
    case 'W/m2/nm'
        % no change
    case 'photon_flux'
        wl_m = wl_spd * 1e-9;
        E_s  = (E_s * 1e12 * 1e4) .* (h_p * c_l) ./ wl_m;
    case 'photon_flux_e13'
        wl_m = wl_spd * 1e-9;
        E_s  = (E_s * 1e13 * 1e4) .* (h_p * c_l) ./ wl_m;
    case 'photon_flux_e15'
        wl_m = wl_spd * 1e-9;
        E_s  = (E_s * 1e15 * 1e4) .* (h_p * c_l) ./ wl_m;
    case 'au_rescale'
        E_tot_raw = trapz(wl_spd, E_s);
        scale     = (E_ref_uWcm2 / 100) / E_tot_raw;
        E_s       = E_s * scale;
    otherwise
        % auto-detect fallback
        if trapz(wl_spd, E_s) > 10
            E_s = E_s / 100;
        end
end

wl_spd = wl_spd(wl_spd >= 380);
E_s    = E_s(end-numel(wl_spd)+1:end);
Etot_s = trapz(wl_spd, E_s) * 100;
l95_s  = lambda_onset_95(wl_spd, E_s);

%% ── 4. Load and prepare EQE ──────────────────────────────
EQE_raw      = readmatrix(f_eqe);
[wl_e_u, ib] = unique(EQE_raw(:,1));
EQE_u        = EQE_raw(ib,2);
if max(EQE_u) > 1, EQE_u = EQE_u / 100; end
wl_eqe       = (ceil(wl_e_u(1)) : 1 : floor(wl_e_u(end)))';
EQE_frac     = max(interp1(wl_e_u, EQE_u, wl_eqe, 'linear'), 0);

%% ── 5. Load and prepare J-V curve ────────────────────────
JV_raw  = readmatrix(f_jv);
V_s     = JV_raw(:,1);
J_s     = JV_raw(:,2);
if max(abs(V_s)) > 5, V_s = V_s / 1000; end   % mV -> V
[V_s, ix] = sort(V_s);
J_s = J_s(ix);
V_s = V_s(V_s >= 0);
J_s = J_s(1:numel(V_s));
% ── Remove duplicate voltage points ──────────────────────
[V_s, ia] = unique(V_s, 'stable');
J_s = J_s(ia);
% Sign fix: ensure J is positive in power-generating quadrant
% (some papers report J < 0 in 4th-quadrant convention)
if median(J_s(V_s > 0.1*max(V_s))) < 0
    J_s = -J_s;
end
if max(J_s) < 5, J_s = J_s * 1000; end   % mA/cm2 -> uA/cm2
%% ── 6. Load corner LED spectra ───────────────────────────
LED_raw      = readmatrix(f_led);
wl_led       = LED_raw(:,1);
LED_cols     = LED_raw(:, 2:5);
corner_names = {'5700K (644nm)', '3000K (660nm)', '5700K (702nm)', '3000K (720nm)'};
corner_refs  = {'Ref4', 'Ref3', 'Ref2', 'Ref1'};
%% ── 7. Spectral responsivity R(lambda) [A/W] ─────────────
wl_m_eqe = wl_eqe * 1e-9;
R_eqe    = EQE_frac .* (q .* wl_m_eqe) ./ (h_p .* c_l);

%% ── 8. Common wavelength grid ────────────────────────────
wl_min = min([wl_spd(1),   wl_led(1),   wl_eqe(1)]);
wl_max = max([wl_spd(end), wl_led(end), wl_eqe(end)]);
wl_c   = (wl_min : 1 : wl_max)';
E_s_c  = max(interp1(wl_spd, E_s,   wl_c, 'linear', 0), 0);
R_c    = max(interp1(wl_eqe, R_eqe, wl_c, 'linear', 0), 0);

%% ── 9. Print header ──────────────────────────────────────
fprintf('==============================================\n');
fprintf(' SPECTRAL PROJECTION — %s\n', paper_label);
fprintf('==============================================\n');
fprintf('Source SPD (as measured):\n');
fprintf('  lambda_onset,95%% = %.1f nm\n', l95_s);
fprintf('  E_tot            = %.2f uW/cm2\n', Etot_s);
Jsc_eqe = trapz(wl_c, R_c .* E_s_c) * 100;
Jsc_jv  = interp1(V_s, J_s, 0, 'linear', J_s(1));
fprintf('\nJsc from EQE x SPD : %.3f uA/cm2\n', Jsc_eqe);
fprintf('Jsc from J-V        : %.3f uA/cm2\n', Jsc_jv);
fprintf('Delta_Jsc           : %.2f%%\n\n', abs(Jsc_eqe-Jsc_jv)/Jsc_jv*100);
fprintf('%-6s  %-16s  %9s  %10s  %+10s  %10s  %8s\n', ...
    'Ref','LED','l95 (nm)','E_tot','delta_JL','Jsc_proj','PCE');
fprintf('%s\n', repmat('-',1,80));

%% ── 10. Spectral projection onto 4 corner LEDs ───────────
PCE_c  = zeros(1,4);
l95_c  = zeros(1,4);
Etot_c = zeros(1,4);
dJL_c  = zeros(1,4);
J_proj = zeros(length(V_s), 4);

for k = 1:4
    E_t_raw  = max(LED_cols(:,k), 0);
    % Scale corner to match source total irradiance (equal-illuminance)
    Etot_raw = trapz(wl_led, E_t_raw) * 100;
    scale    = Etot_s / Etot_raw;
    E_t      = E_t_raw * scale;

    E_t_c  = max(interp1(wl_led, E_t, wl_c, 'linear', 0), 0);
    Etot_t = trapz(wl_c, E_t_c) * 100;
    l95_t  = lambda_onset_95(wl_c, E_t_c);

    % Spectral projection (Eq.14 adapted for positive-J convention)
    % Paper uses J<0 convention; code uses J>0 (flipped). Flipping J
    % requires flipping the shift sign: (E_t - E_s) so that more
    % target photons -> positive delta_JL -> higher projected current.
    delta_JL = trapz(wl_c, R_c .* (E_t_c - E_s_c)) * 100;   % uA/cm2
    J_t      = J_s + delta_JL;

    P_t   = V_s .* J_t;
    PCE_t = max(P_t) / Etot_t * 100;

    PCE_c(k)    = PCE_t;
    l95_c(k)    = l95_t;
    Etot_c(k)   = Etot_t;
    dJL_c(k)    = delta_JL;
    J_proj(:,k) = J_t;

    Jsc_proj = interp1(V_s, J_t, 0, 'linear', J_t(1));
    fprintf('%-6s  %-16s  %9.1f  %10.2f  %+10.4f  %10.3f  %8.2f%%\n', ...
        corner_refs{k}, corner_names{k}, l95_t, Etot_t, delta_JL, Jsc_proj, PCE_t);
end

%% ── 11. Summary ──────────────────────────────────────────
PCE_source = max(V_s .* J_s) / Etot_s * 100;
fprintf('\n==============================================\n');
fprintf(' LOCUS COORDINATES — %s\n', paper_label);
fprintf('==============================================\n');
for k = 1:4
    fprintf('  %s  %-16s  (%.1f nm,  %.2f%%)\n', ...
        corner_refs{k}, corner_names{k}, l95_c(k), PCE_c(k));
end
fprintf('\n  Source (meas.)    (%.1f nm,  %.2f%%)\n', l95_s, PCE_source);
fprintf('\nPCE range : %.2f%% - %.2f%%  (spread = %.2f%%)\n', ...
    min(PCE_c), max(PCE_c), max(PCE_c)-min(PCE_c));
fprintf('lambda95  : %.1f - %.1f nm\n', min(l95_c), max(l95_c));
fprintf('==============================================\n');

%% ── 12. Figures ──────────────────────────────────────────
clr = {'#d62728','#2ca02c','#ff7f0e','#1f77b4'};
mrk = {'o','^','s','d'};

% Figure 1 — Corner LED spectra
figure('Color','w','Position',[50 570 620 370]); hold on;
for k = 1:4
    E_t_raw  = max(LED_cols(:,k), 0);
    E_t_plot = E_t_raw * (Etot_s / (trapz(wl_led, E_t_raw)*100));
    plot(wl_led, E_t_plot*100, 'LineWidth',1.6, 'Color',clr{k}, ...
        'DisplayName', sprintf('%s %s (\\lambda_{95}=%.0f nm)', ...
        corner_refs{k}, corner_names{k}, l95_c(k)));
end
plot(wl_spd, E_s*100, 'k--', 'LineWidth',1.4, ...
    'DisplayName', sprintf('Source SPD (\\lambda_{95}=%.0f nm)', l95_s));
xlabel('Wavelength (nm)','FontSize',12);
ylabel('Spectral Irradiance (\muW cm^{-2} nm^{-1})','FontSize',12);
title('Corner Reference LEDs (rescaled to equal irradiance)','FontSize',12);
legend('Location','northwest','FontSize',9);
xlim([380 820]); grid on; box on;

% Figure 2 — EQE and R(lambda)
figure('Color','w','Position',[690 570 600 370]);
yyaxis left
    plot(wl_eqe, EQE_frac*100, 'g-', 'LineWidth',1.8);
    ylabel('EQE (%)','FontSize',12); ylim([0 105]);
yyaxis right
    plot(wl_eqe, R_eqe, 'b-', 'LineWidth',1.5);
    ylabel('Responsivity R(\lambda)  (A W^{-1})','FontSize',12);
xlabel('Wavelength (nm)','FontSize',12);
title(sprintf('EQE and Responsivity — %s', paper_label),'FontSize',12);
xlim([300 820]); grid on; box on;

% Figure 3 — Projected J-V curves
figure('Color','w','Position',[50 150 620 370]); hold on;
plot(V_s, J_s, 'k--', 'LineWidth',1.6, ...
    'DisplayName', sprintf('Source (\\lambda_{95}=%.0f nm, PCE=%.1f%%)', l95_s, PCE_source));
for k = 1:4
    plot(V_s, J_proj(:,k), 'LineWidth',1.6, 'Color',clr{k}, ...
        'DisplayName', sprintf('%s %s (PCE=%.1f%%)', corner_refs{k}, corner_names{k}, PCE_c(k)));
end
xlabel('Voltage (V)','FontSize',12);
ylabel('Current Density (\muA cm^{-2})','FontSize',12);
title(sprintf('Projected J-V Curves — %s', paper_label),'FontSize',12);
legend('Location','southwest','FontSize',9);
xlim([0 max(V_s)*1.05]); ylim([0 max(J_s)*1.25]);
grid on; box on;

% Figure 4 — PCE-lambda_onset,95% Locus
figure('Color','w','Position',[690 150 680 480]); hold on;
% Quadrilateral: Ref4(1)->Ref2(3)->Ref1(4)->Ref3(2)->close
quad_idx = [1,3,4,2];
fill(l95_c(quad_idx), PCE_c(quad_idx), locus_color, ...
    'FaceAlpha',0.20,'EdgeColor','none', ...
    'DisplayName','PCE locus (full space)');
% Edges
plot([l95_c(1),l95_c(3)],[PCE_c(1),PCE_c(3)],'-','Color',locus_color,'LineWidth',2.2,'HandleVisibility','off');
plot([l95_c(2),l95_c(4)],[PCE_c(2),PCE_c(4)],'-','Color',locus_color,'LineWidth',2.2,'HandleVisibility','off');
plot([l95_c(1),l95_c(2)],[PCE_c(1),PCE_c(2)],'-','Color',locus_color,'LineWidth',2.2,'HandleVisibility','off');
plot([l95_c(3),l95_c(4)],[PCE_c(3),PCE_c(4)],'-','Color',locus_color,'LineWidth',2.2,'HandleVisibility','off');
% Corners
for k = 1:4
    plot(l95_c(k),PCE_c(k),mrk{k},'MarkerSize',10,'LineWidth',2.0, ...
        'Color',clr{k},'MarkerFaceColor',clr{k}, ...
        'DisplayName',sprintf('%s %s: %.2f%%',corner_refs{k},corner_names{k},PCE_c(k)));
    text(l95_c(k)+1.5,PCE_c(k),sprintf('%s\n%.1f%%',corner_refs{k},PCE_c(k)), ...
        'FontSize',9,'Color',clr{k},'FontWeight','bold');
end
% Measured point
plot(l95_s,PCE_source,'k*','MarkerSize',14,'LineWidth',2.0, ...
    'DisplayName',sprintf('Measured (source): %.2f%%',PCE_source));
text(l95_s+1.5,PCE_source-0.35,'(meas.)','FontSize',9,'Color','k');
% CCT labels
text(mean([l95_c(1),l95_c(3)]),mean([PCE_c(1),PCE_c(3)])+0.4,'5700K', ...
    'FontSize',8,'Color',locus_color,'HorizontalAlignment','center', ...
    'FontAngle','italic','HandleVisibility','off');
text(mean([l95_c(2),l95_c(4)]),mean([PCE_c(2),PCE_c(4)])-0.5,'3000K', ...
    'FontSize',8,'Color',locus_color,'HorizontalAlignment','center', ...
    'FontAngle','italic','HandleVisibility','off');
xline([644,660,702,720],'--','Color',[0.7 0.7 0.7],'LineWidth',0.8,'HandleVisibility','off');
xlabel('\lambda_{onset,95%} (nm)','FontSize',13,'Interpreter','none');
ylabel('PCE (%)','FontSize',13);
title({sprintf('PCE-\\lambda_{onset,95%%} Locus — %s',paper_label),paper_info},'FontSize',12);
legend('Location','northeast','FontSize',10);
xticks([644,660,702,720]); xticklabels({'644','660','702','720'});
xlim([630 735]);
y_margin = (max(PCE_c)-min(PCE_c))*0.6;
ylim([min(PCE_c)-y_margin, max(PCE_c)+y_margin]);
grid on; box on;

fprintf('\nFigures generated:\n');
fprintf('  1 - Corner LED spectra\n  2 - EQE and responsivity\n');
fprintf('  3 - Projected J-V curves\n  4 - PCE-lambda_onset,95%% locus\n');

%% ── Helper function ───────────────────────────────────────
function l95 = lambda_onset_95(wl, E)
    E_c      = max(E, 0);
    cumE     = cumtrapz(wl, E_c);
    cumE_n   = cumE / cumE(end);
    [cu, ia] = unique(cumE_n, 'stable');
    l95      = interp1(cu, wl(ia), 0.95, 'linear');
end