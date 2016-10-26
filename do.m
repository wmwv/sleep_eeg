% load('pan2-spectral-psmall-20161024.mat')

first_night_sleep_restriction = ([pall(:).condnum] == 2) & ([pall(:).night] == 1);
second_night_sleep_restriction = ([pall(:).condnum] == 2) & ([pall(:).night] == 2);
first_night_sleep_extension = ([pall(:).condnum] == 1) & ([pall(:).night] == 1);
second_night_sleep_extension = ([pall(:).condnum] == 1) & ([pall(:).night] == 2);

fn_sr = pall(first_night_sleep_restriction)
sn_sr = pall(second_night_sleep_restriction)
fn_se = pall(first_night_sleep_extension)
sn_se = pall(second_night_sleep_extension)

subject = 10

p = sn_sr(subject)

freq_channel = 8  % The first few channels have the main power
lead = 1
time = datetime(p.TIME_20s)
figure(1)
clf
subplot(3,1,1)
plot(time, squeeze(p.data_20s(lead, freq_channel, :)))
ylabel(sprintf('Power in Freq Channel %d', freq_channel))
xlabel('Time')
subplot(3,1,2)
plot(squeeze(p.auc_cum(lead,freq_channel,:)))
ylabel(sprintf('Accumulated Power in Freq Channel %d', freq_channel))
xlabel('Time-ordered samples')

subplot(3,1,3)
fit_this_trial(p, lead, freq_channel)
ylabel(sprintf('Accumulated Power in Freq Channel %d', freq_channel))


% Plot the full set of subjects

ylimit_freq = 1e6
figure(2)
clf
subplot(2,2,1,'replace')
hold on
for s = 1:length(fn_se)
    ps = fn_se(s)
    plot(squeeze(ps.auc_cum(lead,freq_channel,:)))
end
title('First Night Sleep Extension')
ylabel(sprintf('Accumulated Power in Freq Channel %d', freq_channel))
xlim(gca, [0,400])
ylim(gca, [0,ylimit_freq])

subplot(2,2,2,'replace')
hold on
for s = 1:length(sn_se)
    ps = sn_se(s)
    plot(squeeze(ps.auc_cum(lead,freq_channel,:)))
end
title('Second Night Sleep Extension')
xlim(gca, [0,400])
ylim(gca, [0,ylimit_freq])

subplot(2,2,3,'replace')
hold on
for s = 1:length(fn_sr)
    ps = fn_sr(s)
    plot(squeeze(ps.auc_cum(lead,freq_channel,:)))
end
title('First Night Sleep Restriction')
ylabel(sprintf('Accumulated Power in Freq Channel %d', freq_channel))
xlabel('Time-ordered samples')
xlim(gca, [0,400])
ylim(gca, [0,ylimit_freq])

subplot(2,2,4,'replace')
hold on
for s = 1:length(sn_sr)
    ps = sn_sr(s)
    plot(squeeze(ps.auc_cum(lead,freq_channel,:)))
end
title('Second Night Sleep Restriction')
xlabel('Time-ordered samples')
xlim(gca, [0,400])
ylim(gca, [0,ylimit_freq])

temp_auc=zeros([189,1759]);
for i=1:length(pall)
    thisdata=squeeze(pall(i).auc_cum(lead,freq_channel,:));
    temp_auc(i,1:length(thisdata))=thisdata;
end

%%%
fn_se_auc = zeros([length(fn_se), 1759]);
for i=1:length(fn_se)
    thisdata=squeeze(fn_se(i).auc_cum(lead,freq_channel,:));
    fn_se_auc(i,1:length(thisdata))=thisdata;
end

sn_se_auc = zeros([length(sn_se), 1759]);
for i=1:length(sn_se)
    thisdata=squeeze(sn_se(i).auc_cum(lead,freq_channel,:));
    sn_se_auc(i,1:length(thisdata))=thisdata;
end


fn_sr_auc = zeros([length(fn_sr), 1759]);
for i=1:length(fn_sr)
    thisdata=squeeze(fn_sr(i).auc_cum(lead,freq_channel,:));
    fn_sr_auc(i,1:length(thisdata))=thisdata;
end


sn_sr_auc = zeros([length(sn_sr), 1759]);
for i=1:length(sn_sr)
    thisdata=squeeze(sn_sr(i).auc_cum(lead,freq_channel,:));
    sn_sr_auc(i,1:length(thisdata))=thisdata;
end

mean_fn_se_auc = mean(fn_se_auc, 1);
mean_sn_se_auc = mean(sn_se_auc, 1);
mean_fn_sr_auc = mean(fn_sr_auc, 1);
mean_sn_sr_auc = mean(sn_sr_auc, 1);

figure(3)
hold on
plot(mean_fn_se_auc)
plot(mean_sn_se_auc)
plot(mean_fn_sr_auc)
plot(mean_sn_sr_auc)
legend('Mean First Night Sleep Extension', 'Mean Second Night Sleep Extension', 'Mean First Night Sleep Restriction', 'Mean Second Night Sleep Restriction')