function bif=buckSweep(p,name,values,x0,opt)

if nargin<5, opt=struct; end
opt=optionsLocal(opt); values=values(:); n=numel(values);
codes=nan(n,1); labels=cell(n,1); lle=nan(n,1); ccm=false(n,1);
meanV=nan(n,1); finals=nan(n,2); P=cell(n,1); V=cell(n,1); x=x0(:);

for k=1:n
    pk=buckParameters('set',p,name,values(k));

    if opt.useContinuation
        xStart=x;
    else
        xStart=x0(:);
    end

    sim=buckSimulate('run',pk,xStart,opt.nCycles);

    keepStart=opt.discardCycles+1;
    keepStart=max(1,keepStart);
    keep=keepStart:opt.nCycles;
    keep=keep(end-min(opt.keep,numel(keep))+1:end);

    if opt.computeLLE, nLLE=100; else, nLLE=0; end

    settled=sim;
    cycleFields={'x','iL','vO','duty','minIL','t'};
    for f=1:numel(cycleFields)
        valuesToKeep=sim.cycle.(cycleFields{f});
        settled.cycle.(cycleFields{f})=valuesToKeep(keep,:);
    end

    out=buckAnalyze(pk,settled,numel(keep),nLLE);
    P{k}=repmat(values(k),numel(keep),1);
    V{k}=sim.cycle.vO(keep);
    codes(k)=out.class.code;
    labels{k}=out.class.label;
    lle(k)=out.class.llePerCycle;
    ccm(k)=all(sim.cycle.minIL(keep)>1e-8);
    meanV(k)=mean(sim.cycle.vO(keep));
    finals(k,:)=sim.finalState.';

    if opt.useContinuation
        x=sim.finalState;
    else
        x=x0(:);
    end

    if opt.verbose&&(k==1||k==n||mod(k,20)==0)
        fprintf('%s sweep %d/%d\n',name,k,n);
    end
end

bif=struct('parameterName',name,'parameterValues',values,...
    'parameter',vertcat(P{:}),'vO',vertcat(V{:}),'classCode',codes,...
    'classLabel',{labels},'llePerCycle',lle,'ccmValid',ccm,...
    'meanVout',meanV,'finalStates',finals);
end

function opt=optionsLocal(opt)
if ~isfield(opt,'nCycles'), opt.nCycles=700; end
if ~isfield(opt,'discardCycles'), opt.discardCycles=350; end
if ~isfield(opt,'keep'), opt.keep=250; end
if ~isfield(opt,'useContinuation'), opt.useContinuation=false; end
if ~isfield(opt,'verbose'), opt.verbose=false; end
if ~isfield(opt,'computeLLE'), opt.computeLLE=true; end
if opt.discardCycles>=opt.nCycles, error('discardCycles must be smaller than nCycles.'); end
if opt.keep<1, error('keep must be positive.'); end
end
