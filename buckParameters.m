function p = buckParameters(action,varargin)

if nargin==0, action='defaults'; end
switch lower(action)
    case 'defaults'
        p.L=1e-3; p.C=47e-6; p.R=10; p.Vin=10; p.Vref=5;
        p.rL=0.10; p.Vd=0.40; p.Kp=30; p.Vbias=0.50;
        p.fsw=20e3; p.VrampMin=0; p.VrampMax=1; p.tBlank=50e-9;
        p.RelTol=1e-6; p.AbsTol=1e-8; p.MaxStepFraction=1/15;%timestep,ode45 settings.
    case 'validate'
        p=varargin{1};
    case 'set'
        p=varargin{1}; name=varargin{2}; value=varargin{3};
        names={'l','c','r','vin','vref','kp','fsw','vrampmin','vrampmax','vbias','rl','vd'};
        canon={'L','C','R','Vin','Vref','Kp','fsw','VrampMin','VrampMax','Vbias','rL','Vd'};% structure field name
        k=find(strcmpi(strtrim(name),names),1);
        if isempty(k), error('Unsupported parameter: %s',name); end
        p.(canon{k})=value;
    otherwise
        error('Unknown parameter: %s',action);
end
p=validateLocal(p);
end

function p=validateLocal(p)
required={'L','C','R','Vin','Vref','Kp','fsw','VrampMin','VrampMax'};
for k=1:numel(required)
    if ~isfield(p,required{k}), error('Missing p.%s',required{k}); end
end
defaults={'rL',0;'Vd',0;'Vbias',0;'tBlank',0;'RelTol',1e-6;...
          'AbsTol',1e-8;'MaxStepFraction',1/15};
for k=1:size(defaults,1)
    if ~isfield(p,defaults{k,1}), p.(defaults{k,1})=defaults{k,2}; end%Adds optional default values
end
positive={'L','C','R','Vin','fsw'};
for k=1:numel(positive)
    v=p.(positive{k});
    if ~isscalar(v)||~isfinite(v)||v<=0, error('p.%s must be positive.',positive{k}); end
end
if p.Kp<0||p.rL<0||p.Vd<0||p.VrampMax<=p.VrampMin
    error('Invalid controller, loss or ramp parameter.');
end
p.Ts=1/p.fsw;
p.closedDutyFallback=@(vo)min(max((p.Vbias+p.Kp*(p.Vref-vo)-p.VrampMin)/...
    (p.VrampMax-p.VrampMin),0),1);%calculates PWM duty,,0 ≤ duty ≤ 1
end
