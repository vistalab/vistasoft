function view=rmModelPositionCorrectionGUI(view);
% rmModelPositionCorrectionGUI - mrVista interface to
% rmModelPositionCorrection.
% 
% view=rmModelPositionCorrectionGUI(view);
%
% 2007/05 SOD: wrote it.

if notDefined('view'), error('Need view struct'); end;

% get rmFile
rmFile = viewGet(view,'rmFile');
if isempty(rmFile), error('No retModel file loaded.'); end;

% make new file name
[p n]=fileparts(rmFile);
newRmFile = fullfile(p,[n '-posCorr.mat']);

% get position correction (pop up gui)
prompt ={'Enter position correction in degrees (x, y, polar-angle, eccentricity): '};
name   ='Position correction in degrees of visual angle';
numlines = 1;
defaultanswer = {'0 0 0 0'};
answer = inputdlg(prompt,name,numlines,defaultanswer);
if isempty(answer), disp(sprintf('[%s]:User cancelled.',mfilename)); end;
poscorr   = str2num(answer{1});
drawnow;

% do position correction
rmModelPositionCorrection(poscorr,rmFile,newRmFile);

% load new file
loadModel = true;
view = rmSelect(view, loadModel, newRmFile);

% warn
fprintf(1,'[%s]:Position corrected: Please note that some parameters may have to be reloaded.\n',mfilename);

% done
return;
