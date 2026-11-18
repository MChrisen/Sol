function K = ekstra_konfigurationer(p)
%EKSTRA_KONFIGURATIONER  Ekstra skyggetilfælde (T8-T13) til validering i lab.
%   Supplerer logskema_konfigurationer.m (T0-T7, K1, D0) uden at gentage dem.
%   Samme struct-format og samme cellelayout, så K kan sættes sammen med
%   logskemaets K og køres af både koer_skyggetest.m og
%   koer_logskema_simuleringer.m.
%
%   Felter: id, test, G (60x1), Gnom, T, note
%   p.G0 [1000], p.T0 [25]
%
%   CELLELAYOUT (som i logskema_konfigurationer.m)
%     Kolonne A-F fra venstre, række 1-10 fra samledåsen.
%     Delstreng 1 = A-B, 2 = C-D, 3 = E-F (bekræftes i T1).
%   SKYGGE: andel f af en celle -> G = (1 - f)*Gnom.
%
%   Noten starter med [A] for de tilfælde, der skelner skarpest mellem
%   rigtig og forkert model, og [B] for supplerende tilfælde.

if nargin < 1, p = struct(); end
p  = standard(p, 'G0', 1000);
p  = standard(p, 'T0', 25);
G0 = p.G0;
K  = struct('id', {}, 'test', {}, 'G', {}, 'Gnom', {}, 'T', {}, 'note', {});

%% REF - uskygget reference (bruges som baggrund i sammenligningsplots)
K = tilf(K, p, 'REF', 'REF', G0, 'Uskygget reference');

%% T8 - antal skyggede delstrenge
% Én celle pr. delstreng. 100 %: ét trin pr. bypasset delstreng.
% Samme grad i alle tre delstrenge: ingen trin, kun lavere strøm.
K = tilf(K, p, 'T8-AC-100',  'T8', G0, ...
    '[A] A5+C5 100 %: to delstrenge ude, MPP ved ca. 1/3 Voc', rk('AC', 5), 1);
K = tilf(K, p, 'T8-ACE-100', 'T8', G0, ...
    '[A] A5+C5+E5 100 %: alle ude, P ~ 0 (kun lækstrøm)', rk('ACE', 5), 1);
K = tilf(K, p, 'T8-ACE-50',  'T8', G0, ...
    '[A] A5+C5+E5 50 %: ingen trin, I ~ halv, Vmp ~ uskygget', rk('ACE', 5), 0.5);
K = tilf(K, p, 'T8-ACE-25',  'T8', G0, ...
    '[B] A5+C5+E5 25 %: ingen trin, I ~ 3/4', rk('ACE', 5), 0.25);
K = tilf(K, p, 'T8-AC-50',   'T8', G0, ...
    '[A] A5+C5 50 %: ét trin ved ca. 1/3 Voc; Pmax ~ T8-ACE-50', rk('AC', 5), 0.5);

%% T9 - den værste celle i en delstreng bestemmer
% Alle tilfælde her bør give (næsten) samme IV som T9-ref.
K = tilf(K, p, 'T9-ref',   'T9', G0, '[A] C5 70 % alene (reference for T9)', {'C5'}, 0.7);
K = tilf(K, p, 'T9-b',     'T9', G0, '[A] C5 70 % + D5 30 %: ~ T9-ref', ...
    {'C5'}, 0.7, {'D5'}, 0.3);
K = tilf(K, p, 'T9-c',     'T9', G0, '[B] C5 70 % + C6-C8 30 %: ~ T9-ref', ...
    {'C5'}, 0.7, rk('C', 6:8), 0.3);
K = tilf(K, p, 'T9-d',     'T9', G0, '[B] C5 + D5 begge 70 %: ~ T9-ref, trin lidt lavere V', ...
    rk('CD', 5), 0.7);
K = tilf(K, p, 'T9-grad',  'T9', G0, ...
    '[A] Gradueret kant C7-C10 = 25/50/75/100 %: ~ én celle 100 % (T1-C5)', ...
    {'C7'}, 0.25, {'C8'}, 0.5, {'C9'}, 0.75, {'C10'}, 1);

%% T10 - antal skyggede celler i samme delstreng
% 100 %: delstrengen er bypasset uanset antal -> alle ~ T1-C5.
K = tilf(K, p, 'T10-n5-100',  'T10', G0, '[B] C1-C5 100 %: ~ T1-C5', rk('C', 1:5), 1);
K = tilf(K, p, 'T10-n10-100', 'T10', G0, '[B] Kolonne C 100 %: ~ T1-C5', rk('C', 1:10), 1);
K = tilf(K, p, 'T10-n20-100', 'T10', G0, ...
    '[A] Hele delstreng 2 (C+D) 100 %: ~ T1-C5', rk('CD', 1:10), 1);
% 50 %: samme trinstrøm, men trinnets spænding falder svagt med antal celler.
K = tilf(K, p, 'T10-n1-50',   'T10', G0, '[B] C5 50 % (reference, = T2-C5-f50)', {'C5'}, 0.5);
K = tilf(K, p, 'T10-n10-50',  'T10', G0, '[B] Kolonne C 50 %', rk('C', 1:10), 0.5);
K = tilf(K, p, 'T10-n20-50',  'T10', G0, ...
    '[A] Hele delstreng 2 50 %: samme trinstrøm som n1, trin ved lidt lavere V', ...
    rk('CD', 1:10), 0.5);

%% T11 - to delstrenge med forskellig grad (trin smelter sammen / skilles ad)
% Ved ens grad (T8-AC-50) er der ét trin; jo større forskel, jo tydeligere to.
K = tilf(K, p, 'T11-40-60', 'T11', G0, '[B] A5 40 % + C5 60 %', {'A5'}, 0.4, {'C5'}, 0.6);
K = tilf(K, p, 'T11-30-70', 'T11', G0, '[A] A5 30 % + C5 70 %: tre tydelige trin', ...
    {'A5'}, 0.3, {'C5'}, 0.7);
K = tilf(K, p, 'T11-10-90', 'T11', G0, '[B] A5 10 % + C5 90 %', {'A5'}, 0.1, {'C5'}, 0.9);

%% T12 - realistiske skyggeformer
% Samme skyggeareal (8 celler), forskellig orientering i forhold til delstrengene.
K = tilf(K, p, 'T12-blok-lodret',  'T12', G0, ...
    '[A] C4-D7 (8 celler, kun delstreng 2) 100 %: tab ~ 1/3', rk('CD', 4:7), 1);
K = tilf(K, p, 'T12-blok-vandret', 'T12', G0, ...
    '[A] B5-E6 (8 celler, alle delstrenge) 100 %: P ~ 0', rk('BCDE', 5:6), 1);
% Diagonal skygge fra en mast/antenne
diag6 = {'A1', 'B2', 'C3', 'D4', 'E5', 'F6'};
K = tilf(K, p, 'T12-diag-100',  'T12', G0, '[B] Diagonal A1-F6 100 %: P ~ 0', diag6, 1);
K = tilf(K, p, 'T12-diag-50',   'T12', G0, '[A] Diagonal A1-F6 50 %: ingen trin, I ~ halv', diag6, 0.5);
K = tilf(K, p, 'T12-diag3-100', 'T12', G0, '[B] Diagonal A1-C3 100 %: to delstrenge ude', ...
    diag6(1:3), 1);
% Hjørneskygge (blade, sne, snavs i nederste hjørne)
K = tilf(K, p, 'T12-hjoerne1', 'T12', G0, '[B] A9-B10 100 %: kun delstreng 1', rk('AB', 9:10), 1);
K = tilf(K, p, 'T12-hjoerne2', 'T12', G0, '[B] Trekant A8-A10, B9-B10, C10 100 %: delstreng 1+2', ...
    {'A8', 'A9', 'A10', 'B9', 'B10', 'C10'}, 1);

%% T13 - skygge ved lav indstråling (linearitet)
% Trinstrøm/Isc bør være den samme som ved 1000 W/m^2.
Gl = 0.5*G0;
K = tilf(K, p, 'T13-ref500', 'T13', Gl, '[B] Uskygget ved 50 % intensitet', {}, 0);
K = tilf(K, p, 'T13-C5-50',  'T13', Gl, '[A] C5 50 % ved 50 % intensitet: I_trin/Isc ~ T2-C5-f50', ...
    {'C5'}, 0.5);
K = tilf(K, p, 'T13-AC-30-70', 'T13', Gl, '[B] A5 30 % + C5 70 % ved 50 % intensitet', ...
    {'A5'}, 0.3, {'C5'}, 0.7);
end

%% ---------------------------------------------------------------------------
function K = tilf(K, p, id, test, Gn, note, varargin)
% varargin: par af {celler}, f. Senere par overskriver tidligere.
G = Gn*ones(60, 1);
for j = 1:2:numel(varargin)
    c = varargin{j};  f = varargin{j + 1};
    for i = 1:numel(c)
        G(celle_idx(c{i})) = (1 - f)*Gn;
    end
end
K(end + 1) = struct('id', id, 'test', test, 'G', G, 'Gnom', Gn, 'T', p.T0, 'note', note);
end

function n = rk(kol, raekker)
% rk('CD', 4:7) -> {'C4','D4','C5',...}
[KK, RR] = ndgrid(double(kol), raekker);
n = arrayfun(@(k, r) sprintf('%c%d', k, r), KK(:), RR(:), 'UniformOutput', false).';
end

function k = celle_idx(navn)
% Samme mapping som logskema_konfigurationer.m: 'A1'...'F10' -> 1...60.
navn = upper(strtrim(navn));
kol  = double(navn(1)) - double('A') + 1;
r    = str2double(navn(2:end));
if kol < 1 || kol > 6 || isnan(r) || r < 1 || r > 10 || r ~= round(r)
    error('celle_idx: ukendt celle "%s" (brug A-F og 1-10)', navn);
end
s = ceil(kol/2);
if mod(kol - 1, 2) == 0
    k = 20*(s - 1) + r;          % A1 = 1 ... A10 = 10
else
    k = 20*(s - 1) + 21 - r;     % B10 = 11 ... B1 = 20
end
end

function p = standard(p, felt, vaerdi)
if ~isfield(p, felt) || isempty(p.(felt)), p.(felt) = vaerdi; end
end