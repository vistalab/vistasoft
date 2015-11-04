function dwped = dtiInitPhaseDim(dwRawPed)
%
%  dwped = dtiInitPhaseDim(dwParams,dwRaw)
%
% Make sure there is a valid phase-encode dir, as this is crucial for
% eddy-current correction. If the phase_dim is not valid in the dwRaw or
% not set in dwParams.phaseEncode prompt the user for it.
%
% If the phase encode direction is not correct in dwRaw.phase_encode. Here
% we ask the user to tell us what it is. We could read this from the dicom
% if we were smart about it. It would be in the dicom header - we would
% have to know where the raw dicoms are and get them out if they're zipped.
% (dicominfo will read the dicom header).
%
%
% INPUTS
%       (dwRawPed) - passed in from dtiInit
% RETURNS
%       dwped - with a valid phase_dim
%
% Web Resources
%       mrvBrowseSVN('dtiInitPhaseDim');
%
% (C) Stanford VISTA, 8/2011 [lmp]
%

%%
%
% Set it to output what was passed in and check it
dwped = dwRawPed;

% Handle the case where the value is passed in as a string
if ischar(dwped)
    dwped = str2double(dwped);
end

% Check the value passed in: If the phase encode direction is not a valid
% value prompt the user until they give a valid value (default is 2 = 'col'
% =  'A/P').
while (dwped < 1 || dwped > 3)
    prompt = sprintf('Phase-encode dir is currently [ %d ], but must be 1 2 or 3. \n (1 = L/R "row", 2 = A/P "col"). \n Enter new value:\n', dwRawPed);
    resp = inputdlg(prompt, 'Set phase encode direction', 1, {'2'});
    if ~isempty(resp)
        dwped = round(str2double(resp{1}));
    elseif isempty(resp)
        error('User aborted! [dtiInitPhaseDim]');
    end
end


return


