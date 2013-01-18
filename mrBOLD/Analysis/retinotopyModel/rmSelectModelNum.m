function sel = rmSelectModelNum(view);
% Put up a dialog to select a saved retinotopy model.
%
%  sel = rmSelectModelNum(view);
%
% ras, 12/2006.
if notDefined('view') view = getCurView; end

model = viewGet(view, 'rmmodel');

if isempty(model)
    sel = 0;
    return
end

if numel(model)==1
    sel = 1;
else
    for n = 1:length(model),
        modelNames{n} = rmGet(model{n},'desc');
    end;
    dlg.fieldName = 'modelName';
    dlg.style = 'popup';
    dlg.list = modelNames;
    dlg.string = 'Analyze which Retinotopy model?';
    dlg.value = 1;
    resp = generalDialog(dlg, mfilename);
    sel = cellfind(modelNames, resp.modelName);
    viewSet(view, 'rmModelNum', sel);
end

return
