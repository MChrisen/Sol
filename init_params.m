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

% række geometri
L = 0; % Skrå længde af modul
P = 0; %Pitch, vandret afstand mellem ens punkter på to naborækker (underkant til underkant)
beta = 0; %Panelts hældning fra vandret
gamma_m = 0; %modulets azimut. 

GCR = L/P;
