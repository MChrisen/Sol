function y = solpos_step(t)
[a, g, z] = solar_position1(t);
y = [a; g; z];
end