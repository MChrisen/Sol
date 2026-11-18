%% koer_skyggetest.m
% Kører Simulink-modellen for skyggetilfældene i ekstra_konfigurationer.m
% (og evt. logskemaets T0-T7) og gemmer:
%   - én IV/PV-figur pr. tilfælde (<id>.pdf)
%   - ét sammenligningsplot pr. testgruppe (gruppe_<T>.pdf)
%   - en CSV med nøgletal (forudsigelser_ekstra.csv)

clear; clc; close all

%% 1. Indstillinger
opt.model    = 'SOLTEST';       % modelnavn (uden .slx)
opt.G_navn   = 'G_cell';
opt.G_form   = 'kolonne';        % 'kolonne' (60x1) eller 'raekke' (1x60)
opt.grupper  = {};               % fx {'T8','T12'}; tom = alle
opt.logskema = false;            % true: tag også T0-T7/K1 fra logskemaet med
opt.kun_A    = false;            % true: kun tilfælde markeret [A]
opt.udmappe  = 'LabModelFigur';
opt.fast     = false;            % Fast Restart (kræver at G_cell er tunable)

p.G0 = 1000;
p.T0 = 25;

init_params                      % standardparametre; G_cell overstyres pr. kørsel

%% 2. Tilfælde
K = ekstra_konfigurationer(p);
if opt.logskema
    KL = logskema_konfigurationer(p);
    K  = [K, KL(~strcmp({KL.test}, 'D0'))];
end
if ~isempty(opt.grupper)
    K = K(ismember({K.test}, [opt.grupper, {'REF'}]));
end
if opt.kun_A
    K = K(startsWith({K.note}, '[A]') | strcmp({K.test}, 'REF'));
end
n = numel(K);
fprintf('%d simuleringer\n', n);

%% 3. Kør
load_system(opt.model);
if ~isfolder(opt.udmappe), mkdir(opt.udmappe); end

in(1:n) = Simulink.SimulationInput(opt.model);
for k = 1:n
    G = K(k).G;
    if strcmpi(opt.G_form, 'raekke'), G = G(:).'; else, G = G(:); end
    in(k) = in(k).setVariable(opt.G_navn, G);
end
fr = {'off', 'on'};
out = sim(in, 'ShowProgress', 'on', 'StopOnError', 'off', ...
          'UseFastRestart', fr{opt.fast + 1});

%% 4. Analyse og figurer pr. tilfælde
IV = struct('V', cell(1, n), 'I', cell(1, n));
R  = struct('Isc', cell(1, n), 'Voc', [], 'Pmax', [], 'Vmp', [], 'Imp', [], 'n_MPP', []);
ok = true(1, n);
for k = 1:n
    if ~isempty(out(k).ErrorMessage)
        warning('%s fejlede: %s', K(k).id, out(k).ErrorMessage);
        ok(k) = false;
        continue
    end
    [IV(k).V, IV(k).I] = hent_iv(out(k));
    R(k) = noegletal(IV(k).V, IV(k).I);
    fprintf('%-18s Pmax = %6.1f W  Vmp = %5.2f V  Imp = %5.2f A  MPP''er = %d\n', ...
        K(k).id, R(k).Pmax, R(k).Vmp, R(k).Imp, R(k).n_MPP);
    plot_iv(IV(k).V, IV(k).I, R(k), fullfile(opt.udmappe, [K(k).id '.pdf']));
end

%% 5. Sammenligningsplot pr. gruppe (med uskygget reference)
iref = find(strcmp({K.id}, 'REF') & ok, 1);
grupper = setdiff(unique({K.test}, 'stable'), {'REF'}, 'stable');
for g = 1:numel(grupper)
    ix  = find(strcmp({K.test}, grupper{g}) & ok);
    fig = figure('Visible', 'off', 'Units', 'centimeters', 'Position', [2 2 16 11]);
    tiledlayout(fig, 2, 1, 'TileSpacing', 'compact');
    a1 = nexttile; hold(a1, 'on'); grid(a1, 'on');
    a2 = nexttile; hold(a2, 'on'); grid(a2, 'on');
    if ~isempty(iref)
        plot(a1, IV(iref).V, IV(iref).I, 'k--', 'DisplayName', 'Uskygget');
        plot(a2, IV(iref).V, IV(iref).V.*IV(iref).I, 'k--', 'HandleVisibility', 'off');
    end
    for i = ix
        plot(a1, IV(i).V, IV(i).I, 'LineWidth', 1.2, 'DisplayName', K(i).id);
        plot(a2, IV(i).V, IV(i).V.*IV(i).I, 'LineWidth', 1.2, 'HandleVisibility', 'off');
    end
    ylabel(a1, 'Strøm I [A]');  ylim(a1, [0 10]);  xlim(a1, [0 40]);
    ylabel(a2, 'Effekt P [W]'); ylim(a2, [0 260]); xlim(a2, [0 40]);
    xlabel(a2, 'Spænding V [V]');
    legend(a1, 'Location', 'eastoutside', 'Interpreter', 'none');
    title(a1, grupper{g});
    exportgraphics(fig, fullfile(opt.udmappe, ['gruppe_' grupper{g} '.pdf']), ...
        'ContentType', 'vector');
    close(fig)
end

%% 6. Tabel
ID = {K(ok).id}.';  Test = {K(ok).test}.';  Note = {K(ok).note}.';
Rk = R(ok);
tab = table(ID, Test, [Rk.Isc].', [Rk.Voc].', [Rk.Pmax].', [Rk.Vmp].', [Rk.Imp].', ...
    [Rk.n_MPP].', Note, 'VariableNames', ...
    {'ID', 'Test', 'Isc_A', 'Voc_V', 'Pmax_W', 'Vmp_V', 'Imp_A', 'n_MPP', 'Note'});
writetable(tab, fullfile(opt.udmappe, 'forudsigelser_ekstra.csv'));
fprintf('Gemt i %s\n', opt.udmappe);


%% ===================== Lokale funktioner =====================

function [V, I] = hent_iv(so)
V = so.Voltage.Data;  I = so.Current.Data;
V = double(V(:));     I = double(I(:));
[V, ix] = sort(V);    I = I(ix);
[V, iu] = unique(V);  I = I(iu);
end

function r = noegletal(V, I)
r = struct('Isc', NaN, 'Voc', NaN, 'Pmax', 0, 'Vmp', NaN, 'Imp', NaN, 'n_MPP', 0);
r.Isc = interp1(V, I, 0, 'linear', 'extrap');
iz = find(I(1:end-1) > 0 & I(2:end) <= 0, 1);
if ~isempty(iz)
    r.Voc = V(iz) - I(iz)*(V(iz+1) - V(iz))/(I(iz+1) - I(iz));
end
m = V >= 0 & I >= 0;
Vm = V(m);  Im = I(m);  Pm = Vm.*Im;
if isempty(Pm), return; end
[r.Pmax, k] = max(Pm);
r.Vmp = Vm(k);  r.Imp = Im(k);
if r.Pmax > 1      % under 1 W regnes som "ingen effekt" (fx alle delstrenge ude)
    r.n_MPP = nnz(islocalmax(Pm, 'MinProminence', 0.01*r.Pmax));
    r.n_MPP = max(r.n_MPP, 1);
end
end

function plot_iv(V, I, r, filnavn)
m = I >= 0 & V >= 0;
V = V(m);  I = I(m);  P = V.*I;
Pmax = r.Pmax;  Vmp = r.Vmp;  Imp = r.Imp;

guide = {':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1, 'HandleVisibility', 'off'};
fig = figure('Visible', 'off', 'Units', 'centimeters', 'Position', [2 2 14 9]);

yyaxis left
hI = plot(V, I, 'LineWidth', 1.5); hold on
plot([0 Vmp], [Imp Imp], guide{:})
plot(Vmp, Imp, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 6, 'HandleVisibility', 'off')
ylabel('Strøm I [A]')
ylim([0 10])

yyaxis right
hP = plot(V, P, 'LineWidth', 1.5); hold on
plot([Vmp Vmp], [0 Pmax], guide{:})
plot([Vmp 40],  [Pmax Pmax], guide{:})
hM = plot(Vmp, Pmax, 'ko', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
ylabel('Effekt P [W]')
ylim([0 260])

xlabel('Spænding V [V]')
xlim([0 40])
grid on

text(0.04, 0.74, sprintf('V_{mp} = %.2f V\nI_{mp} = %.2f A\nP_{max} = %.1f W', ...
    Vmp, Imp, Pmax), 'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'BackgroundColor', 'w', 'EdgeColor', [0.6 0.6 0.6], 'Margin', 4, 'FontSize', 9)
legend([hI hP hM], {'I', 'P', 'MPP'}, 'Location', 'south', ...
    'Orientation', 'horizontal', 'AutoUpdate', 'off')
hold off

exportgraphics(fig, filnavn, 'ContentType', 'vector');
close(fig)
end