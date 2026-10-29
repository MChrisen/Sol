% Modul (fra Python) REC245PE fit
IL_m  = 8.692061235050982;
I0_m  = 1.0277696567226056e-10;
a_m   = 1.4795997947846946;
Rs_m  = 0.3170328218025026;
Rsh_m = 228.15615554914478;
%Rsh_m = 10e10;
alpha_m = 0.0064232; %A/K
Ns    = 60;

% En celle
IL_ref  = IL_m;
I0_ref  = I0_m;
a_ref   = a_m  / Ns;      % 0.02439 V
Rs      = Rs_m / Ns;      % 0.00566 Ohm
Rsh_ref = Rsh_m / Ns;     
alpha   = alpha_m;

% Sweep parametre
T_sweep = 1;
V_oc = 37.2;
V_oc_single = 22.8/Ns;

% Celler
G_cell = 1000 * ones(Ns,1);
%G_cell(1) = 0;
%G_cell(1) = 500;

% Geometri mm.
beta_p      = 35;          % hældning
gamma_p     = 180;         % modulazimut, samme konvention som gamma_s (syd = 180)
GCR         = 0.5;        % dækningsgrad L/d
rho         = 0.20;        % albedo
b0          = 0.05;        % ASHRAE-koefficient
orientering = 'landskab';  % 'portraet' eller 'landskab'
c_celle     = 0.156;       % cellens sidelængde [m]  <- mål
p_celle     = 0.159;       % pitch, celle + mellemrum [m]  <- mål
m           = NaN;         % underkant -> første celle [m]


% Tid og vejrdata
dt = 600;                                                   % tidsskridt [s]
load('pvgis_data.mat', 't_k', 'Gh', 'Gbn', 'Gdh', 'off');   % til lookup-tabellerne

% Alt til Celleindstråling-subsystemet
[P, geo] = skygge_parametre('GCR', GCR, 'orientering', orientering, ...
    'beta_p', beta_p, 'gamma_p', gamma_p, 'rho', rho, 'b0', b0, ...
    'c_celle', c_celle, 'p_celle', p_celle, 'm', m);