%% PVGIS_DATA  PVGIS-TMY til lookup-tabellerne, med tidsvektor i UTC-sekunder.
%% 1. Hent TMY fra PVGIS som JSON
url  = 'https://re.jrc.ec.europa.eu/api/v5_3/tmy?lat=57.05&lon=9.92&outputformat=json';
data = webread(url, weboptions('Timeout', 60));
tmy  = struct2table(data.outputs.tmy_hourly);
disp(tmy.Properties.VariableNames)
Gh   = tmy.G_h_;                         % G(h):  global vandret        [W/m^2]
Gbn  = tmy.Gb_n_;                        % Gb(n): direkte normal        [W/m^2]
Gdh  = tmy.Gd_h_;                        % Gd(h): diffus vandret        [W/m^2]
% Tidsforskydningen står i JSON under inputs.location. I CSV-filen står den
off  = data.inputs.location.irradiance_time_offset;     % [h]

%% 2. Tidsvektor: hvornår hver måling gælder, i sekunder fra 1. januar kl. 00 UTC
% Række k har tidsstemplet (k-1) timer, men værdien hører til (k-1) timer + off.
assert(numel(Gh) == 8760 && numel(Gbn) == 8760 && numel(Gdh) == 8760, ...
    'Forventer 8760 timeværdier');
Gh = Gh(:);  Gbn = Gbn(:);  Gdh = Gdh(:);
k   = (1:8760).';
t_k = (k - 1)*3600 + off*3600;          % [s]

%% 3. Udfyld manglende satellitdata (rækker med G_h = 0, selvom solen er oppe)
timer = [1528 1529 1856 2817 2821 3993 3995 6295 6733  6804 6828];
% 5/3 kl. 15 og 16, 19/3 kl. 07, 28/4 kl. 08 og 12, 16/6 kl. 08 og 10,
% 20/9 kl. 06, 8/10 kl. 12, 11/10 kl. 11, 12/10 kl. 11
dage  = [60 65];                         % 1/3 og 6/3: hele døgn uden stråling

% Enkelte timer: lineær interpolation mellem timen før og efter
Gh(timer) = NaN;  Gbn(timer) = NaN;  Gdh(timer) = NaN;
Gh  = fillmissing(Gh,  'linear');
Gbn = fillmissing(Gbn, 'linear');
Gdh = fillmissing(Gdh, 'linear');

% Hele døgn: timevis middel af døgnet før og døgnet efter
for d = dage
    i = (d - 1)*24 + (1:24);
    Gh(i)  = (Gh(i - 24)  + Gh(i + 24))/2;
    Gbn(i) = (Gbn(i - 24) + Gbn(i + 24))/2;
    Gdh(i) = (Gdh(i - 24) + Gdh(i + 24))/2;
end

save('pvgis_data.mat', 't_k', 'Gh', 'Gbn', 'Gdh', 'off');
fprintf('Gemt pvgis_data.mat: offset = %.3f h (%.0f min efter hel time)\n', off, off*60);
