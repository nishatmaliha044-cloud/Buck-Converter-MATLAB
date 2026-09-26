function ver=buckVerify(p,sim)

th=buckTheory(p);
duration=sim.t(end)-sim.t(1);
ver.theory=th;
ver.simMeanVout=trapz(sim.t,sim.vO)/duration;
ver.simMeanIL=trapz(sim.t,sim.iL)/duration;
n=numel(sim.cycle.duty); 
idx=max(1,n-349):n;
ver.simMeanDuty=mean(sim.cycle.duty(idx));
ver.simRippleIL=max(sim.iL)-min(sim.iL);
ver.voutErrorPercent=100*(ver.simMeanVout-th.idealVout)/max(abs(th.idealVout),eps);
ver.iLErrorPercent=100*(ver.simMeanIL-th.idealMeanIL)/max(abs(th.idealMeanIL),eps);
ver.dutyErrorPercent=100*(ver.simMeanDuty-th.idealDuty)/max(abs(th.idealDuty),eps);
end
