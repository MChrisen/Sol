% Modul (fra Python) REC245PE fit
%IL_m  = 8.817834871778226;
%I0_m  = 7.892047644757799e-12;
%a_m   = 1.3385143590566657;
%Rs_m  = 0.3502783235015789;
%Rsh_m = 172.83271208360873;
%Rsh_m = 10e10;
%alpha_m = 0.002112; %A/K
Ns    = 60;

% Parametre fra måling-fit
IL_m  = 8.662874196;
I0_m  = 1.970411761e-08;
a_m   = 1.83324586;
Rs_m  = 0.3796199739;
Rsh_m = 296.5974308;
alpha_m = 0.002112; %A/K

% En celle
IL_ref  = IL_m;
I0_ref  = I0_m;
a_ref   = a_m  / Ns;      % 0.  02439 V
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
%G_cell(2) = 500;

% Geometri mm.
beta_p      = 35;          % hældning
gamma_p     = 180;         % modulazimut, samme konvention som gamma_s (syd = 180)
GCR         = 0.991/1.69;        % dækningsgrad L/d
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


%Kald til cellemodel
load_system('SOLTEST');
set_param('SOLTEST', 'FastRestart', 'off');
set_param('SOLTEST', 'SignalLogging', 'off', 'InspectSignalLogs', 'off', ...
    'SaveOutput', 'off', 'SaveState', 'off', 'SaveFinalState', 'off', 'SimscapeLogType', 'none');
set_param('SOLTEST', 'FastRestart', 'on');
Simulink.sdi.clear;