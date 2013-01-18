function rmSetDataTYPES(vw, params)
% Write the retinotopic model stimulus parameters to the dataTYPES
%
%   rmSetDataTYPES(vw, params)

mrGlobals;

dt = viewGet(vw, 'dataTypeNumber');

% %This returns an error if the fields already in dt.retinotopyModelParams
% are not exactly the same as those in params.stim
%
% for scan = 1:numel(params.stim)
%     dataTYPES(dt) = dtSet(dataTYPES(dt),...
%         'retinotopyModelParams', params.stim(scan), scan);
% end

dataTYPES(dt) = dtSet(dataTYPES(dt),'retinotopyModelParams', params.stim);
    
saveSession

return

