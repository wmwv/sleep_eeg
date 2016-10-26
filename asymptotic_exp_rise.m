function model = asymptotic_exp_rise(t, A, tau)
    % ASYMPTOTIC_EXP_RISE
    % Fitting function for accumulated energy
    t0 = 0;
    model = A*(1-exp(-(t-t0)/tau));
