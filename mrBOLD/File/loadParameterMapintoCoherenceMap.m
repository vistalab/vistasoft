function view=loadParameterMapintoCoherenceMap(view);
% loadParameterMapintoCoherenceMap - convert parmap to comap and store
% there
% 
% view=loadParameterMapintoCoherenceMap(view);
%
% This function converts the parameter map into a coherence map (values
% from [0 1] and stores it. It differs from the existing function in that
% it does take both negative and positive values in account. So that we can
% create and threshold both negative and positive p values at once.
%
% 2007/02 SOD & YM: wrote it.

if ieNotDefined('view'), error('Need view struct'); end;

% load parameter maps:
map = viewGet(view,'map');
if isempty(map),
    view = loadParameterMap(view);
end;
% put something in amp and ph fields because some operations expect
% that
if isempty(view.ph),
    fillPh = true;
    ph = map;
else,
    fillPh = false;
end
if isempty(view.amp),
    fillAmp = true;
    amp = map;
else,
    fillAmp = false;
end
 

% loop over each map and make corresponding coherence map
% we scale to [0 1] by dividing by the abs(max) of that map
co = map;
for n=1:numel(map),
    tmp = abs(map{n});
    if ~isempty(max(tmp(:))),
        tmp = tmp./max(tmp(:));
    end;
    co{n} = tmp;
    if fillPh,  ph{n}  = zeros(size(tmp)); end
    if fillAmp, amp{n} = zeros(size(tmp)); end
end;

% store back in view
view = viewSet(view,'co',co);
if fillPh,  view = viewSet(view,'ph',ph);   end
if fillAmp, view = viewSet(view,'amp',amp); end
  

return;
    
