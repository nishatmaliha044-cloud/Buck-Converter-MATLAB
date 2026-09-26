function results=buckConverterMain

clc; close all;
p=buckParameters('defaults'); x0=[p.Vref/p.R;p.Vref];

% Nominal simulation and one-parameter studies.
nominalCycles=700;
KpValues=linspace(10,35,151);
VinValues=linspace(8,12,61);
opt.nCycles=700; opt.discardCycles=350; opt.keep=250;
opt.useContinuation=true; opt.verbose=true; opt.computeLLE=true;

mapVin=linspace(8,12,9);
mapKp=linspace(4,36,17);
mapOpt.nCycles=700; mapOpt.discardCycles=350; mapOpt.keep=250;
mapOpt.useContinuation=false; mapOpt.verbose=false; mapOpt.computeLLE=false;

fprintf('\nMODULAR SWITCHED BUCK-CONVERTER STUDY\n');
theory=buckTheory(p);
nominal=buckAnalyze(p,x0,nominalCycles,100);
verification=buckVerify(p,nominal.sim);

bifurcation=buckSweep(p,'Kp',KpValues,x0,opt);
vinOpt=opt; vinOpt.computeLLE=false;
vinBifurcation=buckSweep(p,'Vin',VinValues,x0,vinOpt);
stabilityMap=buckStabilityMap(p,'Vin',mapVin,'Kp',mapKp,x0,mapOpt);

printSummary(p,theory,nominal,verification);
buckPlotResults('all',nominal,bifurcation,vinBifurcation,stabilityMap,verification);

results=struct('params',p,'theory',theory,'nominal',nominal,...
    'verification',verification,'bifurcation',bifurcation,...
    'vinBifurcation',vinBifurcation,'stabilityMap',stabilityMap);
end

function printSummary(p,th,nom,v)
fprintf('\nL=%.3g H, C=%.3g F, fs=%.1f kHz, Kp=%.3g\n',p.L,p.C,p.fsw/1e3,p.Kp);
fprintf('Ideal: D=%.4f, Vo=%.4f V, IL=%.4f A\n',th.idealDuty,th.idealVout,th.idealMeanIL);
fprintf('Simulation: %s, Vo=%.5f V, D=%.5f, LLE=%.4g/cycle\n',...
    nom.class.label,nom.metrics.meanVout,nom.metrics.meanDuty,nom.class.llePerCycle);
fprintf('Errors: Vo=%+.3f%%, IL=%+.3f%%, duty=%+.3f%%\n',...
    v.voutErrorPercent,v.iLErrorPercent,v.dutyErrorPercent);
end
