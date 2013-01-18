function dataTYPES = UpdateDateTypes(dataTYPES,mrSESSION)
% update dataTYPES(1).scanParams.nFrames, framePeriod, slices, cropSize
%
%  dataTYPES = UpdateDateTypes(dataTYPES,mrSESSION);
%
% Various dataTYPES parameters are supposed to be consistent with
% mrSESSION.  This is because the original design didn't enforce no
% redundancy.  This routine coordinates the values by pushing the mrSESSION
% values into the dataTYPES slots.
%
% This whole approach has me worried. It would be much better to represent
% variables uniquely - BW 
% 
% The values updated are:
%   dataTYPES(1).scanParams.nFrames, framePeriod, slices, cropSize  
%
% djh 9/26/2001

for iScan = 1:length(mrSESSION.functionals)
    dataTYPES(1).scanParams(iScan).nFrames = mrSESSION.functionals(iScan).nFrames;
    dataTYPES(1).scanParams(iScan).framePeriod = mrSESSION.functionals(iScan).framePeriod;
    dataTYPES(1).scanParams(iScan).slices = mrSESSION.functionals(iScan).slices;
    dataTYPES(1).scanParams(iScan).cropSize = mrSESSION.functionals(iScan).cropSize;
end

% Clean up/delete any other data types
if length(dataTYPES) > 1
    typeNames = '';
    for itype = 2:length(dataTYPES)
        typeNames = [typeNames,', ',dataTYPES(itype).name];
    end
    deleteFlag = questdlg(['Data types may be out of date because of changes you may have made to mrSESSION. Clean up and delete these data types?'],...
        'Delete data types?','Yes','No','Yes');
    if strcmp(deleteFlag,'Yes')
        for itype = 1:length(dataTYPES)
            removeDataType(dataTYPES(itype).name);
        end
        dataTYPES = dataTYPES(1);
    end
end

return