function th=buckTheory(p)

p=buckParameters('validate',p);
D=min(max(p.Vref/p.Vin,0),1);
th.idealDuty=D;
th.idealVout=D*p.Vin;
th.idealMeanIL=p.Vref/p.R;
th.idealRippleIL=(p.Vin-p.Vref)*D*p.Ts/p.L;
th.idealMinIL=th.idealMeanIL-th.idealRippleIL/2;
th.idealRippleV=th.idealRippleIL/(8*p.fsw*p.C);
th.Lcritical=(1-D)*p.R/(2*p.fsw);
th.ccmMargin=p.L/th.Lcritical;
th.lossyDuty=(p.Vref*(1+p.rL/p.R)+p.Vd)/(p.Vin+p.Vd);

a=p.VrampMax-p.VrampMin;
b=p.Vbias-p.VrampMin;

th.closedLoopVout=(p.Vin*(b+p.Kp*p.Vref)-p.Vd*a)/(a*(1+p.rL/p.R)+p.Kp*(p.Vin+p.Vd));
th.closedLoopDuty=p.closedDutyFallback(th.closedLoopVout);
end
