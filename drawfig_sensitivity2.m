
% Create figure
figure1 = figure('Color',[1,1,1],'OuterPosition',[0,0,1200,840],'PaperPositionMode','auto');

% Create axes
axes1 = axes('Parent',figure1,...
    'Position',[0.0986745213549337 0.155686274509804 0.879234167893962 0.75313725490196],...
    'FontSize',24);

box(axes1,'on');
hold(axes1,'all');
 
xlim(axes1,[50 1650]);
ylim(axes1,[97  100]);

Average=[98.7,98.7,98.5,98.7,99.0,99.2,99.3,99.3,99.2,99.2,99.3,99.3,99.2,99.3,99.2,99.3];  %各月的平均值
       Variance=[0.5,0.4,0.4,0.3,0.4,0.3,0.3,0.2,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1];   %各月的方差值
       Time=100:100:1600;
       errorbar(Time,Average,Variance,'color',[0 0 0],'LineWidth',4)    %函数调用格式 errorbar(A,B,X)
       xlabel('Iteration Number (K)'); ylabel('Revenue Ratio (%)');