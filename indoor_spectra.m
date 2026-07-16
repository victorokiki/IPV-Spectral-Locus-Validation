%% =========================================================
%  Figure — Reported PCEs of All 15 Surveyed Papers
%  Grouped by technology class
%  Approved devices = solid fill, Excluded = hatched/lighter
%  Reference: Khampa et al., Newton 2, 100437 (2026)
% =========================================================
clear; clc; close all;

%% ── DEVICE DATA ──────────────────────────────────────────
% {Label, Technology, PCE_reported, Approved(1=yes, 0=no)}
data = {
    'S1  Lee 2024',    'Perovskite', 39.04, 0;
    'S2  Tang 2024',   'Perovskite', 40.71, 0;
    'S3  Chen 2025',   'Perovskite', 42.01, 1;
    'S4  Wen 2025',    'Perovskite', 42.30, 1;
    'S5  Liu 2024',    'Perovskite', 41.33, 1;
    'S6  Yang 2024',   'Perovskite', 39.90, 0;
    'S7  Gao 2024',    'Perovskite', 20.12, 0;
    'S8  Li 2024',     'Perovskite', 41.04, 1;
    'S9  Li 2024',     'Perovskite', 35.14, 0;
    'S10 Lee 2024',    'OPV',        31.00, 0;
    'S11 Saeed 2024',  'OPV',        30.30, 0;
    'S12 Wang 2024',   'OPV',        30.40, 1;
    'S13 Santos 2024', 'DSSC',       28.50, 0;
    'S14 Santos 2025', 'DSSC',       30.20, 0;
    'S15 Lu 2024',     'Inorganic',  18.00, 1;
};

labels    = data(:,1);
techs     = data(:,2);
PCEs      = cell2mat(data(:,3));
approved  = cell2mat(data(:,4));

%% ── COLOURS PER TECHNOLOGY ───────────────────────────────
tech_list   = {'Perovskite','OPV','DSSC','Inorganic'};
tech_colors = {[0.12 0.47 0.71],  ...   % blue
               [0.89 0.47 0.20],  ...   % orange
               [0.17 0.63 0.17],  ...   % green
               [0.84 0.15 0.16]}; ...   % red

%% ── BUILD FIGURE ─────────────────────────────────────────
figure('Color','w','Position',[80 80 980 440]);
hold on;

x = 1:15;

for i = 1:15
    % Find colour for this technology
    tidx  = strcmp(tech_list, techs{i});
    clr   = tech_colors{tidx};

    if approved(i) == 1
        % Approved — solid fill, full colour
        bar(x(i), PCEs(i), 0.65, ...
            'FaceColor', clr, ...
            'EdgeColor', clr*0.7, ...
            'LineWidth', 1.2);
    else
        % Excluded — lighter fill, same colour family
        bar(x(i), PCEs(i), 0.65, ...
            'FaceColor', clr + (1-clr)*0.60, ...
            'EdgeColor', clr, ...
            'LineWidth', 1.2, ...
            'LineStyle', '--');
    end
end

%% ── APPROVED / EXCLUDED LABELS ON BARS ───────────────────
for i = 1:15
    if approved(i) == 1
        text(x(i), PCEs(i)+0.5, 'A', ...
            'HorizontalAlignment','center','FontSize',8,...
            'FontWeight','bold','Color',[0.1 0.1 0.1]);
    end
end

%% ── TECHNOLOGY GROUP DIVIDERS ────────────────────────────
% Perovskite: 1-9, OPV: 10-12, DSSC: 13-14, Inorganic: 15
xline(9.5,  '-', 'Color',[0.6 0.6 0.6], 'LineWidth',1.0,'HandleVisibility','off');
xline(12.5, '-', 'Color',[0.6 0.6 0.6], 'LineWidth',1.0,'HandleVisibility','off');
xline(14.5, '-', 'Color',[0.6 0.6 0.6], 'LineWidth',1.0,'HandleVisibility','off');

%% ── TECHNOLOGY GROUP LABELS ──────────────────────────────
y_label = 44.5;
text(5,    y_label, 'Perovskite', 'HorizontalAlignment','center',...
    'FontSize',11,'FontWeight','bold','Color',tech_colors{1});
text(11,   y_label, 'OPV',        'HorizontalAlignment','center',...
    'FontSize',11,'FontWeight','bold','Color',tech_colors{2});
text(13.5, y_label, 'DSSC',       'HorizontalAlignment','center',...
    'FontSize',11,'FontWeight','bold','Color',tech_colors{3});
text(15,   y_label, 'Inorganic',  'HorizontalAlignment','center',...
    'FontSize',11,'FontWeight','bold','Color',tech_colors{4});

%% ── DUMMY LEGEND ENTRIES ─────────────────────────────────
% Approved
bar(nan, nan, 'FaceColor',[0.5 0.5 0.5],'EdgeColor',[0.3 0.3 0.3],...
    'LineWidth',1.2,'DisplayName','Approved (retained for locus)');
% Excluded
bar(nan, nan, 'FaceColor',[0.85 0.85 0.85],'EdgeColor',[0.5 0.5 0.5],...
    'LineWidth',1.2,'LineStyle','--','DisplayName','Excluded (failed validation)');

legend('Location','southwest','FontSize',10,'Box','on');

%% ── AXES FORMATTING ──────────────────────────────────────
xticks(1:15);
xticklabels(labels);
xtickangle(35);
ylabel('Reported PCE (%)','FontSize',13);
xlabel('Paper','FontSize',13);
title('Reported Indoor PCEs of Surveyed Papers (1000 lux)', ...
    'FontSize',13);
xlim([0.3 15.7]);
ylim([0 47]);
set(gca,'FontSize',10,'TickDir','out','YMinorTick','on');
grid on; box on;