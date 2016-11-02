function output=explore_data(pall)

first_night_sleep_restriction = ([pall(:).condnum] == 2) & ([pall(:).night] == 1);
second_night_sleep_restriction = ([pall(:).condnum] == 2) & ([pall(:).night] == 2);
first_night_sleep_extension = ([pall(:).condnum] == 1) & ([pall(:).night] == 1);
second_night_sleep_extension = ([pall(:).condnum] == 1) & ([pall(:).night] == 2);

fn_sr = pall(first_night_sleep_restriction);
sn_sr = pall(second_night_sleep_restriction);
fn_se = pall(first_night_sleep_extension);
sn_se = pall(second_night_sleep_extension);

subject = 10;

p = sn_sr(subject);

% Loose maximum of the power in a given frequency bin
% Intended for use in plotting later.
% There are 39 freq channels
auc_freq_ylimit = 1e4 * ones([39]);
auc_freq_ylimit(1:4) = [1e7, 1e6, 1e5, 1e4];

freq_channel = 2;  % The first few channels have the main power
lead = 1;
time = datetime(p.TIME_20s);

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
ylim(gca, [0,auc_freq_ylimit(freq_channel)])

subplot(2,2,2,'replace')
hold on
for s = 1:length(sn_se)
    ps = sn_se(s)
    plot(squeeze(ps.auc_cum(lead,freq_channel,:)))
end
title('Second Night Sleep Extension')
xlim(gca, [0,400])
ylim(gca, [0,auc_freq_ylimit(freq_channel)])

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
ylim(gca, [0,auc_freq_ylimit(freq_channel)])

subplot(2,2,4,'replace')
hold on
for s = 1:length(sn_sr)
    ps = sn_sr(s)
    plot(squeeze(ps.auc_cum(lead,freq_channel,:)))
end
title('Second Night Sleep Restriction')
xlabel('Time-ordered samples')
xlim(gca, [0,400])
ylim(gca, [0,auc_freq_ylimit(freq_channel)])

all_auc=zeros([length(pall),1759]);
for i=1:length(pall)
    thisdata=squeeze(pall(i).auc_cum(lead,freq_channel,:));
    all_auc(i,1:length(thisdata))=thisdata;
end

fn_se_auc = all_auc(first_night_sleep_extension,:);
sn_se_auc = all_auc(second_night_sleep_extension,:);
fn_sr_auc = all_auc(first_night_sleep_restriction,:);
sn_sr_auc = all_auc(second_night_sleep_restriction,:);

figure(3)
clf
hold on
which='Median';
if strcmp(which, 'Mean')
    plot(mean(fn_se_auc, 1), '--', 'DisplayName', 'Sleep Extension : First Night', 'LineStyle', '--')
    plot(mean(sn_se_auc, 1), '--', 'DisplayName', 'Sleep Extension : Second Night')
    plot(mean(fn_sr_auc, 1), 'DisplayName', 'Sleep Restriction : First Night')
    plot(mean(sn_sr_auc, 1), 'DisplayName', 'Sleep Restriction : Second Night')
else
    plot(median(fn_se_auc,1), '--', 'DisplayName', 'Sleep Extension : First Night')
    plot(median(sn_se_auc,1), '--', 'DisplayName', 'Sleep Extension : Second Night')
    plot(median(fn_sr_auc,1), 'DisplayName', 'Sleep Restriction : First Night')
    plot(median(sn_sr_auc,1), 'DisplayName', 'Sleep Restriction : Second Night')
end

AX.FontSize = 20;
xlabel('Time-ordered Samples', 'FontSize', 24)
ylabel(sprintf('Accumulated Power in Freq Channel %d', freq_channel), 'FontSize', 24)
title(strcat(which, ' AUC across the Population'), 'FontSize', 36)
ylim([0, auc_freq_ylimit(freq_channel)])
l = legend('show');
set(l, 'Location', 'northwest')
set(l, 'FontSize', 24);


sprintf('First night SE: %d', length(fn_se))
sprintf('Second night SE: %d', length(sn_se))
sprintf('First night SR: %d', length(fn_sr))
sprintf('Second night SR: %d', length(sn_sr))

figure(4)
% Fit asymptotic exp rise to each subject*night
output = zeros([length(pall), 2]) + nan
for i = 1:length(pall)
    p = pall(i);
    try
        this_fit_coeff = fit_this_trial(p, lead, freq_channel);
    end
    output(i,:) = [this_fit_coeff.A, this_fit_coeff.tau];
end

figure(5)
hold on
plot(output(:,1), output(:,2), 'o')
plot(output(first_night_sleep_extension,1), output(first_night_sleep_extension,2), 'ro', 'DisplayName', 'Sleep Extension : First Night')
plot(output(second_night_sleep_extension,1), output(second_night_sleep_extension,2), 'go', 'DisplayName', 'Sleep Extension : Second Night')
plot(output(first_night_sleep_restriction,1), output(first_night_sleep_restriction,2), 'bo', 'DisplayName', 'Sleep Restriction : First Night')
plot(output(second_night_sleep_restriction,1), output(second_night_sleep_restriction,2), 'ko', 'DisplayName', 'Sleep Restriction : Second Night')
legend('show')
xlabel('A')
ylabel('tau')
xlim(gca, [0,2.5e6])
ylim(gca, [0,1e3])

figure(6)
hold on
bins = linspace(0,4e6,21)
% h0 = histogram(output(:,1), bins)
% set(h0, 'EdgeColor', 'k', 'FaceColor', 'none', 'DisplayStyle', 'stairs')
h1 = histogram(output(first_night_sleep_extension,1), bins+1e5, 'DisplayName', 'Sleep Extension : First Night');
set(h1, 'EdgeColor', 'r', 'FaceColor', 'none', 'DisplayStyle', 'stairs');
set(h1, 'EdgeColor', 'r')
h2 = histogram(output(second_night_sleep_extension,1), bins+2e5, 'DisplayName', 'Sleep Extension : Second Night');
set(h2, 'EdgeColor', 'g', 'FaceColor', 'none', 'DisplayStyle', 'stairs');
set(h2, 'EdgeColor', 'g')
h3 = histogram(output(first_night_sleep_restriction,1), bins+3e5, 'DisplayName', 'Sleep Restriction : First Night');
set(h3, 'EdgeColor', 'b', 'FaceColor', 'none', 'DisplayStyle', 'stairs');
set(h3, 'EdgeColor', 'b')

h4 = histogram(output(second_night_sleep_restriction,1), bins+4e5, 'DisplayName', 'Sleep Restriction : Second Night');
set(h4, 'EdgeColor', 'k', 'FaceColor', 'none', 'DisplayStyle', 'stairs');
set(h4, 'EdgeColor', 'k')
legend('show')



figure(7)
hold on
bins = linspace(0,2e3,21)
% h0 = histogram(output(:,1), bins)
% set(h0, 'EdgeColor', 'k', 'FaceColor', 'none', 'DisplayStyle', 'stairs')
h1 = histogram(output(first_night_sleep_extension,2), bins+1e2, 'DisplayName', 'Sleep Extension : First Night');
set(h1, 'EdgeColor', 'r', 'FaceColor', 'none', 'DisplayStyle', 'stairs');
set(h1, 'EdgeColor', 'r')
h2 = histogram(output(second_night_sleep_extension,2), bins+2e2, 'DisplayName', 'Sleep Extension : Second Night');
set(h2, 'EdgeColor', 'g', 'FaceColor', 'none', 'DisplayStyle', 'stairs');
set(h2, 'EdgeColor', 'g')
h3 = histogram(output(first_night_sleep_restriction,2), bins+3e2, 'DisplayName', 'Sleep Restriction : First Night');
set(h3, 'EdgeColor', 'b', 'FaceColor', 'none', 'DisplayStyle', 'stairs');
set(h3, 'EdgeColor', 'b')

h4 = histogram(output(second_night_sleep_restriction,2), bins+4e2, 'DisplayName', 'Sleep Restriction : Second Night');
set(h4, 'EdgeColor', 'k', 'FaceColor', 'none', 'DisplayStyle', 'stairs');
set(h4, 'EdgeColor', 'k')
legend('show')

