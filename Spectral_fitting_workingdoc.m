temp_auc=zeros([189,1759]);
for i=1:length(pall2)
    thisdata=squeeze(pall2(i).auc_cum(1,2,:));
    temp_auc(i,1:length(thisdata))=thisdata;
end

temp_auc(77,:)=[]; %reject because values are insanely high at time index 157

se_n2=[pall2(:).condnum]==1 & [pall2(:).night]==2;
sr_n2=[pall2(:).condnum]==2 & [pall2(:).night]==2;
se_n1=[pall2(:).condnum]==1 & [pall2(:).night]==1;
sr_n1=[pall2(:).condnum]==2 & [pall2(:).night]==1;

figure;
hold on;
subplot(2,2,1)
plot(1:1759,temp_auc(se_n1,:))
subplot(2,2,2)
plot(1:1759,temp_auc(se_n2,:))
subplot(2,2,3)
plot(1:1759,temp_auc(sr_n1,:))
subplot(2,2,4)
plot(1:1759,temp_auc(sr_n2,:))
subplot(2,2,1)
ylim([0 3000000])
subplot(2,2,3)
ylim([0 3000000])
subplot(2,2,4)
ylim([0 3000000]

subplot(2,2,1)
title('N1 SE')
subplot(2,2,2)
title('N2 SE')
subplot(2,2,3)
title('N1 SR')
subplot(2,2,4)
title('N2 SR')
subplot(2,2,4)

subplot(2,2,1)
ylim([0 2000000])
xlim([0 600])
subplot(2,2,2)
ylim([0 2000000])
xlim([0 600])
subplot(2,2,3)
ylim([0 2000000])
xlim([0 600])
subplot(2,2,4)
ylim([0 2000000])
xlim([0 600])

    for index=1:length(data)
%         subplot(2,4,index);
        plot_pipr_trialv5(p,index,'bc',eyes(ct),yposition)
        yposition=yposition+5;
    end
    set(gca,'YTickLabel',[0:4+1])
    set(gcf,'NextPlot','add');
    axes;
    h=title(sprintf('PIPR Fits BC %d %s %s Eye',p.(eyes(ct)).id,p.(eyes(ct)).date,upper(eyes(ct))));
    set(gca,'Visible','off');
    set(h,'Visible','on');
    
    set(gcf,'NextPlot','add');
    axes;
    h=xlabel('time (seconds)'); 
    set(gca,'Visible','off');
    set(h,'Visible','on');
    
    set(gcf,'NextPlot','add');
    axes;
    h=ylabel('Trial Number');
    set(gca,'Visible','off');
    set(h,'Visible','on');
    
    
    hold off;