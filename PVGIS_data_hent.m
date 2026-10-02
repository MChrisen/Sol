url = "https://re.jrc.ec.europa.eu/api/v5_3/tmy?lat=57.048&lon=9.919&outputformat=json";
d   = webread(url);

Gb_n = [d.outputs.tmy_hourly.Gb_n_]';
Gd_h = [d.outputs.tmy_hourly.Gd_h_]';
Temp = [d.outputs.tmy_hourly.T2m]';
