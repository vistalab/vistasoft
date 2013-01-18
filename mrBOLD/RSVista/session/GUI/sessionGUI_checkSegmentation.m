function GUI = sessionGUI_checkSegmentation(session);
% Checks if a segmentation is loaded and up-to-date, trying to load it if
% not.
%
% <GUI> = sessionGUI_checkSegmentation(<session=cur session>);
%
% This loads the segmentation for the selected session into the
% VOLUME{1} view. Defaults to Gray view; not sure if you can get
% a segmentation for a volume view?
%
% Checks that the segmentation exists first. If it doesn't, but it can
% be installed, asks the user if he/she'd like to install it.
%
% Updates the field GUI.settings.segmentation to keep track of the
% most recently loaded segmentation. (Doesn't automatically do this when
% you navigate sessions, b/c it takes time.)
%
% ras, 07/06.
mrGlobals2;

if notDefined('session'), session = GUI.settings.session; end

% GUI.settings.segmentation lists the session for the last-loaded
% segmentation
[p segSession] = fileparts(GUI.settings.segmentation);
[p curSession] = fileparts(GUI.settings.session);
if isempty(segSession) | ~isequal(segSession, curSession)
    if exist(fullfile(HOMEDIR, 'Gray', 'coords.mat'))
        VOLUME{1} = switch2Gray(VOLUME{1});

    else
        % Gray coords don't exist, but see if we can build them
        if isfield(mrSESSION, 'alignment')
            % ask user if they'd like to install it
            q = sprintf(['No segmentation is currently installed for ' ...
                'session %s. Would you like to install one now? '], ...
                curSession);
            resp = questdlg(q, mfilename);
            if isequal(resp, 'Yes')
                installSegmentation(0);
            else
                myErrorDlg('No Segmentation Installed.');
            end
        else
            myErrorDlg('No Segmentation Installed; No alignment installed.');
        end

        VOLUME{1} = switch2Gray(VOLUME{1});
    end

    if checkfields(VOLUME{1}, 'mesh')
        for ii = 1:length(VOLUME{1}.mesh)
            VOLUME{1}.mesh{ii}.vertexGrayMap = ...
                mrmMapVerticesToGray(VOLUME{1}.coords, VOLUME{1}.nodes, ...
                VOLUME{1}.mmPerVox, VOLUME{1}.edges);
        end
    end

end


GUI.settings.segmentation = session;



return
