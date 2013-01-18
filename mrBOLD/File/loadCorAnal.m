function vw= loadCorAnal(vw, corAnalFile, computeIfNeeded)
% Loads corAnal (coherence analysis) file and fills co, amp, and ph slots
% in the view structure.
%
% vw = loadCorAnal(vw, [corAnalFile], [computeIfNeeded=1])
%
% If you change this function make parallel changes in:
%   loadCorAnal, loadResStdMap, loadStdMap, loadMeanMap
%
% corAnalFile: path to the corAnal file. If it is empty, assumes
%			   it is 'corAnal.mat' in the view's dataDir. 
%			   If it's one of 'ask' or 'dialog', pops up a dialog to let
%			   the user select.
%
% computeIfNeeded: if 1, and the corAnalFile is not found, will compute it
%			   for all scans in the view's current data type. Otherwise, 
%			   just warns the user and returns an unmodified view. 
%			   [Default: 1]
%
% djh, 1/9/98
% dbr, 6/23/99  Modified to use fullfile for NT/Unix platform
%               compatibility.
% djh, 2/2001, mrLoadRet 3.0
% create the full corAnalFile if dataType not original
% sod, 7/2005,  Added option to look for CorAnal file (ask param).
% will be used from fileMenu but other calls will remain the same.
% ras, 7/2007,  added computeIfNeeded argument.
if notDefined('vw'),		vw = getCurView;		end
if notDefined('corAnalFile')
	corAnalFile = fullfile(dataDir(vw), 'corAnal.mat');
end

if notDefined('computeIfNeeded'), computeIfNeeded = 0; end % Making this ==1 breaks a bunch of stuff in the Flat view as far as I can tell ARW 080807
if notDefined('loadMap'), loadMap=0;    end

if ismember(lower(corAnalFile), {'ask' 'dialog' 'select'})
	corAnalFile = getPathStrDialog(dataDir(vw), ...
					['Choose CorAnal map file name'],['*.mat']);
end

if ~exist(corAnalFile,'file')
     corAnalFile = fullfile(dataDir(vw), corAnalFile);
end

verbose = prefsVerboseCheck;

if ~exist(corAnalFile,'file')
	msg = sprintf('corAnal file %s not found. \n', corAnalFile);
	
	if computeIfNeeded==1
		% compute it
		if verbose > 1,  
			fprintf('[%s]: %s\n', mfilename, msg);
			disp('Computing Coherence Analysis ...')
		end
		vw = computeCorAnal(vw, 0);
	else
		% % just warn the user
		% warning(msg);
	end
	
	return;
end

if verbose > 0
	fprintf('[%s]: Loading from %s ... ', mfilename, corAnalFile);
end

load(corAnalFile); % loads co, amp, ph

if verbose > 0
	fprintf('done.\n');
end

% check that the corAnal fields are the appropriate size
checkSize(vw, co);
checkSize(vw, amp);
checkSize(vw, ph);

% assign to view
vw.co = co;
vw.amp = amp;
vw.ph = ph;
if notDefined('map')~=1, vw.map=map; end
return;
