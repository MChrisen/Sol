% Modul (fra Python)
IL_m  = 8.627;
I0_m  = 4.5202e-11;
a_m   = 0.87812;
Rs_m  = 0.20368;
%Rsh_m = 264.82;
Rsh_m = 10e10;
alpha_m = 0.00431;
Ns    = 36;

% En celle
IL_ref  = IL_m;
I0_ref  = I0_m;
a_ref   = a_m  / Ns;      % 0.02439 V
Rs      = Rs_m / Ns;      % 0.00566 Ohm
Rsh_ref = Rsh_m / Ns;     
alpha   = alpha_m;

% andet
T_sweep = 1;
V_oc = 22.8;
V_oc_single = 22.8/Ns;

% Celler
G_cell = 1000 * ones(Ns,1);
%G_cell(1) = 0;
G_cell(1) = 500;
