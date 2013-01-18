function tc = tc_detrendTimeCourse(tc);
%
% tc = tc_detrendTimeCourse(tc);
%
% Blur the time course UI time course, same
% as in blur tSeries plot.
%
%
% ras 03/30/05
if ieNotDefined('tc')
    tc = get(gcf,'UserData');
end

tc.wholeTc = detrendTSeries(tc.wholeTc(:), tc.params.detrend, ...
                            tc.params.detrendFrames);
tc.wholeTc = tc.wholeTc(:)';  % diff't options return in diff't formats

anal = er_chopTSeries2(tc.wholeTc, tc.trials, tc.params);

% assign over to tc struct 
tc = mergeStructures(tc, anal);

% re-appy GLM if it's already been applied
if isfield(tc, 'glm'), tc = tc_applyGlm(tc); end

if checkfields(tc, 'ui', 'fig')
    set(gcf,'UserData',tc);
end

timeCourseUI;

return
