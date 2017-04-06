function [vw, ok] = loadROI(vw, filename, select, clr, absPathFlag, local)
%
% [vw, ok] = loadROI(vw, filename, [select], [color], [absPathFlag], [local=1])
%
% Loads ROI from a file, adds it to the ROIs field of view, and
% selects it.
%
% filename: cell array of strings (e.g, 'V1L' that determines ROI filename)
% select: if non-zero, chooses the new ROI as the selectedROI
%         (default=1).
% color: sets color for drawing the ROI.  If unspecified, uses
%        the color saved in the ROI file.  If no color is saved
%        in the ROI file, uses 'b' as the default.
%
% Returns a view with the ROI added (if successful), and a status flag
% in ok: 1 if file was found and loaded, 0 otherwise.

% FILE HISTORY:
% djh, 1/24/98
% rmk, 1/12/99 changed to accomodate loading multiple ROIs at once
% dbr, 1/13/99 allow single string spec for ROI name.
% dbr, 10/3/00 Use absolute path specification.
% rfd, 2003.08.14 missing files now generate warnings rather than errors.
% This has the added benefit of not leaving the UI in an ugly state when
% some files are not found.
% arw, 02/13/04 Added flag to allow loading ROIs using an absolute path
% name.
% ras, 05/06 Doesn't error if file doesn't exist, just warns. Also,
% commented out feedback.
% ras, 02/07 added ok flag.

if notDefined('select'),            select=1;           end
if notDefined('absPathFlag'),       absPathFlag=0;      end
if notDefined('local'),
    local = ismember(vw.viewType, {'Inplane' 'Flat'});
end

ok = 0;

if notDefined('filename') || isequal( lower(filename), 'dialog' )
    [filename, ok] = getROIfilename(vw, local);
    if ~ok, return; end
end

% Force filename input to be a unity length cell array:
if (~iscell(filename) && ~isempty(filename))
    filename = {filename};
end

verbose = prefsVerboseCheck;

for i = 1:length(filename)
    
    if (absPathFlag)
        pathStr = filename{i};
    else
        pathStr = fullfile( roiDir(vw,local), filename{i} );
    end
    
    [~,~,ext] = fileparts(pathStr);
    
    if check4File(pathStr, ext)
        if verbose>1,    disp(['loading ', pathStr]);   end
        
        switch lower(ext)
            case {'.nii' '.gz'}
                viewType = viewGet(vw, 'view type');
                switch lower(viewType)
                    case {'gray' 'volume'}
                        vw = nifti2ROI(vw, pathStr);
                    otherwise
                        error('nifti2ROI not yet implemented for viewtype %s', viewType);
                end
            case {'.mat', ''}
                load(pathStr, 'ROI');
                
                % Coerce to current format with viewType instead of viewName
                if isfield(ROI,'viewName')
                    ROI = rmfield(ROI,'viewName');
                    ROI.viewType = vw.viewType;
                end
                
                if (~notDefined('clr')),        ROI.color=clr;      end
                
                if ~isfield(ROI,'color'),       ROI.color='b';      end
                
                if ~isfield(ROI, 'comments'),   ROI.comments = '';  end
                
                
                % let's enforce single-precision coords, to be consistent w/
                % Volume and Gray vw.coords:
                ROI.coords = single(ROI.coords);
                
                % Check to see if ROI filename matches the ROI.name. If not, force
                % ROI.name to be ROI.filename
                [ROIpathname, ROIfilename] = fileparts(filename{i}); %#ok<ASGLU>
                
                if (~strcmp(ROI.name, ROIfilename))
                    fprintf(['\nWarning! ROI.name %s does not match the filename ' ...
                        '%s.\nI will make the two match by changing ROI.name ' ...
                        '(but I will not re-save the ROI). \n'], ...
                        ROI.name, ROIfilename);
                    ROI.name = ROIfilename;
                end
                
                % ras 06/06: don't select here (multiple GUI refreshes for many ROIs),
                % but wait until all ROIs are loaded, then select the last one:
                vw = addROI(vw, ROI, 0);
                
                ok(i) = 1;
                
            otherwise
                error('Unrecognized file extension %s.', ext);
        end
    else
        % ras 01/07: don't stop everything if we can't find the ROI
        warning('Could not find ROI file %s', pathStr); %#ok<WNTAG>
        ok(i) = 0;
        
    end
end

if verbose>1,  disp('Done loading ROIs'); end

% select the last ROI loaded:
if select, vw = selectROI(vw, length(vw.ROIs)); end


return
