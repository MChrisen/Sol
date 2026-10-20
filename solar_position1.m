function [alpha, gamma, theta_z] = solar_position1(t)
alpha   = 0;
gamma   = 0;
theta_z = 0;

lat = 57.05;
lon = 9.92;

t_utc = datetime(2025,1,1,0,0,0,'TimeZone','UTC') + seconds(t); %Beregner datatime ud fra simuleringstidspunkt


% t_utc: datetime UTC
% lat, lon: grader (lon øst-positiv)
dnum = datenum(datetime(t_utc,'TimeZone','UTC')); % Dette giver en talværdi der repræsenterer det specifikke tidspunkt.
yy   = year(t_utc);
dayn = dnum - datenum(yy,1,1) + 1;    % giver nummer dag på året, 30 jan = 30
gy = 2*pi*(dayn-1)/365; % dagvinkel

% beregner aksehældning (deklination varierer mellem plus minus 23.4)
%delta_deg = -23.44 * cosd(360/365 * (dayn + 10)); % Cooper
delta = 0.006918 ...
    - 0.399912*cos(gy)   + 0.070257*sin(gy) ...
    - 0.006758*cos(2*gy) + 0.000907*sin(2*gy) ...
    - 0.002697*cos(3*gy) + 0.001480*sin(3*gy); % Spencer
delta_deg = rad2deg(delta);

%equation of time, Spencer
utc_hour = hour(t_utc) + minute(t_utc)/60 + second(t_utc)/3600;

Et = 229.18*(0.000075 + 0.001868*cos(gy) - 0.032077*sin(gy) - 0.014615*cos(2*gy) - 0.040849*sin(2*gy));  % minutter
solar_hour = utc_hour + lon/15 + Et/60; % 15° = 1 time (I dette tilfælde betyder det at solen står direkte syd kl 12 utc + 0,66(lon/15))

% beregner soltid, timevinkel
omega_deg  = 15 * (solar_hour - 12); % 0 ved sand middag (timevinkel)
omega_deg = mod(omega_deg + 180, 360) - 180;

% beregner solhøjde (alpha)
phi = lat;
cosz = sind(phi).*sind(delta_deg) + cosd(phi).*cosd(delta_deg).*cosd(omega_deg); % Her bestemmes cos til zenit
cosz = min(max(cosz,-1),1); %cos til zenit er en faktor fra -1 til 1
theta_z = acosd(cosz); % finder vinklen
alpha   = 90 - theta_z; % Omregner fra zenit til solhøjde (Vinkel ift. over observatør til vinkel over horisonten)

% azimut (gamma)
cos_az = (sind(delta_deg) - sind(phi).*cosd(theta_z)) ./ (cosd(phi).*sind(theta_z));
cos_az = min(max(cos_az,-1),1);
gamma  = acosd(cos_az); % azimutvinklen (denne ligger fra 0 til 180)
gamma(omega_deg > 0) = 360 - gamma(omega_deg > 0); %da gamma ikke dækker alle 360 grader benyttes timevinklen til at bestemme om den er øst eller vest
end