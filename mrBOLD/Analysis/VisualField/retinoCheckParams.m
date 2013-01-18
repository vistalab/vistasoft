function params = retinoCheckParams(view, dt, scans);
% Check if visual field mapping ("retinotopy", though it doesn't
% need to be retinotopic) parameters have been set for the specified
% scans, giving the user an option to set them if they haven't been
% assigned yet.
%
% params = retinoCheckParams(view, <dt, scans>);
%
% Returns the parameters as a struct array of length(nScans).
% Will prompt the user to set any scans that haven't been set yet
% in the scan list.
%
% ras, 01/06: testing the waters if this code is needed. I see many
% other places where similar parameters are set, but none of them
% seem immediately useable to me.
if notDefined('view'), view = getCurView;                   end
if notDefined('dt'), dt = viewGet(view, 'curdt');           end
if notDefined('scans'), scans = viewGet(view, 'curscan');   end

mrGlobals;
params = [];

if isnumeric(dt)
    dtNum = dt;
    dt = dataTYPES(dtNum).name; 
else
    dtNum = existDataType(dt);
end

for i = 1:length(scans)
    check = retinoGetParams(view, dt, scans(i));

    if isempty(check)
        % not assigned: ask user if he/she wants to assign now
        annotation = dataTYPES(dtNum).scanParams(scans(i)).annotation;
        q = [sprintf('%s, scan %i (%s): ', dt, scans(i), annotation) ...
            'This scan doesn''t have any visual field-mapping ' ...
            'parameters assigned yet. Do you want to assign them now?'];
        resp = questdlg(q, mfilename, 'Yes', 'No', 'Yes');

        if isequal(resp, 'Yes')
            check = retinoSetParams(view, dt, scans(i));
        else
            error('No visual field map parameters set -- user aborted.');
        end
    end
    
    % at this point, check should be assigned, or we would have aborted
    if isempty(params)  % first scan
        params = check;
    else
        % add the current params to the struct array: copy a field
        % at a time, since the params for different scans may have 
        % different fields (different design types)    
        for f = fieldnames(check)'
            params(i).(f{1}) = check.(f{1});
        end
    end
end

return
