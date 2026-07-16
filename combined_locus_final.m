%% =========================================================
%  COMBINED PCE-lambda_onset,95% LOCUS PLOT
%  IPV Project — 6 Approved Devices (labelled A-F)
%
%  Device A = S3  Chen 2025    (Perovskite, 1.67 eV)
%  Device B = S4  Wen 2025     (Perovskite, 1.79 eV)
%  Device C = S5  Liu 2024     (Perovskite, 1.56 eV)
%  Device D = S8  Li 2024      (Perovskite, 1.52 eV)
%  Device E = S12 Wang 2024    (OPV,        1.74 eV)
%  Device F = S15 Lu 2024      (Inorganic Se, 1.90 eV)
%
%  Reference: Khampa et al., Newton 2, 100437 (2026)
% =========================================================
clear; clc; close all;

%% ── DEVICE DATA ──────────────────────────────────────────
%  l95 = [Ref4(644nm), Ref3(660nm), Ref2(702nm), Ref1(720nm)]
%  PCE = [Ref4,        Ref3,        Ref2,        Ref1       ]

devices(1).label = 'Device A (PVSK, 1.67 eV)';
devices(1).tech  = 'Perovskite';
devices(1).Eg    = 1.67;
devices(1).l95   = [645.8, 660.1, 702.0, 721.1];
devices(1).PCE   = [40.58, 43.16, 41.18, 43.76];
devices(1).color = [0.12 0.47 0.71];   % blue

devices(2).label = 'Device B (PVSK, 1.79 eV)';
devices(2).tech  = 'Perovskite';
devices(2).Eg    = 1.79;
devices(2).l95   = [645.8, 660.1, 702.0, 721.1];
devices(2).PCE   = [39.66, 41.58, 37.89, 38.16];
devices(2).color = [0.00 0.62 0.45];   % teal

devices(3).label = 'Device C (PVSK, 1.56 eV)';
devices(3).tech  = 'Perovskite';
devices(3).Eg    = 1.56;
devices(3).l95   = [645.8, 660.1, 702.0, 721.1];
devices(3).PCE   = [37.22, 40.20, 38.30, 41.59];
devices(3).color = [0.80 0.47 0.65];   % pink

devices(4).label = 'Device D (PVSK, 1.52 eV)';
devices(4).tech  = 'Perovskite';
devices(4).Eg    = 1.52;
devices(4).l95   = [645.8, 660.1, 702.0, 721.1];
devices(4).PCE   = [39.24, 41.46, 40.28, 42.85];
devices(4).color = [0.58 0.40 0.74];   % purple

devices(5).label = 'Device E (OPV, 1.74 eV)';
devices(5).tech  = 'OPV';
devices(5).Eg    = 1.74;
devices(5).l95   = [645.8, 660.1, 702.0, 721.1];
devices(5).PCE   = [28.41, 30.50, 27.97, 29.34];
devices(5).color = [0.89 0.47 0.20];   % orange

devices(6).label = 'Device F (Se, 1.90 eV)';
devices(6).tech  = 'Inorganic';
devices(6).Eg    = 1.90;
devices(6).l95   = [645.8, 660.1, 702.0, 721.1];
devices(6).PCE   = [16.64, 14.97, 14.18, 11.08];
devices(6).color = [0.84 0.15 0.16];   % red

%% ── CORNER REFERENCE COLOURS ─────────────────────────────
ref_colors = {[0.84 0.15 0.16], ...   % Ref4 5700K 644nm — red
              [0.89 0.47 0.20], ...   % Ref3 3000K 660nm — orange
              [0.12 0.47 0.71], ...   % Ref2 5700K 702nm — blue
              [0.17 0.63 0.17]};      % Ref1 3000K 720nm — green
ref_labels = {'Ref 4 (5700K, 644 nm)', ...
              'Ref 3 (3000K, 660 nm)', ...
              'Ref 2 (5700K, 702 nm)', ...
              'Ref 1 (3000K, 720 nm)'};

%% ── QUADRILATERAL ORDER ──────────────────────────────────
% Ref4(1) -> Ref2(3) -> Ref1(4) -> Ref3(2) -> close
quad_idx = [1, 3, 4, 2, 1];

%% ── BUILD FIGURE ─────────────────────────────────────────
figure('Color','w','Position',[80 60 920 600]);
hold on;

for i = 1:length(devices)
    d  = devices(i);
    lx = d.l95(quad_idx);
    py = d.PCE(quad_idx);

    % Shaded fill — coloured square patch in legend
    fill(lx(1:end-1), py(1:end-1), d.color, ...
        'FaceAlpha', 0.18, ...
        'EdgeColor', d.color, ...
        'LineWidth', 1.8, ...
        'DisplayName', d.label);

    % Locus outline
    plot(lx, py, '-', ...
        'Color', d.color, ...
        'LineWidth', 2.0, ...
        'HandleVisibility', 'off');

    % Corner dots coloured by Ref identity
    for k = 1:4
        plot(d.l95(k), d.PCE(k), 'o', ...
            'Color',           ref_colors{k}, ...
            'MarkerFaceColor', ref_colors{k}, ...
            'MarkerSize',      7, ...
            'LineWidth',       1.2, ...
            'HandleVisibility','off');
    end
end

%% ── DUMMY LEGEND ENTRIES FOR REF CORNERS ─────────────────
for k = 1:4
    plot(nan, nan, 'o', ...
        'Color',           ref_colors{k}, ...
        'MarkerFaceColor', ref_colors{k}, ...
        'MarkerSize',      9, ...
        'LineWidth',       1.2, ...
        'DisplayName',     ref_labels{k});
end

%% ── REFERENCE VERTICAL LINES ─────────────────────────────
xline(644,'--','Color',[0.68 0.68 0.68],'LineWidth',0.9,'HandleVisibility','off');
xline(660,'--','Color',[0.68 0.68 0.68],'LineWidth',0.9,'HandleVisibility','off');
xline(702,'--','Color',[0.68 0.68 0.68],'LineWidth',0.9,'HandleVisibility','off');
xline(720,'--','Color',[0.68 0.68 0.68],'LineWidth',0.9,'HandleVisibility','off');

%% ── REGION LABELS alpha beta gamma delta ─────────────────
all_PCE = [];
for i = 1:length(devices)
    all_PCE = [all_PCE, devices(i).PCE]; %#ok<AGROW>
end
y_top = max(all_PCE) * 1.046;
text(652, y_top, '\alpha', 'FontSize',13,'HorizontalAlignment','center','FontWeight','bold');
text(681, y_top, '\beta',  'FontSize',13,'HorizontalAlignment','center','FontWeight','bold');
text(711, y_top, '\gamma', 'FontSize',13,'HorizontalAlignment','center','FontWeight','bold');
text(724, y_top, '\delta', 'FontSize',13,'HorizontalAlignment','center','FontWeight','bold');

%% ── AXES AND FORMATTING ──────────────────────────────────
xlabel('\lambda_{onset,95%} (nm)', 'FontSize',13,'Interpreter','tex');
ylabel('PCE (%)',                   'FontSize',13);
title('PCE–\lambda_{onset,95%} Locus Comparison', 'FontSize',13,'Interpreter','tex');

lgd = legend('Location','northoutside','FontSize',7,'Box','off','NumColumns',4);
title(lgd,'Device locus / Corner reference');

xticks([644, 660, 702, 720]);
xticklabels({'644 (Ref4)','660 (Ref3)','702 (Ref2)','720 (Ref1)'});
xlim([625, 732]);
y_min = min(all_PCE) * 0.86;
y_max = max(all_PCE) * 1.07;
ylim([y_min, y_max]);
set(gca,'FontSize',11,'TickDir','out','YMinorTick','on');
grid on; box on;

%% ── CONSOLE SUMMARY ──────────────────────────────────────
fprintf('\n%s\n', repmat('=',1,82));
fprintf(' COMBINED LOCUS SUMMARY\n');
fprintf('%s\n', repmat('=',1,82));
fprintf('%-30s  %-12s  %4s  %6s  %6s  %6s  %6s   %s\n', ...
    'Device','Technology','Eg','Ref4','Ref3','Ref2','Ref1','PCE range');
fprintf('%s\n', repmat('-',1,82));
for i = 1:length(devices)
    d = devices(i);
    fprintf('%-30s  %-12s  %.2f  %5.2f  %5.2f  %5.2f  %5.2f   %.2f–%.2f%%\n', ...
        d.label, d.tech, d.Eg, ...
        d.PCE(1),d.PCE(2),d.PCE(3),d.PCE(4), ...
        min(d.PCE), max(d.PCE));
end

%% ── DOMINANCE ANALYSIS ───────────────────────────────────
fprintf('\n%s\n', repmat('-',1,82));
fprintf(' DOMINANCE ANALYSIS\n');
fprintf('%s\n', repmat('-',1,82));
corner_refs = {'Ref4(644nm)','Ref3(660nm)','Ref2(702nm)','Ref1(720nm)'};
for i = 1:length(devices)
    for j = i+1:length(devices)
        a = devices(i).PCE;
        b = devices(j).PCE;
        if all(a > b)
            fprintf('  %s DOMINATES %s at ALL 4 corners\n\n', ...
                devices(i).label, devices(j).label);
        elseif all(b > a)
            fprintf('  %s DOMINATES %s at ALL 4 corners\n\n', ...
                devices(j).label, devices(i).label);
        else
            wins_i = corner_refs(a > b);
            wins_j = corner_refs(b > a);
            fprintf('  %s  vs  %s\n    Former wins at: %s\n    Latter wins at: %s\n\n', ...
                devices(i).label, devices(j).label, ...
                strjoin(wins_i,', '), strjoin(wins_j,', '));
        end
    end
end
fprintf('%s\n', repmat('=',1,82));