function pathStr = roiDir(vw,local)
%
% pathStr = roiDir(vw, [local=1])
%
% Return the directory path for loading/saving ROIs for a view, based
% on whether we are saving locally or globally.
%
% If local=1, will return an ROI directory for the local session.
%             The general location is:
%             [HOMEDIR] / [viewType] / ROIs
% If local=0, ROI will be saved according to the 'defaultROIPath'
%             preference variable. If this variable isn't found,
%             will ask the user and set the preference.
%
%             This ROI directory is relative to the anatomy path
%             (see getAnatomyPath). 
global  HOMEDIR


if (notDefined('vw')),      vw = getCurView;  end
if (notDefined('local')),     
	local =  ismember(vw.viewType, {'Inplane' 'Flat'});
end

pathStr = '';


if (local)
    % local ROI directory
    pathStr = fullfile(HOMEDIR,vw.subdir,'ROIs');

else
    % shared ROI directory
    if ismember(vw.viewType, {'Gray' 'Volume'})

        if ispref('VISTA','defaultROIPath')
            ROIdir = getpref('VISTA','defaultROIPath');
			
			% this code will build an absolute path relative to the 
			% HOMEDIR, if appropriate, and not relative to it, if
			% appropriate, while returning where you are (even if it's not
			% HOMEDIR) - ras, 05/10/07
			callingDir = pwd;
			cd(HOMEDIR);
            pathStr = fullpath( fullfile(getAnatomyPath, ROIdir) );
			cd(callingDir);
        else
            if ispref('VISTA', 'verbose') && getpref('VISTA', 'verbose')
                fprintf('[%s]: default ROI dir is ''ROIs'' in anatomy directory.\n', ...
                    mfilename);
            end
			pathStr = fullfile( getAnatomyPath, 'ROIs' );
        end % End check on preference existing
        
    elseif isequal(vw.viewType, 'Flat')
        % ideally, there would be separate ROIs/ subdir for each
        % flat file -- but this will work for now:
        % (ras, 01/07):
        
        % The following line has no effect and hence was commented out. Is
        % 'ROIdir' supposed to be 'pathStr'?
        % ROIdir = fullfile(getAnatomyPath, 'FlatROIs'); 
        
    else % This is not a Volume-type view.

        disp('You cannot use a default (session-independent) ROI directory for a non-volume-type view');
        pathStr=[];
        return;

    end % End check on view type

end % End check on flag


% make it if it's not there
if ~exist(pathStr,'dir') && ~isempty(pathStr)
    fprintf('Making ROI dir %s ...\n', pathStr);
    ensureDirExists(pathStr);
end

return;
