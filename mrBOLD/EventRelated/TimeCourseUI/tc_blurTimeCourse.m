function tc = tc_blurTimeCourse(tc);
%
% tc = tc_blurTimeCourse(tc);
%
% Blur the time course UI time course, same
% as in blur tSeries plot.
%
%
% ras 03/30/05
if ieNotDefined('tc')
    tc = get(gcf,'UserData');
end

tc.wholeTc = imblur(tc.wholeTc);

anal = er_chopTSeries2(tc.wholeTc, tc.trials, tc.params);
                   
% assign over to tc struct (ugly, but there are other fields
% in tc I don't want to erase -- is there a way to eat the whole
% struct in one go?)
fields = fieldnames(anal);
for i = 1:length(fields)
    tc.(fields{i}) = anal.(fields{i});
end

% re-appy GLM if it's already been applied
if isfield(tc, 'glm'), tc = tc_applyGlm(tc); end

if checkfields(tc, 'ui', 'fig')
    set(gcf,'UserData',tc);
end

timeCourseUI;

return
