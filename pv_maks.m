function Pmax = pv_maks(G)
%PV_MAKS  Kører cellemodellen med indstrålingen G (60x1) og returnerer maks effekt [W].
%   Kaldes fra MATLAB Function-blokken "Cellemodel" i årsmodellen i hvert tidsskridt.

if max(G) < 1               % nat: ingen grund til at køre cellemodellen
    Pmax = 0;
    return
end

assignin('base', 'G_cell', G);     % Constant-blokkene i pv_modul læser G_cell(1) ... G_cell(60)
out = sim('SOLTEST');

p = out.Power;
if isa(p, 'timeseries')
    p = p.Data;
end
Pmax = max(p);
end
