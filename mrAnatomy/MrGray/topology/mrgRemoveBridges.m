function class = mrgRemoveBridges(classFile,datFile,outFile)
% class = mrgRemoveBridges(classFile,datFile,outFile)
%
% Author: RFD, ISS, BW
% Purpose:
%   Eliminate  (or at least reduce) the bridges (handles) in a mrGray
%   *.Class file. 
%
%   After building a mrGray project, and creating a .Class file that has
%   nearly all the white matter selected, you should run this Matlab
%   program on the project class file.  This program will greatly reduce
%   the number handles automatically, fixing up the classification.
%
%   If you open up mrGray, you can load the class file created by this
%   program as the white matter classification file and check the results.
%
%   To avoid renaming files, it is possible to choose the input file and
%   the output file to be the same.  This is dangerous, of course, so we
%   make a back-up copy before over-writing.  You should delete the backup
%   once you are satisfied with the results.  Or move the back-up to the
%   original name and everything will be as before you ran this program.
%
%   The connectivity assumed in mrGray and in BrainVoyager differ, so
%   the reduction of handles by this program does not guarantee zero
%   handles in mrGray.  Usually, the reduction is helpful.
%
% Requires:  
% removeBridgesMex (in Matlab path)  (old form:  fixTopology).
%
% HISTORY:
%   110202 ISS wrote it.
%   2002.11.13 RFD (bob@white.stanford.edu) cleaned up and updated to use
%   the new bridgeRemovalMex file.
%   This Matlab code uses material originally written by N. Kriegeskorte.
%   ISS/RFD wrote the Matlab interface and figured out how to use it.  
%   BW converted to this file name, placed the program in the mrGray
%   folder, and edited some UI features. 
%   2005.06.23 SOD minor bug fix if you're not using UI

if ieNotDefined('classFile')
    [f,p]=uigetfile('*.class;*.Class', 'Select a class file...');
    if isequal(f,0) | isequal(p,0), return; end
    classFile = fullfile(p,f);
    disp(['Class file: ',classFile]);
else,
  [p,f]=fileparts(classFile);
end

% Change to the class file directory
curDir = pwd;
if ~isempty(p),chdir(p);end;

if ieNotDefined('datFile')
    [f,p]=uigetfile('*.dat;*.DAT', 'Select corresponding vAnatomy...');
    if isequal(f,0) | isequal(p,0), return; end
    datFile = fullfile(p,f);
    disp(['Anatomy file: ',datFile]);
end

% Try to create an output file with a .Class extension
if ieNotDefined('outFile')
    [f,p]=uiputfile('*.class;*.Class', 'Save corrected Class file as...');
    if isequal(f,0) | isequal(p,0), return; end
    [tmp,n,e] = fileparts(f);
    if ~strcmp(lower(e),'.class')
        Resp=questdlg('OK to change the extension to .Class?');
        switch Resp
            case 'Yes'
                e = '.Class';
            case 'No'    
            case 'Cancel' 
                return;
        end
    end
    outFile = fullfile(p,[n,e]);
    sprintf(['Output Class file: ',outFile]);
end
   
chdir(curDir);

%-----------------------Read in presegmented data----------------------------
preSegClass = readClassFile(classFile,0,0);
preWhite = preSegClass.data;
preWhite(preSegClass.data~=16)=0;
% The handle removal function sets all non-zero values to white matter, so
% we can leave the non-zero data alone. We just need to set all non-white matter
% to zero.

% Data anatomical data to match format of white matter
% Permuting to match preseg data
[anatData,mmPerVox,img_dim]=readVolAnat(datFile);
anatData=permute(anatData,[2 1 3]);
% scale = 225/256;
% anatData = uint8(double(anatData)*scale);
anatData = uint8(double(anatData));

params = preSegClass.header.params;

% This should be a function that takes in preWhite and params and
% returns the fixedSegWhite.
% corrected = mrgRemBridges(preWhite,anatData,scale,params);
corrected = mrgRemBridges(preWhite,anatData,params);

% -- Copy the corrected data into the preWhite data.
% For some reason, this works better than the previous, even though they
% *should* be equivalent. I suspect that the bridge removal code doesn't 
% properly mark all the removed voxels. However, we need to put the CSF
% back in.
preWhite = uint8(corrected==225 | corrected==245);
preWhite(preWhite>0) = preSegClass.type.white;
preWhite(preSegClass.data==preSegClass.type.csf) = preSegClass.type.csf;
preSegClass.data = preWhite;

if strcmp(outFile,classFile)
    backupFile = [classFile,'-Backup'];
    copyfile(classFile,backupFile); 
end

class = writeClassFile(preSegClass, outFile);

return;