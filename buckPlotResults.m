function buckPlotResults(action,varargin)

switch lower(action)
    case 'all'
        plotAll(varargin{:});
    case 'animate'
        animateLocal(varargin{:});
    otherwise
        error('Unknown plotting action: %s',action);
end
end

function plotAll(nom,bif,bifVin,map,verification) %#ok<INUSD>
sim=nom.sim;
figure('Name','Time response','Color','w');
subplot(2,1,1); plot(sim.t*1e3,sim.vO); grid on;
xlabel('Time (ms)'); ylabel('v_o (V)'); title(sprintf('Output voltage | mean = %.4f V',nom.metrics.meanVout));
subplot(2,1,2); plot(sim.t*1e3,sim.iL); grid on;
xlabel('Time (ms)'); ylabel('i_L (A)'); title(sprintf('Inductor current | min = %.4f A',nom.metrics.minIL));

n=size(sim.cycle.x,1); pc=sim.cycle.x(max(1,n-19):end,:);
figure('Name','Phase + Poincare','Color','w');
plot(sim.vO,sim.iL,'LineWidth',1); hold on;
scatter(pc(:,2),pc(:,1),24,'filled'); grid on;
xlabel('v_o (V)'); ylabel('i_L (A)'); title(sprintf('Phase space at K_p = %.3g',sim.params.Kp));
legend('Trajectory','Poincare samples','Location','best'); hold off;

seq=sim.cycle.x(max(1,n-149):end,:);
figure('Name','Poincare sequence','Color','w');
scatter(1:size(seq,1),seq(:,2),20,'filled'); grid on; box on;
xlabel('Settled switching-cycle index'); ylabel('v_o(nT_s) (V)');
title(sprintf('Poincare sequence | %s',nom.class.label));

figure('Name','PWM comparator','Color','w');
subplot(2,1,1); plot(sim.t*1e6,sim.vCtrl,'LineWidth',1); hold on;
plot(sim.t*1e6,sim.vRamp,'--','LineWidth',1); grid on;
xlabel('Time (microseconds)'); ylabel('Voltage (V)');
legend('v_{ctrl}','v_{ramp}','Location','best'); title('PWM comparator'); hold off;
subplot(2,1,2); stairs(sim.t*1e6,sim.switchState,'LineWidth',1); grid on;
ylim([-0.1 1.1]); xlabel('Time (microseconds)'); ylabel('Switch state'); title('1 = ON, 0 = OFF');

show=min(150,numel(sim.cycle.duty)); idx=numel(sim.cycle.duty)-show+1:numel(sim.cycle.duty);
meanDuty=mean(sim.cycle.duty(idx));
figure('Name','Duty ratio','Color','w'); scatter(idx,sim.cycle.duty(idx),18,'filled'); hold on;
plot([idx(1) idx(end)],[meanDuty meanDuty],'r--','LineWidth',1.3);
grid on; ylim([-0.05 1.05]); xlabel('Switching-cycle number'); ylabel('Duty ratio D_k');
title(sprintf('Duty ratio | mean = %.3f',meanDuty)); hold off;

figure('Name','Bifurcation diagram','Color','w'); scatter(bif.parameter,bif.vO,3,'.'); grid on;
xlabel(bif.parameterName); ylabel('v_o(nT_s) (V)'); title(['Bifurcation versus ' bif.parameterName]);

figure('Name','Vin bifurcation','Color','w'); scatter(bifVin.parameter,bifVin.vO,3,'.'); grid on;
xlabel(bifVin.parameterName); ylabel('v_o(nT_s) (V)'); title(['Bifurcation versus ' bifVin.parameterName]);

valid=isfinite(bif.llePerCycle); figure('Name','Largest Lyapunov exponent','Color','w');
if any(valid)
    x=bif.parameterValues(valid); y=bif.llePerCycle(valid);
    plot(x,y,'.-','LineWidth',1.1); hold on;
    plot([min(x) max(x)],[0 0],'k--','LineWidth',1.2); grid on;
    xlabel(bif.parameterName); ylabel('LLE per switching cycle'); title('Largest Lyapunov exponent');
    legend('Calculated LLE','Zero boundary','Location','best'); hold off;
else
    text(0.5,0.5,'No finite LLE values','Units','normalized','HorizontalAlignment','center'); grid on;
end

figure('Name','Stability map','Color','w'); imagesc(map.colValues,map.rowValues,map.code);
axis xy; colorbar; xlabel(map.colParameter); ylabel(map.rowParameter);
title('Operating-regime map: V_{in} versus K_p');
end

function animateLocal(sim,speedFactor)
if nargin<2||isempty(speedFactor), speedFactor=1; end
v=sim.vO(:); i=sim.iL(:); speedFactor=max(speedFactor,eps);
fig=figure('Name','Phase-space animation','Color','w'); ax=axes('Parent',fig);
hold(ax,'on'); grid(ax,'on'); xlabel(ax,'v_o (V)'); ylabel(ax,'i_L (A)');
xpad=max(1e-3,0.05*(max(v)-min(v))); ypad=max(1e-3,0.05*(max(i)-min(i)));
xlim(ax,[min(v)-xpad max(v)+xpad]); ylim(ax,[min(i)-ypad max(i)+ypad]);
trail=animatedline('Parent',ax,'Color',[0 0.447 0.741],'LineWidth',1.2);
point=plot(ax,v(1),i(1),'ro','MarkerFaceColor','r','MarkerSize',7);
frames=unique(round(linspace(1,numel(v),min(300,numel(v)))));
for k=frames
    if ~ishandle(fig), return; end
    addpoints(trail,v(k),i(k)); set(point,'XData',v(k),'YData',i(k));
    drawnow; pause(0.02/speedFactor);
end
end
