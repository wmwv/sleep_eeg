% load('pan2-spectral-psmall-20161102.mat')
pall=addusecd_tospecpall(pall);
pall_winsubs=resizeSpecPall_winsubs(pall);

output = explore_data(pall_winsubs);

first_night_sleep_restriction = ([pall_winsubs(:).condnum] == 2) & ([pall_winsubs(:).night] == 1);
second_night_sleep_restriction = ([pall_winsubs(:).condnum] == 2) & ([pall_winsubs(:).night] == 2);
first_night_sleep_extension = ([pall_winsubs(:).condnum] == 1) & ([pall_winsubs(:).night] == 1);
second_night_sleep_extension = ([pall_winsubs(:).condnum] == 1) & ([pall_winsubs(:).night] == 2);
