function K = logskema_konfigurationer(p)
%LOGSKEMA_KONFIGURATIONER  Indstrålingsvektor G (60x1) for hver konfiguration i logskemaet.
%   K = logskema_konfigurationer(p) returnerer en struct-array med felterne
%     id     - konfigurationens ID (som i logskemaet, uden -r1/-r2/-r3)
%     test   - testgruppe ('T0', 'T1', ..., 'D0')
%     G      - 60x1 indstråling pr. celle [W/m^2], indekseret som i modellen
%     Gnom   - nominel indstråling på uskyggede celler [W/m^2]
%     T      - celletemperatur [degC]
%     note   - kort beskrivelse
%
%   p (alle felter valgfrie, se standardværdier nedenfor):
%     G0        nominel indstråling                      [1000]
%     T0        celletemperatur                          [25]
%     testcelle testcelle i T2, T3 og T7                 ['C5']
%     T3_samme  celle i samme delstreng som testcellen   ['D5']
%     T3_anden  celle i en anden delstreng               ['E5']
%     T5_celler celler i delstreng 1, 2, 3               {'B5','C5','E5'}
%     T_eff     struct med T_eff pr. materiale fra K2     [SN50 0,5; FN 0,7]
%     fX        ekstra skyggegrader i T2 omkring MPP-skift [NaN NaN NaN]
%
%   CELLELAYOUT (REC245PE, 6 x 10 celler, 3 bypass-dioder)
%     Set forfra med samledåsen øverst:
%       kolonne A-F fra venstre mod højre, række 1-10 fra samledåsen.
%     ANTAGELSE (bekræftes i T1): hver bypass-diode dækker et kolonnepar,
%       delstreng 1 = A-B -> G_cell(1:20)
%       delstreng 2 = C-D -> G_cell(21:40)
%       delstreng 3 = E-F -> G_cell(41:60)
%     Strengen løber ned ad venstre kolonne og op ad højre i hvert par:
%       A1..A10 = 1..10,  B10..B1 = 11..20
%       C1..C10 = 21..30, D10..D1 = 31..40
%       E1..E10 = 41..50, F10..F1 = 51..60
%     Simulink-modellen (pv_modul): tre rækker á 20 celler, én bypass-diode
%     pr. række. Nederste række G_cell(1) th. -> G_cell(20) tv., midterste
%     21 th. -> 40 tv., øverste 41 th. -> 60 tv.
%     Rækkefølgen inden for en delstreng er elektrisk ligegyldig, og pga.
%     symmetri er det også ligegyldigt, hvilket kolonnepar der kaldes
%     delstreng 1. Det eneste, der skal passe, er hvilke kolonner der deler
%     diode. Ret celle_idx nederst, hvis T1 viser noget andet.
%
%   SKYGGE
%     En celle skygget med andelen f får G = (1 - f)*G0. Det er netop
%     G_eff-antagelsen, som forsøgene tester, så modellens forudsigelse for
%     T7 (translucent vs. uigennemsigtig) bliver identisk pr. konstruktion.
%
%   INDSTRÅLING UDEN KALIBRERING
%     Simulatoren kan ikke kalibreres (referencecelle og referencemoduler fra
%     2013 afvises af softwaren), så den absolutte indstråling er ukendt.
%     G0 er derfor en NOMINEL effektiv indstråling:
%       - Før lab: G0 = 1000 giver forudsigelserne (relativt til 1 sol).
%       - Efter lab: hovedscriptet (konfig_fra_maalinger) skalerer hver
%         konfiguration til G_eff, bestemt ud fra modulets egen Isc i de
%         uskyggede målinger (T0, K1-rot, T6). Skyggemønstret bevares.
%     Konsekvens: modellens Isc passer med T0 pr. konstruktion og valideres
%     ikke. Voc, FF, Pmax, V_mpp, trinstrømme og antal trin valideres stadig.

if nargin < 1, p = struct(); end
p = standard(p, 'G0', 1000);
p = standard(p, 'T0', 25);
p = standard(p, 'testcelle', 'C5');
p = standard(p, 'T3_samme', 'D5');
p = standard(p, 'T3_anden', 'E5');
p = standard(p, 'T5_celler', {'B5', 'C5', 'E5'});
p = standard(p, 'T_eff', struct('SN50', 0.5, 'FN', 0.7));
p = standard(p, 'fX', [NaN NaN NaN]);

G0 = p.G0;
tc = p.testcelle;
K  = struct('id', {}, 'test', {}, 'G', {}, 'Gnom', {}, 'T', {}, 'note', {});

%% T0 - uskygget baseline
K = tilfoej(K, p, 'T0', 'T0', uskygget(G0), G0, 'Uskygget');

%% D0 - mørk IV (kræver at modellens spændingssweep går over Voc)
% Uafhængig af indstrålingen, så D0 er upåvirket af den manglende kalibrering.
K = tilfoej(K, p, 'D0', 'D0', zeros(60, 1), 0, 'Mørk IV, G = 0');

%% K1 - uniformitetstjek uden referencecelle
% Rotationstest: uskygget i normal position og drejet 180 grader.
K = tilfoej(K, p, 'K1-rot0',   'K1', uskygget(G0), G0, 'Uskygget, normal position');
K = tilfoej(K, p, 'K1-rot180', 'K1', uskygget(G0), G0, 'Uskygget, drejet 180 grader');
% Trinstrømskort: én celle 50 % skygget ad gangen. Med uniform G forudsiger
% modellen samme I_trin/Isc i alle positioner; afvigelser i målingen er den
% lokale indstråling (C5 måles tre gange som drifttjek, samme konfiguration).
for c = {'C5', 'A1', 'F1', 'A10', 'F10'}
    K = tilfoej(K, p, ['K1-' c{1}], 'K1', skyg(uskygget(G0), c, 0.5, G0), G0, ...
        sprintf('%s 50 %% (trinstrømskort)', c{1}));
end

%% T1 - topologi (100 % skygge)
T1 = { 'C5'        , 'Reference: én delstreng ude'
       'C5 C6'     , 'Samme kolonne, naboceller'
       'C5 C10'    , 'Samme kolonne, modsatte ende'
       'C5 D5'     , 'Nabokolonne (samme delstreng?)'
       'C5 B5'     , 'Nabokolonne (anden delstreng?)'
       'C5 E5'     , 'To kolonner væk'
       'A5 F5'     , 'Yderkolonnerne' };
for i = 1:size(T1, 1)
    celler = strsplit(T1{i, 1});
    G = skyg(uskygget(G0), celler, 1, G0);
    K = tilfoej(K, p, ['T1-' strjoin(celler, '-')], 'T1', G, G0, T1{i, 2});
end

%% T2 - delvis skygge af testcellen
for f = 10:10:100
    G = skyg(uskygget(G0), {tc}, f/100, G0);
    K = tilfoej(K, p, sprintf('T2-%s-f%d', tc, f), 'T2', G, G0, sprintf('%s %d %%', tc, f));
end
for j = 1:numel(p.fX)
    if ~isnan(p.fX(j))
        G = skyg(uskygget(G0), {tc}, p.fX(j)/100, G0);
        K = tilfoej(K, p, sprintf('T2-%s-fX%d', tc, j), 'T2', G, G0, ...
            sprintf('%s %g %% (ekstra punkt)', tc, p.fX(j)));
    end
end

%% T3 - samme skyggeareal, forskellig fordeling
K = tilfoej(K, p, 'T3-a', 'T3', skyg(uskygget(G0), {tc}, 1, G0), G0, ...
    sprintf('%s 100 %%', tc));
G = skyg(skyg(uskygget(G0), {tc}, 0.5, G0), {p.T3_samme}, 0.5, G0);
K = tilfoej(K, p, 'T3-b', 'T3', G, G0, sprintf('%s 50 %% + %s 50 %%', tc, p.T3_samme));
G = skyg(skyg(uskygget(G0), {tc}, 0.5, G0), {p.T3_anden}, 0.5, G0);
K = tilfoej(K, p, 'T3-c', 'T3', G, G0, sprintf('%s 50 %% + %s 50 %%', tc, p.T3_anden));

%% T4 - rækkeskygge
% Portræt: skyggekanten er parallel med kortsiden og dækker række 10 (A10-F10).
% Landskab: skyggekanten er parallel med langsiden og dækker kolonne A (A1-A10).
raekke10  = arrayfun(@(c) sprintf('%c10', c), 'A':'F', 'UniformOutput', false);
kolonne_A = arrayfun(@(r) sprintf('A%d', r), 1:10, 'UniformOutput', false);
for f = [25 50 75 100]
    K = tilfoej(K, p, sprintf('T4-P%d', f), 'T4', skyg(uskygget(G0), raekke10, f/100, G0), ...
        G0, sprintf('Række 10, %d %% af cellehøjden', f));
end
for f = [25 50 75 100]
    K = tilfoej(K, p, sprintf('T4-L%d', f), 'T4', skyg(uskygget(G0), kolonne_A, f/100, G0), ...
        G0, sprintf('Kolonne A, %d %% af cellebredden', f));
end

%% T5 - forskellige skyggegrader på flere delstrenge
c = p.T5_celler;
G = skyg(skyg(uskygget(G0), c(1), 0.25, G0), c(2), 0.50, G0);
K = tilfoej(K, p, 'T5-a', 'T5', G, G0, sprintf('%s 25 %%, %s 50 %%', c{1}, c{2}));
G = skyg(G, c(3), 0.75, G0);
K = tilfoej(K, p, 'T5-b', 'T5', G, G0, sprintf('%s 25 %%, %s 50 %%, %s 75 %%', c{1}, c{2}, c{3}));

%% T6 - reduceret indstråling på hele modulet
% Intensiteten er ukalibreret: niveauerne er nominelle andele af 1 sol. Efter
% lab bestemmes G_eff for hver T6-måling ud fra dens egen Isc.
for Gn = [1000 800 600 400 200]
    K = tilfoej(K, p, sprintf('T6-G%d', Gn), 'T6', uskygget(Gn), Gn, ...
        sprintf('Uniform, nominelt %d %% af 1 sol', round(100*Gn/1000)));
end

%% T7 - uigennemsigtig vs. translucent
mat = fieldnames(p.T_eff);
for m = 1:numel(mat)
    Te = p.T_eff.(mat{m});
    % Translucent: hele cellen dæmpet til T_eff*G0
    G = uskygget(G0);  G(celle_idx(tc)) = Te*G0;
    K = tilfoej(K, p, sprintf('T7-%s-T', mat{m}), 'T7', G, G0, ...
        sprintf('%s over hele %s, T_eff = %.3f', mat{m}, tc, Te));
    % Uigennemsigtig: andelen 1 - T_eff dækket -> samme G i modellen
    G = skyg(uskygget(G0), {tc}, 1 - Te, G0);
    K = tilfoej(K, p, sprintf('T7-%s-O', mat{m}), 'T7', G, G0, ...
        sprintf('Maske over %.1f %% af %s', 100*(1 - Te), tc));
    K = tilfoej(K, p, sprintf('T7-%s-Ovink', mat{m}), 'T7', G, G0, ...
        sprintf('Maske over %.1f %% af %s, vinkelret', 100*(1 - Te), tc));
end
end

%% ---------------------------------------------------------------------------
function k = celle_idx(navn)
%CELLE_IDX  Cellenavn ('A1'...'F10') -> indeks i G_cell (1...60).
navn = upper(strtrim(navn));
kol  = double(navn(1)) - double('A') + 1;     % 1...6
r    = str2double(navn(2:end));               % 1...10
if kol < 1 || kol > 6 || isnan(r) || r < 1 || r > 10 || r ~= round(r)
    error('celle_idx: ukendt celle "%s" (brug A-F og 1-10)', navn);
end
s = ceil(kol/2);                 % delstreng 1, 2, 3
h = mod(kol - 1, 2);             % 0 = venstre, 1 = højre kolonne i parret
if h == 0
    k = 20*(s - 1) + r;          % ned ad venstre kolonne: A1 = 1 ... A10 = 10
else
    k = 20*(s - 1) + 21 - r;     % op ad højre kolonne:  B10 = 11 ... B1 = 20
end
end

function G = uskygget(Gn)
G = Gn*ones(60, 1);
end

function G = skyg(G, celler, f, G0)
% Sætter G = (1 - f)*G0 i de angivne celler.
for i = 1:numel(celler)
    G(celle_idx(celler{i})) = (1 - f)*G0;
end
end

function K = tilfoej(K, p, id, test, G, Gnom, note)
K(end + 1) = struct('id', id, 'test', test, 'G', G, 'Gnom', Gnom, 'T', p.T0, 'note', note);
end

function p = standard(p, felt, vaerdi)
if ~isfield(p, felt) || isempty(p.(felt)), p.(felt) = vaerdi; end
end
