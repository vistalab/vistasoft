function roiSaveHdf5(view, ROI)
% roiSaveHdf5(view, ROI, fname)
%
% Seeks to emulate the original saveROI function, except do more without
% forcing anyone to do more work.
%
% view - e.g. a member of INPLANE or VOLUME
% ROI - an ROI struct
%
% davclark@white - 03/17/06

% if (ieNotDefined('loadFromDefaultFlag'));
%     loadFromDefaultFlag=0;
% end

global mrSESSION;
global MRFILES;

pathStr = ['/', view.subdir, '/ROIs/', ROI.name];

MRFILES = mrFilesSet(MRFILES, 'path', pathStr);
[MRFILES, savePos] = mrfPos(MRFILES, 'new');

saveFlag = 'Yes';
% This could have some additional 'noninteractive' condition
if savePos > 0
    saveFlag = questdlg(['ROI "',ROI.name,'" already exists.  New Version?'], ...
                            'Save ROI','Yes','No','No');
    if strcmp(saveFlag, 'No')
        return
    end
end


if strcmp(saveFlag, 'Yes')
    disp(['Saving ROI "',ROI.name,'".']);

    % It's easy to add or overwrite metadata here
    ROI.subject = sessionGet(mrSESSION, 'subject');
    ROI.expTitle = sessionGet(mrSESSION,'title');
    ROI.alignment = sessionGet(mrSESSION, 'alignment');
    % We want to include information that will get us into
    % 1) Millimeter coordinates
    % 2) Taliarach space
    % - for now, the above will take us from Inplane to Volume coords
    
    MRFILES = mrfSaveHdf5(MRFILES, ROI, 'coords');    
else
    disp('ROI not saved.');
end

return
