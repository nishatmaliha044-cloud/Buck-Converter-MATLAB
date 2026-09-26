function varargout=buckSimulate(action,varargin)
switch lower(action)
    case 'run'
        varargout{1}=runCycles(varargin{:});
    case 'time'
        p=varargin{1}; x0=varargin{2}; totalTime=varargin{3};
        p=buckParameters('validate',p);
        varargout{1}=runCycles(p,x0,max(1,round(totalTime/p.Ts)));%findswitching cycles
    case 'onecycle'
        p=buckParameters('validate',varargin{1}); x0=varargin{2};
        base=solverOptions(p);
        [varargout{1},varargout{2},varargout{3},varargout{4}]=oneCycle(x0(:),p,base);
    otherwise
        error('Unknown simulation action: %s',action);
end
end

function sim=runCycles(p,x0,nCycles)
p=buckParameters('validate',p); 
x=x0(:);% convert initial state into column vector
if numel(x)~=2||any(~isfinite(x)), error('x0 must be [iL; vO].'); end 
if nCycles<1||nCycles~=floor(nCycles), error('nCycles must be positive.'); end
sample=zeros(nCycles,2); duty=zeros(nCycles,1); iMin=zeros(nCycles,1);
T=[]; X=[]; S=[]; finalWindow=min(nCycles,40); 
base=solverOptions(p);
for k=1:nCycles
    [t,z,s,d]=oneCycle(x,p,base); x=z(end,:).';% final state=next cycle's ic
    x(1)=max(x(1),0); z(:,1)=max(z(:,1),0);%Prevents negative inductor current numerically
    sample(k,:)=x.'; duty(k)=d; iMin(k)=min(z(:,1));
    if k>nCycles-finalWindow
        T=[T;(k-1)*p.Ts+t]; X=[X;z]; S=[S;s]; %#ok<AGROW>
    end
end
sim.cycle.x=sample; sim.cycle.iL=sample(:,1); sim.cycle.vO=sample(:,2);
sim.cycle.duty=duty; sim.cycle.minIL=iMin; sim.cycle.t=(1:nCycles)'*p.Ts;
sim.finalState=x; start=max(1,nCycles-350);
sim.minInductorCurrent=min(iMin(start:end)); sim.ccmValid=all(iMin(start:end)>1e-8);
sim.t=T; sim.x=X; sim.iL=X(:,1); sim.vO=X(:,2); sim.switchState=S;
phase=mod(T,p.Ts); sim.vRamp=p.VrampMin+(p.VrampMax-p.VrampMin).*phase/p.Ts;
sim.vCtrl=p.Vbias+p.Kp*(p.Vref-sim.vO); sim.params=p;
end

function base=solverOptions(p)
base=odeset('RelTol',p.RelTol,'AbsTol',p.AbsTol,'MaxStep',p.Ts*p.MaxStepFraction);
end

function [tAll,xAll,sAll,duty]=oneCycle(x0,p,base)
if controlVoltage(x0,p)<=p.VrampMin
    [tAll,xAll]=offInterval(x0,0,p.Ts,p,base);
    sAll=zeros(size(tAll)); duty=0; return
end
ev=odeset(base,'Events',@(t,x)switchEvent(t,x,p));
[ton,xon,te,xe]=ode45(@(t,x)dynamics(x,p,true),[0 p.Ts],x0,ev);
if isempty(te)||te(1)>=p.Ts*(1-1e-10)
    tAll=ton; xAll=xon; sAll=ones(size(ton)); duty=1; return
end%ON for entire cycle,D=1

toff=te(1); [tf,xf]=offInterval(xe(1,:).',toff,p.Ts,p,base);
tAll=[ton;tf(2:end)]; xAll=[xon;xf(2:end,:)];
sAll=[ones(size(ton));zeros(numel(tf)-1,1)]; duty=toff/p.Ts;
end

function [tAll,xAll]=offInterval(x0,t0,t1,p,base)
if x0(1)<=1e-12
    x0(1)=0;
    [tAll,xAll]=ode45(@(t,x)[0;-x(2)/(p.R*p.C)],[t0 t1],x0,base); return
end
ev=odeset(base,'Events',@zeroEvent);
[ta,xa,te,xe]=ode45(@(t,x)dynamics(x,p,false),[t0 t1],x0,ev);
if isempty(te), tAll=ta; xAll=xa; return; end
xz=xe(1,:).'; xz(1)=0;
[tb,xb]=ode45(@(t,x)[0;-x(2)/(p.R*p.C)],[te(1) t1],xz,base);
tAll=[ta;tb(2:end)]; xAll=[xa;xb(2:end,:)]; xAll(:,1)=max(xAll(:,1),0);
end

function dx=dynamics(x,p,on)
i=x(1); v=x(2);
if on, vL=p.Vin-v-p.rL*i; else, vL=-v-p.rL*i-p.Vd; end
dx=[vL/p.L;(i-v/p.R)/p.C];
end

function v=controlVoltage(x,p), v=p.Vbias+p.Kp*(p.Vref-x(2)); end
function [value,terminal,direction]=switchEvent(t,x,p)
vRamp=p.VrampMin+(p.VrampMax-p.VrampMin)*t/p.Ts;
value=controlVoltage(x,p)-vRamp;
if t<p.tBlank, value=max(value,eps); end
terminal=1; direction=-1;
end
function [value,terminal,direction]=zeroEvent(~,x)
value=x(1); terminal=1; direction=-1;
end
