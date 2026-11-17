function P = model_call(G)
G = G(:);
if all (G <= 0.01)
    P = 0;
    return
end

in = Simulink.SimulationInput('SOLTEST');
in = in.setModelParameter('FastRestart','on');
in = in.setVariable('G_cell', G);
out = sim(in);
P = max(out.Power.Data);