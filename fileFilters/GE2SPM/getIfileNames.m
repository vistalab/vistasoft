function allIfileNames = getIfileNames(anIfile,imList,numDigits);
% function allIfileNames = getIfileNames([anIfile],[imList],[numDigits]);
% 
% Searches and returns all appropriate Ifiles akin to the specified anIfile.
% 
% anIfile shall be in following structure:
% anIfile = filePath/fileTag.freeItem
% If fileTag (the part after last filesep but before the first '.') exists,
% read all fileTag.* files (default fileTag = I), unless:
%   if freeItem contains a numeric string (e.g. fileTag.whatever001whoever), then read
%   files that only change that numeric part (e.g. fileTag.whatever***whoever)
% 
% e.g. anIfile = X:/folder/, finds all I.* files in this folder
%  anFile = X:/folder/I, also finds all I.* files in this folder
%  anFile = X:/folder/OTHER, finds all OTHER.* files in this folder
%  anFile = X:/Ifiles/I.004, finds all I.*** files in this folder.
%      if files not found, will search for I.***.dcm instead.
%  anFile = X:/Ifiles/testI.001.dcm, finds all testI.***.dcm files in this folder.
% 
% The following two inputs are almost useless (for makeCubeIfiles.m)
% imList: limit files to only those containing numeric strings described in imList (e.g. 2:10)
% numDigits: limit files to only those containing numeric strings of length numDigits
% 
% Junjie Liu 2003.01.24
% 2004.06.03 RFD: we now allow for I_001.dcm and I001.dcm formats.


if ~exist('anIfile','var') | isempty(anIfile)
   [f, p] = uigetfile({'*.dcm','DICOM files (*.dcm)';'*.001','GE I-files (*.001)';'*.*','All files'}, 'Select one of the I-files...');
   anIfile = fullfile(p, f);
end

if ~exist('numDigits','var');
    numDigits = 0;
end

if ~exist('imList','var');
    imList = [];
else
    numDigits = length(num2str(max(imList)));
    %add 0 paddings to imList
    imList = int2str(10^(numDigits+1)+imList);
    imList = imList(:,2:end);
end

if isdir(anIfile) & ~strcmp(anIfile(end),filesep); % avoid choosing dir
    anIfile = [anIfile,filesep];
end;

[pathstr filetag freeitem] = fileparts(anIfile);

if isempty(filetag);
    filetag = 'I';
else
    % see if there are more than one extensions in anIfile (e.g. I.001.dcm)
    % We also check for file names like I_001.dcm
    ind = find(filetag == '.' | filetag == '_');
    if ~isempty(ind);
        filetag = filetag(1:min(ind)-1);
    end
    % Crude check for filenames like I0001.dcm
    if(length(filetag)>4 & all(filetag(end-3:end)=='0001'))
        filetag = filetag(1:end-4);
    elseif(length(filetag)>3 & all(filetag(end-2:end)=='001'))
        filetag = filetag(1:end-3);
    end
end

tmp = dir(fullfile(pathstr,[filetag,'.*']));
if(isempty(tmp))
    tmp = dir(fullfile(pathstr,[filetag,'_*']));
end
if(isempty(tmp))
    tmp = dir(fullfile(pathstr,[filetag,'*']));
end
allIfileNames = {};
for(ii=1:length(tmp))
    if(~tmp(ii).isdir)
        allIfileNames{end+1} = tmp(ii).name;
    end
end
nGoodFiles = 0;
if ~isempty(allIfileNames);
    for ii = 1:length(allIfileNames);
        allIfileNames{ii} = fullfile(pathstr,allIfileNames{ii});
    end
end

return;
