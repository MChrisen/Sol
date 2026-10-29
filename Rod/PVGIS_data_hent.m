url = "https://re.jrc.ec.europa.eu/api/v5_3/tmy?lat=57.048&lon=9.919&outputformat=json";
d   = webread(url);

G_h = [d.outputs.tmy_hourly.G_h_]';
G_bn = [d.outputs.tmy_hourly.Gb_n_]';
G_dh = [d.outputs.tmy_hourly.Gd_h_]';
Temp = [d.outputs.tmy_hourly.T2m]';

ts   = string({d.outputs.tmy_hourly.time_UTC_})';
tUTC = datetime(ts, 'InputFormat','yyyyMMdd:HHmm', 'TimeZone','UTC');

tUTC.Year = 2023;                                   % ikke skudår
t = seconds(tUTC - datetime(2023,1,1,'TimeZone','UTC'));   % s siden 1 Jan 00:00 UTC

assert(numel(t) == 8760 && all(diff(t) == 3600), 'Noget galt')
