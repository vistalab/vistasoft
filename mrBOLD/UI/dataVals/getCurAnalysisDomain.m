function domain=getCurAnalysisDomain(view)
% domain=getCurAnalysisDomain(view)
% Returns 'time' if the view.ui.analysisDomainButtons(1) is set
% otherwise return 'frequency'
if (get(view.ui.analysisDomainButtons(1),'Value'))

    domain='time';
else
    domain='frequency';
end
