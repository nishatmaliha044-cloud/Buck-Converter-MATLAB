function map=buckStabilityMap(p,rowName,rowValues,colName,colValues,x0,opt)
% Two-parameter operating-regime map.
% Each grid point is simulated independently from x0 by default.
% This is intentional: it prevents continuation from one parameter point
% from changing the attractor selected at the next point.
if nargin<7, opt=struct; end
opt=mapOptionsLocal(opt);

rowValues=rowValues(:);
colValues=colValues(:).';
nr=numel(rowValues); nc=numel(colValues);
code=nan(nr,nc); ccm=false(nr,nc);
labels=cell(nr,nc);

parfor i=1:nr
    q=buckParameters('set',p,rowName,rowValues(i));
    % Use the sweep engine with continuation explicitly disabled unless
    % the caller deliberately requests continuation.
    row=buckSweep(q,colName,colValues,x0,opt);
    code(i,:)=row.classCode.';
    ccm(i,:)=row.ccmValid.';
    labels(i,:)=row.classLabel(:).';
end

map=struct('rowParameter',rowName,'rowValues',rowValues,...
    'colParameter',colName,'colValues',colValues,...
    'code',code,'classLabel',{labels},'ccmValid',ccm);
end

function opt=mapOptionsLocal(opt)
if ~isfield(opt,'nCycles'), opt.nCycles=700; end
if ~isfield(opt,'discardCycles'), opt.discardCycles=350; end
if ~isfield(opt,'keep'), opt.keep=250; end
if ~isfield(opt,'useContinuation'), opt.useContinuation=false; end
if ~isfield(opt,'verbose'), opt.verbose=false; end
opt.computeLLE=false;
if opt.discardCycles>=opt.nCycles
    error('discardCycles must be smaller than nCycles.');
end
if opt.keep<1
    error('keep must be positive.');
end
end
