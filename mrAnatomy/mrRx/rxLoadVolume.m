function rxLoadVolume(rx,volPath,type);
%
% rxLoadVolume([rx],[volPath],[type]):
%
% Load a new volume to be either the
% main xformed volume or reference volume
% for mrRx. After loading, checks fields
% in the GUI to make sure they're consistent
% with the new settings.
%
% type: string which specifies which fields to
% load the new volume in to. Can be 'vol' or
% 'ref'. Defaults to 'vol'.
%
% If volPath is omitted, brings up a dialog.
%
% 
% ras 03/05
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ieNotDefined('type')
    type = 'vol';
end

if ieNotDefined('volPath')
    % put up a dialog
    opts = {...
            '*.dat' 'mrVista vAnatomy files' ...
            '*.img' 'ANALYZE fies' ...
            '*.dcm' 'DICOM files' ...
            'I*'  'I files' ...
        };
    [fname pth] = uigetfile(opts,'Load A New Volume...');
    volPath = fullfile(pth,fname);
end

[vol mmpervox] = loadVolume(volPath,'reorient');

% set appropriate fields in rx struct
switch type
    case 'vol',
    case 'ref',
end


% set ui controls


return

