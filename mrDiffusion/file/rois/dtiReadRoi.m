function roi = dtiReadRoi(fileName, xformParams)
%
%  roi = dtiReadRoi([fileName], [xformParams])
%
% HISTORY:
%  2005.02.24 RFD: pulled code from other places to modularize.
%  2008.04.01 RFD: now forces ROI coords to 'double' type.

if(~exist('fileName','var') || isempty(fileName))
    [f, p] = uigetfile({'*.mat';'*.*'}, 'Load ROI file...');
    if(isnumeric(f)), disp('Read ROI canceled.'); roi=[]; return; end
    fileName = fullfile(p,f);
end
if(~exist('xformParams','var')) xformParams = []; end
load(fileName); 

% We now save version and coordinate space fields. But for backwards compatability....
if(~exist('versionNum')) versionNum = 0.1; end
if(~exist('coordinateSpace')) coordinateSpace = 'acpc'; end
if ~exist('roi','var'), error('No ROI variable found.'); end

% New field in ROI struct for the DTI query ID. We alway reset it to -1
% when loading to indicate no associated dtiQuery ROI.
roi.query_id = -1;

roi.coords = double(roi.coords(~any(isnan(roi.coords')),:));
roi.visible = 1;
if(~strcmp(coordinateSpace,'acpc'))
    % try to find a matching coordinate space xform
    if(~isfield(xformParams,'name'))
        if(strcmp(coordinateSpace,'MNI'))
            csInd = 1;
        else
            error('t1NormParams has an old format (no coord space name).');
        end
    else
        csInd = strmatch(coordinateSpace, {xformParams.name}, 'exact');
        if(isempty(csInd))
            warning(['No coord spaces matching ROI coord space "' coordinateSpace '".']);
        end
    end
    if(~isempty(xformParams) && ~isempty(xformParams(csInd)))
        if(~isfield(xformParams(csInd),'sn') || isempty(xformParams(csInd).sn))
            disp(['Subject data appear to be in the same space as the ROI (' coordinateSpace ')- not warping ROI...']);
        else
            disp(['Warping ROI coords from ' coordinateSpace ' space to this subject''s space...']);
            % *** TO DO: we assume that the xform is an SPM-style sn struct. We
            % should figure out how to support other xforms.
            roi.coords = mrAnatXformCoords(xformParams(csInd).sn, roi.coords);
        end
    else
        disp(['NOTE: ROI coordinate space is ' coordinateSpace ', but there are no spatial norm params- ROI loaded WITHOUT coordinate transform.']);
    end
end

return;
