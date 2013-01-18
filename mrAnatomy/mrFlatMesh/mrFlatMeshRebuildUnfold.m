function mrFlatMeshRebuildUnfold(inFlatMatFile, outFlatMatFile)
%
% mrFlatMeshRebuildUnfold([inFlatMatFile], [outFlatMatFile])
%
% Rebuilds a mrFlatMesh unfold. This is only really useful if you want to 
% get a new unfold file with the additional data structures that mrFlatMesh
% now saves. (eg. to run the new mesh-based surface area measurements)
%
% HISTORY
% 2003.02.?? RFD (bob@white.stanford.edu) wrote it.

if(~exist('inFlatMatFile','var'))
    [f,p] = uigetfile({'*.mat','MAT-files (*.mat)'; '*.*',  'All Files (*.*)'}, ...
                        'Select a flat.mat file to redo', 'flat.mat');
    inFlatMatFile = fullfile(p,f);
end
u = load(inFlatMatFile);
disp(['Unfold loaded from ',inFlatMatFile,'.']);

if(~exist('outFlatMatFile','var'))
    [f,p] = myUiPutFile(inFlatMatFile, {'*.mat','MAT-files (*.mat)'}, ...
                        'Save the reprocessed file as', 'flat.mat');
    outFlatMatFile = fullfile(p,f);
end
if(exist(outFlatMatFile,'file'))
    disp([outFlatMatFile,' exists- making a backup copy.']);
    [p,f,e] = fileparts(outFlatMatFile);
    [s,msg] = copyfile(outFlatMatFile, fullfile(p,[f,'_ORIGINAL',e]));
    if(~s)
        disp(['copyfile failed:', msg]);
    end
end

mrFlatMesh({'grayPath',u.infoStr.grayFile, 'meshPath', u.infoStr.meshFile, 'savePath', outFlatMatFile, ...
        'startXYZ', u.infoStr.startCoords, 'unfoldRadiusMM',u.infoStr.perimDist});

