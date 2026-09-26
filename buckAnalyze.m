function out=buckAnalyze(p,x0,nCycles,nLLE,discardCycles)
if nargin<3
    nCycles=600;
end

if nargin<4
    nLLE=100;
end

if nargin<5
    discardCycles=350;
end

if isstruct(x0)
    sim=x0;
    nCycles=size(sim.cycle.x,1);
else
    sim=buckSimulate('run',p,x0,nCycles);
end

discard=max(1,nCycles-discardCycles);
X=sim.cycle.x(discard+1:end,:);

cls=classifyOrbit(X,p,sim.finalState,nLLE);

idx=discard+1:nCycles;

m.meanVout=mean(sim.cycle.vO(idx));
m.meanIL=mean(sim.cycle.iL(idx));
m.meanDuty=mean(sim.cycle.duty(idx));

m.minIL=min(sim.cycle.minIL(idx));
m.maxIL=max(sim.cycle.iL(idx));

m.voutPoincarePP=...
    max(sim.cycle.vO(idx))-min(sim.cycle.vO(idx));

m.ccmValid=m.minIL>1e-8;

m.zeroCurrentFraction=...
    mean(sim.cycle.minIL(idx)<=1e-8);

if m.zeroCurrentFraction==0
    m.conductionMode='CCM';
elseif m.zeroCurrentFraction>=1-1/numel(idx)
    m.conductionMode='DCM';
else
    m.conductionMode='Mixed CCM/DCM';
end

out=struct(...
    'sim',sim,...
    'class',cls,...
    'metrics',m,...
    'params',p);

end

function cls=classifyOrbit(X,p,x,nLLE)

cls=struct(...
    'code',-1,...
    'period',NaN,...
    'label','Insufficient samples',...
    'recurrenceScore',NaN,...
    'llePerCycle',NaN,...
    'chaosEvidence',false);

if size(X,1)<40
    return;
end

% Keep only the most recent settled samples
Nkeep=min(250,size(X,1));
X=X(end-Nkeep+1:end,:);

scale=std(X,0,1);

scale=max(scale,[1e-6 1e-6]);

periods=[1 2 4 8 16 32 64];
tol=5e-3;

for q=periods

    if size(X,1)<3*q+10
        continue;
    end

    % Compare the state with the state q cycles earlier
    A=X(q+1:end,:);
    B=X(1:end-q,:);

    E=(A-B)./scale;
    err=sqrt(sum(E.^2,2));
    score=percentileLocal(err,0.95);

    nTest=min(3,size(X,1)-q);
    valid=true;
    for r=1:nTest

        start1=size(X,1)-r*q+1;
        start0=start1-q;

        if start0<1
            valid=false;
            break;
        end

        d=(X(start1,:)-X(start0,:))./scale;
        if norm(d)>tol
            valid=false;
            break;
        end
    end

    if score<tol && valid

        cls.code=q;
        cls.period=q;
        cls.label=sprintf('Period-%d',q);
        cls.recurrenceScore=score;

        return;
    end
end

if nLLE<=1

    cls.code=-2;
    cls.period=Inf;
    cls.label='High-period / LLE not calculated';

    return;
end

cls.llePerCycle=estimateLLE(p,x,nLLE);

if isfinite(cls.llePerCycle) && cls.llePerCycle>2e-3

    cls.code=0;
    cls.period=Inf;
    cls.label='Chaos (positive LLE)';
    cls.chaosEvidence=true;

else

    cls.code=-2;
    cls.period=Inf;
    cls.label='High-period / aperiodic';

end

end

function lle=estimateLLE(p,x,nCycles)

s=[max(abs(x(1)),0.5);...
   max(abs(x(2)),p.Vref)];

delta0=1e-7;

% Initial perturbation direction
d=[1;1]/sqrt(2);

% Perturbed trajectory
y=x+s.*(delta0*d);

logs=nan(nCycles,1);

for k=1:nCycles

    % One switching cycle for original trajectory
    [~,zx]=buckSimulate('onecycle',p,x);
    % One switching cycle for perturbed trajectory
    [~,zy]=buckSimulate('onecycle',p,y);

    x=zx(end,:).';
    y=zy(end,:).';

    d=(y-x)./s;

    growth=norm(d);

    if ~isfinite(growth)

        lle=NaN;
        return;

    end

    if growth<1e-14

        if mod(k,2)==0
            d=[1;0];
        else
            d=[0;1];
        end

        growth=1e-14;

    else

        d=d/growth;

    end

    logs(k)=log(growth/delta0);
    y=x+s.*(delta0*d);

end

first=max(2,round(0.15*nCycles));

valid=isfinite(logs(first:end));

if ~any(valid)

    lle=NaN;

else

    z=logs(first:end);
    lle=mean(z(valid));

end
end

function q=percentileLocal(x,f)

x=sort(x(:));

if isempty(x)

    q=NaN;
    return;
end
idx=max(1,min(numel(x),ceil(f*numel(x))));
q=x(idx);
end