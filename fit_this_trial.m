function fitresults = fit_this_trial(p, lead, freq_channel)

auc = p.auc_cum(lead, freq_channel, :);
auc = squeeze(auc);

num_auc_points = length(auc);  % returns the length of the largest dimension
time = transpose(linspace(0, num_auc_points-1, num_auc_points));

% Fitting function
A = 7e5;  % uV^2
tau = 120;  % minutes

ft = fittype('asymptotic_exp_rise(x, A, tau)');
coeffnames(ft);
% Note that fittype reworks the StartPoint into its own order (apparently
% lexical).  We have to know that the order to StartPoint is [A, k, p0, t0] 

fitresults = fit(time, auc, ft, 'StartPoint', [A, tau]); % , 'Weight', 1+0*auc_pipr_obs)

% plot(time, auc)
plot(fitresults, time, auc)
%    plot(time-t0, pipr)
%    hold on
%    plot(fitresults, time(time_to_fit)-t0, pipr(time_to_fit))
%    xlabel('Time since stimulus [s]')
%    ylabel('PIPR [units unknown]')
%    hold off
