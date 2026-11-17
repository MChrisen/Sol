function [P, geo] = skygge_parametre(opt)
%SKYGGE_PARAMETRE  Parametre og cellegeometri til "Celleindstråling" for én konfiguration
%   [P, geo] = skygge_parametre()                                       standardværdier
%   [P, geo] = skygge_parametre('GCR', 0.3, 'orientering', 'landskab')  én konfiguration
%   P   Det, Simulink-blokkene bruger, samlet i én struct. Kun tal med faste
%       størrelser (skalarer og 60x1), så P kan skiftes mellem kørsler uden
%       at modellen skal kompileres igen. Sendes til en kørsel med
%       in = in.setVariable('P', P).
%   geo Cellernes kanter, F_d, kolonne, række og lag (alle 60x1, indekseret
%       som G_cell i pv_modul) samt de valgte indstillinger (geo.opt).
arguments
    opt.GCR         (1,1) double {mustBePositive} = 0.40   % dækningsgrad L/d
    opt.orientering (1,:) char {mustBeMember(opt.orientering, {'portraet', 'landskab'})} = 'portraet'
    opt.beta_p      (1,1) double = 35      % hældning
    opt.gamma_p     (1,1) double = 180     % modulazimut fra nord med uret (syd = 180), som gamma_s
    opt.rho         (1,1) double = 0.20    % albedo
    opt.b0          (1,1) double = 0.05    % ASHRAE-koefficient (0 = ingen refleksionstab)
    opt.c_celle     (1,1) double = 0.156   % cellens sidelængde. Mål den på panelet
    opt.p_celle     (1,1) double = 0.159   % pitch: celle + mellemrum. Mål den på panelet
    opt.m           (1,1) double = NaN     % modulets underkant -> første celle. NaN: cellefeltet centreret
    opt.L           (1,1) double = NaN     % rækkens længde langs hældningen. NaN: fra REC245PE og orienteringen
end
 
% ---- 1) Rækkens længde og rækkeafstand --------------------------------------
% REC245PE er 1665 x 991 mm med 6 x 10 celler.
switch opt.orientering
    case 'portraet'
        L = 1.665;  n_lag = 10;            % langsiden langs hældningen
    case 'landskab'
        L = 0.991;  n_lag = 6;             % kortsiden langs hældningen
end
if ~isnan(opt.L)
    L = opt.L;                             % bruges af testen med normaliseret geometri
end
m = opt.m;
if isnan(m)
    m = (L - ((n_lag - 1)*opt.p_celle + opt.c_celle))/2;   % antager cellefeltet centreret
end
d = L/opt.GCR;
 
% ---- 2) Fra celleindeks k til kolonne og række -------------------------------
% Samme nummerering som celle_idx i logskema_konfigurationer.m, bare den
% modsatte vej. Én bypass-diode pr. kolonnepar (A-B, C-D, E-F). Strengen løber
% ned ad venstre kolonne (række 1 -> 10) og op ad højre (række 10 -> 1).
kol = zeros(60, 1);
rk  = zeros(60, 1);
for c = 1:6
    for r = 1:10
        s = ceil(c/2);                     % delstreng 1, 2 eller 3
        if mod(c - 1, 2) == 0
            k = 20*(s - 1) + r;            % venstre kolonne i parret
        else
            k = 20*(s - 1) + 21 - r;       % højre kolonne i parret
        end
        kol(k) = c;
        rk(k)  = r;
    end
end
 
% ---- 3) Lag og kanter langs hældningen --------------------------------------
% Skyggen afhænger kun af, hvor højt cellen sidder.
switch opt.orientering
    case 'portraet'
        lag = 11 - rk;                     % samledåsen vender op, så række 10 sidder nederst
    case 'landskab'
        lag = kol;                         % kolonne A sidder nederst (som i logskemaets T4)
end
u_lo = m + (lag - 1)*opt.p_celle;
u_hi = u_lo + opt.c_celle;
if any(u_hi > L + 1e-9)
    error('skygge_parametre: cellerne rækker ud over L.');
end
 
% ---- 4) Synsfaktor til himlen i cellens midtpunkt ----------------------------
% psi er afskærmningsvinklen til den forreste rækkes overkant (afsnittet om
% diffus indstråling). Den afhænger kun af geometrien og regnes derfor her.
u_mid = (u_lo + u_hi)/2;
psi   = atan2d((L - u_mid)*sind(opt.beta_p), d - (L - u_mid)*cosd(opt.beta_p));
Fd    = (1 + cosd(opt.beta_p + psi))/2;
 
% ---- 5) Til Simulink: samme felter i samme rækkefølge hver gang ---------------
P = struct('beta_p', opt.beta_p, 'gamma_p', opt.gamma_p, 'rho', opt.rho, 'b0', opt.b0, ...
           'L', L, 'd', d, 'u_lo', u_lo, 'u_hi', u_hi, 'Fd', Fd);
 
% ---- 6) Til efterbehandling ----------------------------------------------------
geo = struct('u_lo', u_lo, 'u_hi', u_hi, 'Fd', Fd, 'kol', kol, 'rk', rk, 'lag', lag, ...
             'L', L, 'm', m, 'opt', opt);
end