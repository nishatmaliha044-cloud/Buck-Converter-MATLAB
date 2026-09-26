function BuckConverter_GUI
required={'buckParameters','buckSimulate','buckAnalyze','buckSweep', 'buckStabilityMap','buckVerify'};
for k=1:numel(required)
    if exist(required{k},'file')~=2
        errordlg(['MATLAB cannot find ',required{k},'.m']); return
    end
end
p0 = buckParameters('defaults');

app = struct;
app.last = struct('analysis',[],'sweep',[],'map',[]);

app.theme.bg     = [0.025 0.035 0.060];
app.theme.panel  = [0.055 0.075 0.120];
app.theme.panel2 = [0.090 0.125 0.190];
app.theme.accent = [0.00 0.75 1.00];
app.theme.green  = [0.10 0.82 0.48];
app.theme.red    = [1.00 0.30 0.32];
app.theme.text   = [0.94 0.97 1.00];
app.theme.muted  = [0.62 0.72 0.84];
app.theme.input  = [0.10 0.14 0.21];
app.theme.plotbg = [0.035 0.050 0.085];

makeInterface(p0);
writeStatus('Ready.Change any values,then press Run simulation.',false);

function makeInterface(p)

    app.fig = uifigure( 'Name','Nonlinear PWM Buck Converter Laboratory', ...
        'Color',app.theme.bg, 'Position',[30 35 1300 700]);

    app.fig.CloseRequestFcn = @closeRequest;

    outer = uigridlayout(app.fig,[2 2]);
    outer.RowHeight = {55,'1x'};
    outer.ColumnWidth = {'30x','70x'};
    outer.Padding = [14 12 14 14];
    outer.RowSpacing = 10;
    outer.ColumnSpacing = 12;

    header = uipanel(outer, 'BorderType','none', 'BackgroundColor',app.theme.bg);
    header.Layout.Row = 1;
    header.Layout.Column = [1 2];

    headerGrid = uigridlayout(header,[1 1]);
    headerGrid.RowHeight = {'1x'};
    headerGrid.ColumnWidth = {'1x'};
    headerGrid.Padding = [14 10 14 8];
    headerGrid.RowSpacing = 1;
    headerGrid.BackgroundColor = app.theme.bg;

    titleLabel = uilabel(headerGrid, 'Text','NONLINEAR PWM BUCK CONVERTER', ...
        'FontSize',20, 'FontWeight','bold', 'FontColor',app.theme.accent);
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = 1;

    left = uipanel(outer, 'Title','Control desk', 'FontWeight','bold', ...
        'FontSize',14, 'ForegroundColor',app.theme.text, 'BackgroundColor', ...
        app.theme.panel, 'BorderColor',app.theme.panel2);
    left.Layout.Row = 2;
    left.Layout.Column = 1;

    lg = uigridlayout(left,[5 1]);
    lg.Scrollable = 'on';
    lg.RowHeight = {280,175,82,225,65};
    lg.Padding = [10 10 10 10];
    lg.RowSpacing = 8;

    app.parameterPanel = makeParameterPanel(lg,p);
    app.simulationPanel = makeSimulationPanel(lg,p);
    app.buttonPanel = makeButtonPanel(lg);
    app.sweepPanel = makeSweepPanel(lg);

    app.status = uitextarea(lg, 'Editable','off', 'FontName','Consolas', ...
        'FontSize',10, 'BackgroundColor',[0.025 0.040 0.070], 'FontColor', ...
        app.theme.text, 'Value',{'Starting...'});
    app.status.Layout.Row = 5;

    right = uipanel(outer, 'BorderType','none', 'BackgroundColor',app.theme.bg);
    right.Layout.Row = 2;
    right.Layout.Column = 2;

    makeTabs(right);
end

function panel = makeParameterPanel(parent,p)

    panel = uipanel(parent, 'Title','Circuit and controller parameters', ...
        'BackgroundColor',app.theme.panel, 'ForegroundColor',app.theme.text, ...
        'FontWeight','bold', 'BorderColor',app.theme.panel2);
    panel.Layout.Row = 1;

    g = uigridlayout(panel,[12 4]);
    g.ColumnWidth = {68,105,68,105};
    g.RowHeight =repmat({25,15},1,6);
    g.Padding =[7 7 7 7];
    g.RowSpacing = 1;
    g.ColumnSpacing = 5;
    g.BackgroundColor = app.theme.panel;

    addExplainedField(g,1,1,'L (mH)','L',p.L*1e3,'%.4g', 'Inductor');
    addExplainedField(g,1,3,'C (uF)','C',p.C*1e6,'%.4g', 'Capacitor');

    addExplainedField(g,3,1,'R (Ohm)','R',p.R,'%.4g', 'Load resistance');
    addExplainedField(g,3,3,'Vin (V)','Vin',p.Vin,'%.4g', 'Inputvoltage');

    addExplainedField(g,5,1,'Vref (V)','Vref',p.Vref,'%.4g', 'Desired output voltage');
    addExplainedField(g,5,3,'Kp','Kp',p.Kp,'%.4g', 'Feedback controller gain');

    addExplainedField(g,7,1,'fsw (kHz)','fsw',p.fsw/1e3,'%.4g', 'Switching frequency');
    addExplainedField(g,7,3,'Vbias (V)','Vbias',p.Vbias,'%.4g', 'Basic PWM duty bias');

    addExplainedField(g,9,1,'rL (Ohm)','rL',p.rL,'%.4g', 'Inductor winding resistance');
    addExplainedField(g,9,3,'Vd (V)','Vd',p.Vd,'%.4g', 'Diode forward voltage drop');

    addExplainedField(g,11,1,'Ramp min','VrampMin',p.VrampMin,'%.4g', 'PWM ramp lower level');
    addExplainedField(g,11,3,'Ramp max','VrampMax',p.VrampMax,'%.4g', 'PWM ramp upper level');
end

function panel = makeSimulationPanel(parent,p)

    panel = uipanel(parent, 'Title','Simulation settings', 'BackgroundColor' ...
        ,app.theme.panel, 'ForegroundColor',app.theme.text, 'FontWeight','bold', 'BorderColor',app.theme.panel2);
    panel.Layout.Row = 2;

    g = uigridlayout(panel,[6 4]);
    g.ColumnWidth = {68,105,68,105};
    g.RowHeight = repmat({27,16},1,3);
    g.Padding = [7 7 7 7];
    g.RowSpacing = 1;
    g.ColumnSpacing = 5;
    g.BackgroundColor = app.theme.panel;

    addExplainedField(g,1,1,'Cycles','nCycles',700,'%.0f', 'Number of switching cycles simulated');
    addExplainedField(g,1,3,'iL(0) (A)','iL0',p.Vref/p.R,'%.4g', 'Initial inductor current');

    addExplainedField(g,3,1,'vO(0) (V)','vO0',p.Vref,'%.4g', 'Initial output voltage');
    addExplainedField(g,3,3,'Last cycles','shownCycles',20,'%.0f', 'Points shown in phase plot');

    addExplainedField(g,5,1,'Settle cycles','discardCycles',350,'%.0f', 'Transient cycles discarded before period is judged. Used by Run, Sweep and Map alike.');
end

function panel = makeButtonPanel(parent)

    panel = uipanel(parent, 'BorderType','none', 'BackgroundColor',app.theme.panel);
    panel.Layout.Row = 3;

    g = uigridlayout(panel,[2 3]);
    g.RowHeight = {37,37};
    g.ColumnWidth = {'1x','1x','1x'};
    g.Padding = [0 1 0 1];
    g.RowSpacing = 5;
    g.ColumnSpacing = 6;

    app.controls.run = uibutton(g, 'Text','RUN SIMULATION', 'ButtonPushedFcn' ...
        ,@onRun, 'FontWeight','bold', 'FontSize',11, 'BackgroundColor',app.theme.accent, 'FontColor',[0.01 0.06 0.10]);
    app.controls.run.Layout.Row = 1;
    app.controls.run.Layout.Column = [1 2];

    b = uibutton(g, 'Text','Reset', 'ButtonPushedFcn',@onReset, 'BackgroundColor' ...
        ,app.theme.panel2, 'FontColor',app.theme.text);
    b.Layout.Row = 1;
    b.Layout.Column = 3;

    b = uibutton(g, 'Text','Animate state', 'ButtonPushedFcn',@onAnimate, ...
        'BackgroundColor',app.theme.green, 'FontColor',[0.02 0.10 0.06]);
    b.Layout.Row = 2;
    b.Layout.Column = [1 3];
end

function panel = makeSweepPanel(parent)

    panel = uipanel(parent, 'Title','Bifurcation+LLE', 'BackgroundColor' ...
        ,app.theme.panel, 'ForegroundColor',app.theme.text, 'FontWeight','bold', 'BorderColor',app.theme.panel2);
    panel.Layout.Row = 4;

    g = uigridlayout(panel,[8 4]);
    g.ColumnWidth = {'1x','1x','1x','1x'};
    g.RowHeight = {30,16,32,22,30,16,30,16};
    g.Padding = [7 6 7 6];
    g.RowSpacing = 2;
    g.ColumnSpacing = 5;
    g.BackgroundColor = app.theme.panel;

    % One-parameter sweep controls
    app.controls.sweepParameter = uidropdown(g, 'Items',{'Kp','Vin'},'Value','Kp', ...
        'FontSize',10,'FontColor',app.theme.text, 'BackgroundColor',app.theme.input);
    app.controls.sweepParameter.Layout.Row = 1;
    app.controls.sweepParameter.Layout.Column = 1;

    app.controls.sweepMin = uieditfield(g,'numeric', 'Value',10,'Limits',[-Inf Inf], ...
        'FontSize',10,'FontColor',app.theme.text, 'BackgroundColor',app.theme.input);
    app.controls.sweepMin.Layout.Row = 1;
    app.controls.sweepMin.Layout.Column = 2;

    app.controls.sweepMax = uieditfield(g,'numeric', 'Value',35,'Limits',[-Inf Inf], ...
        'FontSize',10,'FontColor',app.theme.text, 'BackgroundColor',app.theme.input);
    app.controls.sweepMax.Layout.Row = 1;
    app.controls.sweepMax.Layout.Column = 3;

    app.controls.sweepPoints = uieditfield(g,'numeric', 'Value',61,'Limits',[3 401], ...
        'RoundFractionalValues','on','FontSize',10,'FontColor',app.theme.text, ...
        'BackgroundColor',app.theme.input);
    app.controls.sweepPoints.Layout.Row = 1;
    app.controls.sweepPoints.Layout.Column = 4;

    labels = {'Parameter','Start value','End value','Points'};
    for c=1:4
        note = uilabel(g,'Text',labels{c},'FontSize',9,'HorizontalAlignment','center', ...
            'FontColor',app.theme.muted);
        note.Layout.Row = 2; note.Layout.Column = c;
    end

    b = uibutton(g,'Text','Run sweep + LLE','ButtonPushedFcn',@onSweep, ...
        'BackgroundColor',app.theme.panel2,'FontColor',app.theme.text,'FontSize',10);
    b.Layout.Row = 3; b.Layout.Column = [1 2];

    b = uibutton(g,'Text','Build 2-D map','ButtonPushedFcn',@onMap, ...
        'BackgroundColor',app.theme.panel2,'FontColor',app.theme.text,'FontSize',10);
    b.Layout.Row = 3; b.Layout.Column = [3 4];

    note = uilabel(g,'Text','2-D stability map settings','FontSize',9,'FontWeight','bold', ...
        'HorizontalAlignment','center','FontColor',app.theme.accent);
    note.Layout.Row = 4; note.Layout.Column = [1 4];

    % Vin range: minimum, maximum, number of grid points
    note = uilabel(g,'Text','Vin','FontSize',9,'FontWeight','bold', ...
        'HorizontalAlignment','center','FontColor',app.theme.text);
    note.Layout.Row = 5; note.Layout.Column = 1;

    app.controls.mapVinMin = uieditfield(g,'numeric','Value',8,'Limits',[0.001 Inf], ...
        'FontSize',10,'FontColor',app.theme.text,'BackgroundColor',app.theme.input);
    app.controls.mapVinMin.Layout.Row = 5; app.controls.mapVinMin.Layout.Column = 2;

    app.controls.mapVinMax = uieditfield(g,'numeric','Value',12,'Limits',[0.001 Inf], ...
        'FontSize',10,'FontColor',app.theme.text,'BackgroundColor',app.theme.input);
    app.controls.mapVinMax.Layout.Row = 5; app.controls.mapVinMax.Layout.Column = 3;

    app.controls.mapVinPoints = uieditfield(g,'numeric','Value',9,'Limits',[3 101], ...
        'RoundFractionalValues','on','FontSize',10,'FontColor',app.theme.text, ...
        'BackgroundColor',app.theme.input);
    app.controls.mapVinPoints.Layout.Row = 5; app.controls.mapVinPoints.Layout.Column = 4;

    labels = {'','Vin min','Vin max','Vin points'};
    for c=1:4
        note = uilabel(g,'Text',labels{c},'FontSize',9,'HorizontalAlignment','center', ...
            'FontColor',app.theme.muted);
        note.Layout.Row = 6; note.Layout.Column = c;
    end

    % Kp range: minimum, maximum, number of grid points
    note = uilabel(g,'Text','Kp','FontSize',9,'FontWeight','bold', ...
        'HorizontalAlignment','center','FontColor',app.theme.text);
    note.Layout.Row = 7; note.Layout.Column = 1;

    app.controls.mapKpMin = uieditfield(g,'numeric','Value',4,'Limits',[0 Inf], ...
        'FontSize',10,'FontColor',app.theme.text,'BackgroundColor',app.theme.input);
    app.controls.mapKpMin.Layout.Row = 7; app.controls.mapKpMin.Layout.Column = 2;

    app.controls.mapKpMax = uieditfield(g,'numeric','Value',36,'Limits',[0 Inf], ...
        'FontSize',10,'FontColor',app.theme.text,'BackgroundColor',app.theme.input);
    app.controls.mapKpMax.Layout.Row = 7; app.controls.mapKpMax.Layout.Column = 3;

    app.controls.mapKpPoints = uieditfield(g,'numeric','Value',17,'Limits',[3 101], ...
        'RoundFractionalValues','on','FontSize',10,'FontColor',app.theme.text, ...
        'BackgroundColor',app.theme.input);
    app.controls.mapKpPoints.Layout.Row = 7; app.controls.mapKpPoints.Layout.Column = 4;

    labels = {'','Kp min','Kp max','Kp points'};
    for c=1:4
        note = uilabel(g,'Text',labels{c},'FontSize',9,'HorizontalAlignment','center', ...
            'FontColor',app.theme.muted);
        note.Layout.Row = 8; note.Layout.Column = c;
    end
end

function makeTabs(parent)

    mainGrid = uigridlayout(parent,[1 1]);
    mainGrid.RowHeight = {'1x'};
    mainGrid.ColumnWidth = {'1x'};
    mainGrid.Padding = [0 0 0 0];

    app.tabs = uitabgroup(mainGrid);
    app.tabs.Layout.Row = 1;
    app.tabs.Layout.Column = 1;

    tab1 = uitab(app.tabs,'Title','Time response');
    tab2 = uitab(app.tabs,'Title','Phase + Poincare');
    tab3 = uitab(app.tabs,'Title','PWM + duty');
    tab4 = uitab(app.tabs,'Title','Bifurcation + LLE');
    tab5 = uitab(app.tabs,'Title','Stability map');
    app.tabPhase = tab2;
    app.tabBif = tab4;
    app.tabMap = tab5;

    g1 = uigridlayout(tab1,[2 1]);
    g1.RowHeight = {'1x','1x'};
    g1.Padding = [15 15 15 15];
    g1.BackgroundColor = app.theme.plotbg;
    app.axes.vout = makeAxes(g1,'Output voltage v_o(t)');
    app.axes.vout.Layout.Row = 1;
    app.axes.il = makeAxes(g1,'Inductor current i_L(t)');
    app.axes.il.Layout.Row = 2;

    g2 = uigridlayout(tab2,[1 2]);
    g2.ColumnWidth = {'1x','1x'};
    g2.Padding = [15 15 15 15];
    g2.BackgroundColor = app.theme.plotbg;
    app.axes.phase = makeAxes(g2,'Phase space: v_o versus i_L');
    app.axes.phase.Layout.Column = 1;
    app.axes.poincare = makeAxes(g2,'Stroboscopic Poincare sequence');
    app.axes.poincare.Layout.Column = 2;

    g3 = uigridlayout(tab3,[2 1]);
    g3.RowHeight = {'1x','1x'};
    g3.Padding = [15 15 15 15];
    g3.BackgroundColor = app.theme.plotbg;
    app.axes.pwm = makeAxes(g3,'PWM comparator signals');
    app.axes.pwm.Layout.Row = 1;
    app.axes.duty = makeAxes(g3,'Settled cycle-by-cycle duty ratio');
    app.axes.duty.Layout.Row = 2;

    g4 = uigridlayout(tab4,[2 1]);
    g4.RowHeight = {'1x','1x'};
    g4.Padding = [15 15 15 15];
    g4.BackgroundColor = app.theme.plotbg;
    app.axes.bif = makeAxes(g4,'Bifurcation diagram');
    app.axes.bif.Layout.Row = 1;
    app.axes.lle = makeAxes(g4,'Largest Lyapunov exponent');
    app.axes.lle.Layout.Row = 2;

    g5 = uigridlayout(tab5,[1 1]);
    g5.Padding = [15 15 15 15];
    g5.BackgroundColor = app.theme.plotbg;
    app.axes.map = makeAxes(g5,'Operating-regime map: Vin versus Kp');

    app.cards = makeMetricCards(tab1);
end


function ax = makeAxes(parent,titleText)

    ax = uiaxes(parent);
    ax.Color = app.theme.plotbg;
    ax.XColor = app.theme.text;
    ax.YColor = app.theme.text;
    ax.GridColor = [0.35 0.45 0.60];
    ax.GridAlpha = 0.28;
    ax.XGrid = 'on';
    ax.YGrid = 'on';
    ax.FontSize = 11;
    ax.LineWidth = 1.0;
    ax.Box = 'on';

    title(ax,titleText,'FontWeight','bold','Color',app.theme.text);
    ax.Title.Color = app.theme.text;
    ax.XLabel.Color = app.theme.text;
    ax.YLabel.Color = app.theme.text;
end

function cards = makeMetricCards(parent)

    cards = struct;

    strip = uipanel(parent, 'BorderType','none', 'BackgroundColor',[0.99 1 1]);
    strip.Position = [0.04 0.88 0.92 0.10];

    g = uigridlayout(strip,[1 5]);
    g.ColumnWidth = repmat({'1x'},1,5);
    g.Padding = [0 0 0 0];
    g.ColumnSpacing = 8;

    cards.vo = metricCard(g,'Mean v_o','-- V');
    cards.il = metricCard(g,'Mean i_L','-- A');
    cards.duty = metricCard(g,'Mean duty','--');
    cards.mode = metricCard(g,'Mode','--');
    cards.class = metricCard(g,'Orbit','--');
end


function card = metricCard(parent,label,value)

    card = struct;

    card.panel = uipanel(parent, 'BackgroundColor',[0.93 0.97 1.00], 'BorderColor',[0.72 0.84 0.94]);

    gl = uigridlayout(card.panel,[2 1]);
    gl.RowHeight = {20,'1x'};
    gl.Padding = [5 3 5 3];

    uilabel(gl,'Text',label, 'HorizontalAlignment','center', 'FontSize',10, ...
        'FontColor',[0.18 0.32 0.45]);

    card.value = uilabel(gl,'Text',value, 'HorizontalAlignment','center', ...
        'FontWeight','bold', 'FontSize',13, 'FontColor',[0.02 0.30 0.50]);
    card.value.Layout.Row = 2;
end

function addExplainedField(grid,baseRow,col,label,key,value,fmt,description)

    lab = uilabel(grid, 'Text',label, 'FontSize',10, 'FontWeight','bold', ...
        'FontColor',app.theme.text, 'HorizontalAlignment','left');
    lab.Layout.Row = baseRow;
    lab.Layout.Column = col;

    ed = uieditfield(grid,'numeric', 'Value',value, 'FontSize',10, 'FontColor' ...
        ,app.theme.text, 'BackgroundColor',app.theme.input, 'HorizontalAlignment','right');
    ed.ValueDisplayFormat = fmt;
    ed.Layout.Row = baseRow;
    ed.Layout.Column = col + 1;

    desc = uilabel(grid, 'Text',description, 'FontSize',10, 'FontAngle','italic', ...
        'FontColor',app.theme.muted, 'HorizontalAlignment','left');
    desc.Layout.Row = baseRow + 1;
    desc.Layout.Column = [col col+1];

    app.controls.(key) = ed;
end


function onRun(~,~)
    runSafely(@doRun);
end

function doRun

    p = readParameters();

    nCycles = requireInteger(app.controls.nCycles.Value,'Cycles',400,5000);
    discardCycles = requireInteger(app.controls.discardCycles.Value,'Settle cycles',10,nCycles-10);

    x0 = [app.controls.iL0.Value; app.controls.vO0.Value];

    busy(true,'Running switched-model simulation...');

    out = buckAnalyze(p,x0,nCycles,100,discardCycles);

    ver = buckVerify(p,out.sim);
    app.last.analysis = out;

    drawSimulation(out,ver);

    busy(false,sprintf( 'Simulation finished: %s. Select any tab to inspect results.', out.class.label));
end

function onSweep(~,~)
    runSafely(@doSweep);
end

function doSweep

    p = readParameters();
    x0 = [app.controls.iL0.Value; app.controls.vO0.Value];

    a = app.controls.sweepMin.Value;
    b = app.controls.sweepMax.Value;

    n = requireInteger(app.controls.sweepPoints.Value, 'Sweep points',3,401);

    if ~isfinite(a) || ~isfinite(b) || b <= a
        error('Sweep maximum must be larger than sweep minimum.');
    end

    values = linspace(a,b,n);

    discardCycles = requireInteger(app.controls.discardCycles.Value,'Settle cycles',10,440);

    opt = struct( 'nCycles',450, 'discardCycles',discardCycles, 'keep',100, 'useContinuation', ...
        true, 'verbose',false, 'computeLLE',true);

    busy(true,sprintf( 'Running %d-point %s sweep. LLE calculation can take time.', ...
        n,app.controls.sweepParameter.Value));

    bif = buckSweep(p,app.controls.sweepParameter.Value,values,x0,opt);

    app.last.sweep = bif;
    drawSweep(bif);
    app.tabs.SelectedTab = app.tabBif;

    busy(false,sprintf( '%s sweep completed (%d operating points).', bif.parameterName,n));
end

function onMap(~,~)
    runSafely(@doMap);
end


function doMap

    p = readParameters();
    x0 = [app.controls.iL0.Value; app.controls.vO0.Value];

    vinMin = positiveValue(app.controls.mapVinMin.Value,'Vin minimum');
    vinMax = positiveValue(app.controls.mapVinMax.Value,'Vin maximum');
    kpMin = nonnegativeValue(app.controls.mapKpMin.Value,'Kp minimum');
    kpMax = nonnegativeValue(app.controls.mapKpMax.Value,'Kp maximum');
    nVin = requireInteger(app.controls.mapVinPoints.Value,'Vin points',3,101);
    nKp = requireInteger(app.controls.mapKpPoints.Value,'Kp points',3,101);

    if vinMax <= vinMin
        error('Vin maximum must be larger than Vin minimum.');
    end
    if kpMax <= kpMin
        error('Kp maximum must be larger than Kp minimum.');
    end

    vinValues = linspace(vinMin,vinMax,nVin);
    kpValues = linspace(kpMin,kpMax,nKp);


    discardCycles = requireInteger(app.controls.discardCycles.Value,'Settle cycles',10,690);

    opt = struct('nCycles',700,'discardCycles',discardCycles,'keep',250, ...
        'useContinuation',false,'verbose',false,'computeLLE',false);

    busy(true,sprintf('Building %d x %d stability map...',nVin,nKp));

    map = buckStabilityMap(p,'Vin',vinValues,'Kp',kpValues,x0,opt);

    app.last.map = map;
    drawMap(map);
    app.tabs.SelectedTab = app.tabMap;

    busy(false,sprintf(['Stability map completed: %d Vin x %d Kp points.' ...
        'Each point was simulated independently.'],nVin,nKp));
end

function onAnimate(~,~)
    runSafely(@doAnimate);
end

function doAnimate

    if isempty(app.last.analysis)
        doRun;
        if isempty(app.last.analysis)
            return
        end
    end

    sim = app.last.analysis.sim;
    app.tabs.SelectedTab = app.tabPhase;

    ax = app.axes.phase;
    v = sim.vO(:);
    i = sim.iL(:);

    cla(ax);
    hold(ax,'on');
    grid(ax,'on');

    plot(ax,v,i,'Color',[0.65 0.82 0.95],'LineWidth',1.0);

    xlabel(ax,'Output voltage v_o (V)');
    ylabel(ax,'Inductor current i_L (A)');
    title(ax,sprintf('Real Time State Animation at K_p = %.2f',sim.params.Kp));

    xPad = max(1e-4,0.08*(max(v)-min(v)));
    yPad = max(1e-4,0.08*(max(i)-min(i)));

    xlim(ax,[min(v)-xPad,max(v)+xPad]);
    ylim(ax,[min(i)-yPad,max(i)+yPad]);

    trail = animatedline(ax,'Color',[0.00 0.35 0.75],'LineWidth',2.0);
    point = plot(ax,v(1),i(1),'ro','MarkerFaceColor','r','MarkerSize',8);

    frameIndex = unique(round(linspace(1,numel(v),min(280,numel(v)))));

    for k = frameIndex
        addpoints(trail,v(k),i(k));
        set(point,'XData',v(k),'YData',i(k));
        drawnow limitrate;
        pause(0.018);
    end

    hold(ax,'off');

    writeStatus('Phase-space animation completed inside the GUI.',false);
end

function onReset(~,~)

    p = buckParameters('defaults');

    app.controls.L.Value = p.L*1e3;
    app.controls.C.Value = p.C*1e6;
    app.controls.R.Value = p.R;
    app.controls.Vin.Value = p.Vin;
    app.controls.Vref.Value = p.Vref;
    app.controls.Kp.Value = p.Kp;
    app.controls.fsw.Value = p.fsw/1e3;
    app.controls.Vbias.Value = p.Vbias;
    app.controls.rL.Value = p.rL;
    app.controls.Vd.Value = p.Vd;
    app.controls.VrampMin.Value = p.VrampMin;
    app.controls.VrampMax.Value = p.VrampMax;

    app.controls.nCycles.Value =700;
    app.controls.iL0.Value = p.Vref/p.R;
    app.controls.vO0.Value = p.Vref;
    app.controls.shownCycles.Value = 20;
    app.controls.discardCycles.Value = 350;

    app.controls.sweepParameter.Value ='Kp';
    app.controls.sweepMin.Value=10;
    app.controls.sweepMax.Value = 35;
    app.controls.sweepPoints.Value=61;

    app.controls.mapVinMin.Value=8;
    app.controls.mapVinMax.Value=12;
    app.controls.mapVinPoints.Value=9;
    app.controls.mapKpMin.Value=4;
    app.controls.mapKpMax.Value=36;
    app.controls.mapKpPoints.Value=17;

    clearPlots();
    app.last = struct('analysis',[],'sweep',[],'map',[]);

    writeStatus('Default values restored.',false);
end

function drawSimulation(out,ver)

    sim = out.sim;
    p = sim.params;

    cla(app.axes.vout);
    cla(app.axes.il);
    cla(app.axes.phase);
    cla(app.axes.poincare);
    cla(app.axes.pwm);
    cla(app.axes.duty);

    plot(app.axes.vout,sim.t*1e3,sim.vO, 'Color',[0.00 0.78 1.00],'LineWidth',1.15);
    xlabel(app.axes.vout,'Time (ms)');
    ylabel(app.axes.vout,'v_o (V)');
    title(app.axes.vout,sprintf('Output voltage | mean = %.4f V', out.metrics.meanVout));

    plot(app.axes.il,sim.t*1e3,sim.iL, 'Color',[0.15 0.95 0.55],'LineWidth',1.15);
    xlabel(app.axes.il,'Time (ms)');
    ylabel(app.axes.il,'i_L (A)');
    title(app.axes.il,sprintf('Inductor current | min = %.4f A', out.metrics.minIL));

    hold(app.axes.phase,'on');

    plot(app.axes.phase,sim.vO,sim.iL, 'Color',[0.10 0.72 1.00],'LineWidth',1.0);

    nShow = requireInteger(app.controls.shownCycles.Value, 'Last cycles',1,500);

    totalCycles = size(sim.cycle.x,1);

    pc = sim.cycle.x( max(1,totalCycles-nShow+1):totalCycles,:);

    scatter(app.axes.phase,pc(:,2),pc(:,1),26, [1.00 0.30 0.32],'filled');

    hold(app.axes.phase,'off');

    xlabel(app.axes.phase,'v_o (V)');
    ylabel(app.axes.phase,'i_L (A)');
    title(app.axes.phase,sprintf('Phase space at Kp = %.3g',p.Kp));

    lgd = legend(app.axes.phase, {'Trajectory','Poincare samples'},'Location','best');
    lgd.TextColor = app.theme.text;
    lgd.Color = [0.06 0.09 0.14];
    lgd.EdgeColor = app.theme.muted;

    pc = sim.cycle.x(max(1,totalCycles-nShow+1):totalCycles,:);

    scatter(app.axes.poincare,1:size(pc,1),pc(:,2),22, [0.00 0.35 0.75],'filled');

    xlabel(app.axes.poincare,'Settled switching-cycle index');
    ylabel(app.axes.poincare,'v_o(nT_s) (V)');
    title(app.axes.poincare,sprintf('Poincare sequence | %s',out.class.label));

    hold(app.axes.pwm,'on');

    plot(app.axes.pwm,sim.t*1e6,sim.vCtrl, 'Color',[0.00 0.35 0.75],'LineWidth',1.0);

    plot(app.axes.pwm,sim.t*1e6,sim.vRamp,'--', 'Color',[0.92 0.20 0.25],'LineWidth',1.0);

    hold(app.axes.pwm,'off');

    xlabel(app.axes.pwm,'Time (microseconds)');
    ylabel(app.axes.pwm,'Voltage (V)');
    title(app.axes.pwm,'PWM comparator: control voltage and ramp');

    lgd = legend(app.axes.pwm,{'v_{ctrl}','v_{ramp}'},'Location','best');
    lgd.TextColor = app.theme.text;
    lgd.Color = [0.06 0.09 0.14];
    lgd.EdgeColor = app.theme.muted;

    k = max(1,numel(sim.cycle.duty)-nShow+1):numel(sim.cycle.duty);

    scatter(app.axes.duty,k,sim.cycle.duty(k),20, [0.03 0.45 0.80],'filled');

    hold(app.axes.duty,'on');
    yline(app.axes.duty,out.metrics.meanDuty,'--r','Mean duty');
    hold(app.axes.duty,'off');

    ylim(app.axes.duty,[-0.05 1.05]);
    xlabel(app.axes.duty,'Switching-cycle number');
    ylabel(app.axes.duty,'Duty ratio D_k');
    title(app.axes.duty,'Settled cycle-by-cycle duty ratio');

    app.cards.vo.value.Text = sprintf('%.4f V',out.metrics.meanVout);
    app.cards.il.value.Text = sprintf('%.4f A',out.metrics.meanIL);
    app.cards.duty.value.Text = sprintf('%.4f',out.metrics.meanDuty);
    app.cards.mode.value.Text = out.metrics.conductionMode;
    app.cards.class.value.Text = out.class.label;

    writeStatus(sprintf([ 'Simulation complete\n', 'Class: %s\n', 'Mode: %s\n', ...
        'Mean v_o: %.5f V (ideal %.5f V)\n', 'Output-voltage error vs ideal: %+.2f %%\n', ...
        'LLE: %.5g per cycle'], out.class.label,out.metrics.conductionMode, ...
        out.metrics.meanVout,ver.theory.idealVout, ver.voutErrorPercent,out.class.llePerCycle),false);
end

function drawSweep(bif)

    cla(app.axes.bif);
    cla(app.axes.lle);

    scatter(app.axes.bif,bif.parameter,bif.vO,7, [0.02 0.32 0.72],'filled');

    xlabel(app.axes.bif,bif.parameterName);
    ylabel(app.axes.bif,'v_o(nT_s) (V)');
    title(app.axes.bif,sprintf('Bifurcation diagram versus %s', bif.parameterName));

    good = isfinite(bif.llePerCycle);

    if any(good)

        plot(app.axes.lle,bif.parameterValues(good), bif.llePerCycle(good),'.-', ...
            'Color',[0.02 0.34 0.72], 'LineWidth',1.0,'MarkerSize',13);

        hold(app.axes.lle,'on');

        yline(app.axes.lle,0,'--k','Zero-LLE boundary');

        pos = good & bif.llePerCycle > 2e-3;

        if any(pos)
            scatter(app.axes.lle,bif.parameterValues(pos), bif.llePerCycle(pos),30, [0.90 0.16 0.18],'filled');
        end

        hold(app.axes.lle,'off');

    else
        text(app.axes.lle,0.5,0.5, 'No finite LLE values were calculated.', ...
            'Units','normalized', 'HorizontalAlignment','center', 'Color',[0.7 0 0]);
    end

    xlabel(app.axes.lle,bif.parameterName);
    ylabel(app.axes.lle,'LLE per switching cycle');
    title(app.axes.lle,'Largest Lyapunov exponent');
end

function drawMap(map)

    cla(app.axes.map);

    imagesc(app.axes.map,map.colValues,map.rowValues,map.code);
    axis(app.axes.map,'xy');

    xlabel(app.axes.map,map.colParameter);
    ylabel(app.axes.map,map.rowParameter);

    title(app.axes.map, 'Operating-regime map | 1=P1, 2=P2, 4=P4, 8=P8, 0=chaos, -2=high-period');

    cb = colorbar(app.axes.map);
    cb.Label.String = 'Detected orbit code';

    codes = unique(map.code(isfinite(map.code)));
    if ~isempty(codes)
        caxis(app.axes.map,[min(codes)-0.5,max(codes)+0.5]);
        cb.Ticks = codes;
    end
    colormap(app.axes.map,parula(256));
end

function p = readParameters

    p = buckParameters('defaults');

    p.L = positiveValue(app.controls.L.Value,'L')*1e-3;
    p.C = positiveValue(app.controls.C.Value,'C')*1e-6;
    p.R = positiveValue(app.controls.R.Value,'R');
    p.Vin = positiveValue(app.controls.Vin.Value,'Vin');
    p.Vref = app.controls.Vref.Value;
    p.Kp = nonnegativeValue(app.controls.Kp.Value,'Kp');
    p.fsw = positiveValue(app.controls.fsw.Value,'fsw')*1e3;
    p.Vbias = app.controls.Vbias.Value;
    p.rL = nonnegativeValue(app.controls.rL.Value,'rL');
    p.Vd = nonnegativeValue(app.controls.Vd.Value,'Vd');
    p.VrampMin = app.controls.VrampMin.Value;
    p.VrampMax = app.controls.VrampMax.Value;

    if ~isfinite(p.Vref) || ~isfinite(p.Vbias) ||  ~isfinite(p.VrampMin) || ~isfinite(p.VrampMax)
        error('All circuit and controller values must be finite numbers');
    end

    if p.VrampMax <= p.VrampMin
        error('Ramp maximum must be larger than ramp minimum.');
    end
    p = buckParameters('validate',p);
end

function clearPlots

    axesList = struct2cell(app.axes);

    for q = 1:numel(axesList)
        if isvalid(axesList{q})
            cla(axesList{q});
        end
    end

    app.cards.vo.value.Text= '-- V';
    app.cards.il.value.Text = '-- A';
    app.cards.duty.value.Text = '--';
    app.cards.mode.value.Text = '--';
    app.cards.class.value.Text = '--';
end

function busy(isBusy,message)

    app.fig.Pointer = ternary(isBusy,'watch','arrow');
    app.controls.run.Enable = ternary(isBusy,'off','on');

    drawnow;
    writeStatus(message,isBusy);
end

function writeStatus(message,keepPrevious)

    lines = regexp(message,'\n','split');
    lines = lines(:);

    if keepPrevious
        app.status.Value = [lines;app.status.Value];
    else
        app.status.Value = lines;
    end
end

function runSafely(task)

    try
        task();
    catch ME
        busy(false,'Ready after error.');
        writeStatus(['ERROR: ',ME.message],true);

        uialert(app.fig,ME.message,'Simulation error','Icon','error');
    end
end

function x = positiveValue(x,name)

    if ~isscalar(x) || ~isfinite(x) || x <= 0
        error('%s must be a positive number.',name);
    end
end

function x = nonnegativeValue(x,name)

    if ~isscalar(x) || ~isfinite(x)|| x < 0
        error('%s cannot be negative.',name);
    end
end

function n = requireInteger(x,name,low,high)

    if ~isscalar(x) || ~isfinite(x)
        error('%s must be a number.',name);
    end

    n = round(x);

    if n < low ||n >high
        error('%s must be between %g and %g.',name,low,high);
    end
end

function value = ternary(condition,yesValue,noValue)

    if condition
        value = yesValue;
    else
        value = noValue;
    end
end

function closeRequest(~,~)
    delete(app.fig);
end
end