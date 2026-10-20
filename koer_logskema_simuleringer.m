%% KOER_LOGSKEMA_SIMULERINGER
% Kører panelmodellen (REC245PE, 60 celler, 3 bypass-dioder) for hver
% konfiguration i det eksperimentelle logskema og gemmer IV-kurver og
% nøgletal (Isc, Voc, Pmax, V_mpp, antal lokale MPP'er, trinstrøm).
%
% Brug:
%   1. Ret afsnit 1, så det passer til jeres model.
%   2. Før lab: kør scriptet med opt.maalinger = ''. Kolonnen Pmax_W i
%      simresultater/forudsigelser.csv er "Pmax model" i logskemaet.
%   3. Efter lab: sæt opt.maalinger til en CSV eksporteret fra logskemaet med
%      kolonnerne ID, Tid (ÅÅÅÅ-MM-DD tt:mm), Isc, T og evt. G_mon. Så køres
%      én simulering pr. måling ved den effektive indstråling og temperatur.
%
% Simulatoren kan ikke kalibreres, så den absolutte indstråling er ukendt.
% Den effektive indstråling bestemmes i stedet ud fra modulets egen Isc:
%   G_eff = G_STC * Isc / (Isc_STC * (1 + alpha*(T - 25)))
% - Uskyggede målinger (T0, K1-rot, T6): direkte fra målingens egen Isc.
% - Skyggede målinger: G_mon (ukalibreret monitorværdi) skaleret med
%   forholdet G_eff/G_mon fra de uskyggede målinger, hvis G_mon er logget.
%   Ellers interpoleres G_eff i tid mellem de nærmeste T0/K1-rot-målinger.
%
% Konfigurationerne og cellelayoutet er defineret i logskema_konfigurationer.m.

clear; clc;

%% 1. Indstillinger - tilpas til jeres model
opt.tilstand  = 'simulink';    % 'simulink' eller 'funktion'
opt.model     = 'SOLTEST';    % Simulink-modellens navn (uden .slx)
opt.G_navn    = 'G_cell';      % variablen modellen læser indstrålingen fra (Ns x 1)
opt.G_form    = 'kolonne';     % 'kolonne' (60x1) eller 'raekke' (1x60)
opt.T_navn    = '';            % temperaturvariabel; '' hvis modellen ikke har en
opt.V_navn    = 'V';           % logget spænding (signal logging eller To Workspace)
opt.I_navn    = 'I';           % logget strøm, generatorkonvention (I > 0 ved Isc)
opt.funktion  = [];            % kun ved 'funktion': handle, [V, I] = f(G, T)
opt.parallel  = false;         % true: parsim (kræver Parallel Computing Toolbox)
opt.koer_D0   = false;         % mørk IV: kræver at spændingssweepet går over Voc
opt.fint_T2   = false;         % ekstra sweep f = 0:2:100 % for at finde MPP-skiftet
opt.maalinger = '';            % CSV fra lab: ID, Tid, Isc, T, (G_mon) - tom før lab
opt.uddata    = 'simresultater';

% Parametre til konfigurationerne (se logskema_konfigurationer.m)
p.G0        = 1000;
p.T0        = 25;
p.testcelle = 'C5';
p.T3_samme  = 'D5';
p.T3_anden  = 'E5';
p.T5_celler = {'B5', 'C5', 'E5'};
p.T_eff     = struct('SN50', 0.50, 'FN', 0.70);   % opdatér med K2-resultaterne
p.fX        = [NaN NaN NaN];                       % ekstra T2-punkter, fx [33 36 39]

% Selvreference for indstrålingen (REC245PE-datablad). Isc_STC skal være
% modellens egen Isc ved STC - datablad-værdien, hvis jeres 5 parametre er
% udtrukket fra databladet; ellers modellens Isc ved 1000 W/m^2 og 25 degC.
p.G_STC     = 1000;        % [W/m^2]
p.Isc_STC   = 8.68;        % [A]
p.alpha_Isc = 0.07/100;    % [1/K], temperaturkoefficient for Isc

%% 2. Konfigurationer
K = logskema_konfigurationer(p);
if ~opt.koer_D0
    K = K(~strcmp({K.test}, 'D0'));
end
if ~isempty(opt.maalinger)
    K = konfig_fra_maalinger(K, opt.maalinger, p);
end
fprintf('%d simuleringer.\n', numel(K));

%% 3. Kør
[R, IV] = koer(K, opt);

%% 4. Gem
if ~exist(opt.uddata, 'dir'), mkdir(opt.uddata); end
tab = resultattabel(K, R);
if isempty(opt.maalinger)
    csvnavn = fullfile(opt.uddata, 'forudsigelser.csv');
else
    csvnavn = fullfile(opt.uddata, 'model_ved_maalebetingelser.csv');
end
writetable(tab, csvnavn);
save(fullfile(opt.uddata, 'simresultater.mat'), 'K', 'R', 'IV', 'tab', 'opt', 'p');
disp(tab(:, {'ID', 'Pmax_W', 'Vmpp_V', 'n_MPP', 'I_trin_A'}));
fprintf('Gemt: %s\n', csvnavn);

%% 5. Figurer, én pr. testgruppe
grupper = unique({K.test}, 'stable');
for g = 1:numel(grupper)
    ix  = find(strcmp({K.test}, grupper{g}));
    fig = figure('Name', grupper{g}, 'Color', 'w');
    tiledlayout(fig, 2, 1, 'TileSpacing', 'compact');
    ax1 = nexttile; hold(ax1, 'on'); grid(ax1, 'on');
    ax2 = nexttile; hold(ax2, 'on'); grid(ax2, 'on');
    for i = ix
        plot(ax1, IV(i).V, IV(i).I, 'DisplayName', K(i).id);
        plot(ax2, IV(i).V, IV(i).V.*IV(i).I, 'DisplayName', K(i).id);
    end
    ylabel(ax1, 'I [A]'); ylim(ax1, [0 inf]);
    ylabel(ax2, 'P [W]'); ylim(ax2, [0 inf]); xlabel(ax2, 'V [V]');
    legend(ax1, 'Location', 'eastoutside', 'Interpreter', 'none');
    title(ax1, grupper{g});
    exportgraphics(fig, fullfile(opt.uddata, [grupper{g} '.png']), 'Resolution', 200);
end

%% 6. Valgfrit: find MPP-skiftet i T2 med et fint sweep
if opt.fint_T2
    f = 0:2:100;
    pf = p;  pf.fX = f;                      % genbrug T2-definitionen
    Kf = logskema_konfigurationer(pf);
    Kf = Kf(startsWith({Kf.id}, ['T2-' p.testcelle '-fX']));
    Rf = koer(Kf, opt);
    Vm = [Rf.Vmpp];
    [~, j] = max(abs(diff(Vm)));
    fprintf(['Globalt MPP springer mellem f = %d %% og f = %d %% ' ...
             '(V_mpp %.1f -> %.1f V).\nSæt p.fX omkring dette interval.\n'], ...
             f(j), f(j + 1), Vm(j), Vm(j + 1));
    figure('Color', 'w');
    yyaxis left;  plot(f, [Rf.Pmax], '-o'); ylabel('P_{max} [W]');
    yyaxis right; plot(f, Vm, '-s');        ylabel('V_{mpp} [V]');
    xlabel(sprintf('Skygget andel af %s [%%]', p.testcelle)); grid on;
end

%% ===========================================================================
%  Lokale funktioner
%  ===========================================================================

function [R, IV] = koer(K, opt)
% Kører alle konfigurationer i K og analyserer IV-kurverne.
n  = numel(K);
IV = struct('V', cell(1, n), 'I', cell(1, n));
switch opt.tilstand
    case 'simulink'
        load_system(opt.model);
        in(1:n) = Simulink.SimulationInput(opt.model);
        for i = 1:n
            in(i) = in(i).setVariable(opt.G_navn, formG(K(i).G, opt.G_form));
            if ~isempty(opt.T_navn)
                in(i) = in(i).setVariable(opt.T_navn, K(i).T);
            end
        end
        if opt.parallel
            out = parsim(in, 'ShowProgress', 'on');
        else
            out = sim(in, 'ShowProgress', 'on');
        end
        for i = 1:n
            if ~isempty(out(i).ErrorMessage)
                error('Simulering %s fejlede:\n%s', K(i).id, out(i).ErrorMessage);
            end
            [IV(i).V, IV(i).I] = hent_iv(out(i), opt);
        end
    case 'funktion'
        for i = 1:n
            [V, I] = opt.funktion(formG(K(i).G, opt.G_form), K(i).T);
            IV(i).V = V(:);  IV(i).I = I(:);
            fprintf('%3d/%d %s\n', i, n, K(i).id);
        end
    otherwise
        error('Ukendt opt.tilstand "%s"', opt.tilstand);
end
for i = 1:n
    [IV(i).V, IV(i).I] = rens_iv(IV(i).V, IV(i).I, K(i).id);
    R(i) = analyser_iv(IV(i).V, IV(i).I); %#ok<AGROW>
end
end

function G = formG(G, form)
if strcmpi(form, 'raekke'), G = G(:).'; else, G = G(:); end
end

function [V, I] = hent_iv(so, opt)
% Henter V og I fra et SimulationOutput: først som variabel (To Workspace),
% ellers som logget signal i logsout (signal logging på linjen).
V = hent_signal(so, opt.V_navn);
I = hent_signal(so, opt.I_navn);
end

function x = hent_signal(so, navn)
x = [];
try
    x = so.get(navn);
catch
end
if isempty(x)
    try
        el = so.get('logsout').getElement(navn);
        if isa(el, 'Simulink.SimulationData.Dataset'), el = el{1}; end
        x = el.Values;
    catch
    end
end
if isempty(x)
    error(['Fandt ikke signalet "%s" i simuleringens output - hverken som ' ...
           'variabel eller i logsout. Tjek signalnavnet på linjen.'], navn);
end
x = tilvektor(x);
end

function x = tilvektor(x)
% Håndterer To Workspace-formaterne Timeseries, Structure (with time) og Array.
if isa(x, 'timeseries')
    x = x.Data;
elseif isstruct(x) && isfield(x, 'signals')
    x = x.signals.values;
end
x = double(squeeze(x));
x = x(:);
end

function [V, I] = rens_iv(V, I, id)
% Sorterer efter V, fjerner dubletter og tjekker strømretningen.
if numel(V) ~= numel(I)
    error('%s: V og I har forskellig længde (%d vs %d)', id, numel(V), numel(I));
end
[V, ix] = sort(V);  I = I(ix);
[V, iu] = unique(V);  I = I(iu);
if median(I) < 0 && ~startsWith(id, 'D0')   % mørk kurve er negativ med vilje
    warning('%s: strømmen er overvejende negativ - vender fortegnet (generatorkonvention).', id);
    I = -I;
end
end

function r = analyser_iv(V, I)
% Nøgletal fra en IV-kurve i generatorkonvention, sorteret efter V.
r = struct('Isc', NaN, 'Voc', NaN, 'Pmax', NaN, 'Vmpp', NaN, 'Impp', NaN, ...
           'n_MPP', 0, 'V_lok', [], 'I_trin', NaN);
P = V.*I;
r.Isc = interp1(V, I, 0, 'linear', 'extrap');

% Voc: første nulgennemgang af I med stigende V
iz = find(I(1:end-1) > 0 & I(2:end) <= 0, 1);
if isempty(iz), return; end
r.Voc = V(iz) - I(iz)*(V(iz+1) - V(iz))/(I(iz+1) - I(iz));

% Kun 1. kvadrant
m  = V >= 0 & V <= r.Voc;
Vm = V(m);  Im = I(m);  Pm = P(m);
[r.Pmax, ip] = max(Pm);
r.Vmpp = Vm(ip);  r.Impp = Im(ip);

% Lokale MPP'er: maksima med prominens over 1 % af Pmax
lm = find(islocalmax(Pm, 'MinProminence', 0.01*r.Pmax));
if isempty(lm), lm = ip; end
r.n_MPP = numel(lm);
r.V_lok = Vm(lm).';

% Trinstrøm: strømmen på det vandrette trin før det lokale MPP med højest
% spænding, dvs. den skyggede delstrengs strøm. Tages som medianen af
% strømmen fra dalen i P(V) og halvvejs hen mod MPP'et, så knæet undgås.
if r.n_MPP >= 2
    a = lm(end - 1);  b = lm(end);
    [~, d] = min(Pm(a:b));  dal = a + d - 1;
    e = dal + max(1, floor((b - dal)/2));
    r.I_trin = median(Im(dal:e));
end
end

function tab = resultattabel(K, R)
ID       = {K.id}.';
Test     = {K.test}.';
Note     = {K.note}.';
T_C      = [K.T].';
G_eff_Wm2 = [K.Gnom].';
Isc_A    = [R.Isc].';
Voc_V    = [R.Voc].';
Pmax_W   = [R.Pmax].';
Vmpp_V   = [R.Vmpp].';
Impp_A   = [R.Impp].';
n_MPP    = [R.n_MPP].';
I_trin_A = [R.I_trin].';
V_lokale_MPP = arrayfun(@(r) strjoin(compose('%.1f', r.V_lok), ' '), R, ...
                        'UniformOutput', false).';
tab = table(ID, Test, Note, T_C, G_eff_Wm2, Isc_A, Voc_V, Pmax_W, Vmpp_V, Impp_A, ...
            n_MPP, I_trin_A, V_lokale_MPP);
end

function Km = konfig_fra_maalinger(K, fil, p)
% Laver én konfiguration pr. måling i CSV-filen ved målingens effektive
% indstråling G_eff og temperatur T.
%   Kolonner: ID, Isc [A], T [degC]; valgfrit Tid (ÅÅÅÅ-MM-DD tt:mm) og
%   G_mon (ukalibreret monitorværdi, vilkårlig enhed).
% Hver måling kobles til den konfiguration, hvis ID er det længste præfiks
% af målingens ID (fx T2-C5-f30-r2 -> T2-C5-f30, T0-d1-start-r1 -> T0).
% G skaleres med G_eff/Gnom, så skyggemønstret bevares.
M    = readtable(fil, 'TextType', 'string');
navn = string(M.Properties.VariableNames);
mangler = setdiff(["ID", "Isc", "T"], navn);
if ~isempty(mangler)
    error('%s mangler kolonnen/kolonnerne: %s', fil, strjoin(mangler, ', '));
end
n   = height(M);
mid = strtrim(M.ID);

% Tidspunkter (til interpolation mellem T0-målinger)
tnum = nan(n, 1);
if ismember("Tid", navn)
    t = M.Tid;
    if ~isdatetime(t), t = datetime(t, 'InputFormat', 'yyyy-MM-dd HH:mm'); end
    tnum = posixtime(t);
end
Gmon = nan(n, 1);
if ismember("G_mon", navn), Gmon = double(M.G_mon); end

% 1) Uskyggede målinger: G_eff direkte fra egen Isc
selv = startsWith(mid, ["T0", "K1-rot", "T6"]);
nom  = startsWith(mid, ["T0", "K1-rot"]);        % nominel intensitet
Geff = nan(n, 1);
Geff(selv) = p.G_STC*M.Isc(selv) ./ (p.Isc_STC*(1 + p.alpha_Isc*(M.T(selv) - 25)));
if ~any(isfinite(Geff(nom)))
    error('Ingen gyldige T0/K1-rot-målinger - G_eff kan ikke bestemmes.');
end

% 2) Skyggede målinger: via G_mon-forhold, ellers interpolation i tid
rest = ~selv;
ok = selv & isfinite(Gmon) & Gmon > 0 & isfinite(Geff);
if any(ok)
    kG = median(Geff(ok)./Gmon(ok));
    brug = rest & isfinite(Gmon) & Gmon > 0;
    Geff(brug) = kG*Gmon(brug);
    fprintf('G_eff fra G_mon-forhold for %d målinger (k = %.4g).\n', nnz(brug), kG);
end
tilbage = rest & isnan(Geff);
ref = nom & isfinite(Geff) & isfinite(tnum);
if any(tilbage) && nnz(ref) >= 2
    [tu, iu] = unique(tnum(ref));
    gr = Geff(ref);  gr = gr(iu);
    Geff(tilbage) = interp1(tu, gr, tnum(tilbage), 'linear');
    ud = tilbage & isnan(Geff) & isfinite(tnum);           % før første / efter sidste T0
    Geff(ud) = interp1(tu, gr, tnum(ud), 'nearest', 'extrap');
    fprintf('G_eff interpoleret i tid for %d målinger.\n', nnz(tilbage & isfinite(Geff)));
end
tilbage = rest & isnan(Geff);
if any(tilbage)
    Geff(tilbage) = mean(Geff(nom), 'omitnan');
    fprintf('G_eff = middel af T0 for %d målinger uden tid og G_mon.\n', nnz(tilbage));
end

% 3) Byg konfigurationerne
ids = string({K.id});
Km  = K([]);
sprunget = strings(0);
for j = 1:n
    hit = find(mid(j) == ids | arrayfun(@(s) startsWith(mid(j), s + "-"), ids));
    if isempty(hit) || isnan(M.T(j)) || isnan(Geff(j))
        sprunget(end + 1) = mid(j); %#ok<AGROW>
        continue
    end
    [~, b] = max(strlength(ids(hit)));
    k = K(hit(b));
    if k.Gnom > 0                    % D0 (mørk) beholder G = 0
        k.G    = k.G*Geff(j)/k.Gnom;
        k.Gnom = Geff(j);
    end
    k.T  = M.T(j);
    k.id = char(mid(j));
    Km(end + 1) = k; %#ok<AGROW>
end
if ~isempty(sprunget)
    fprintf('Sprunget over (ingen konfiguration, fx K2, eller manglende data): %s\n', ...
            strjoin(sprunget, ', '));
end
end
