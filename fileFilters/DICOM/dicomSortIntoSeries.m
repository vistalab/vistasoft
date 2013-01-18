function dicomSortIntoSeries(dicomDir)

% function dicomSortIntoSeries(dicomDir)
%
% dicomDir=full path to dicom dir
% 
% This script sorts DICOM files into different directories
% depending on the Series Description or Series Number provided by the
% header in the DICOMs.
%
%
% HISTORY:
% 2008.09.23  AMR & LMP wrote it
%
%
if notDefined('dicomDir')
singleDicom = mrvSelectFile('r',[],'Please point to a single dicom file in your directory of choice',pwd);
    if isempty(singleDicom)
        return
    else
        dicomDir = fileparts(singleDicom);
    end
end
cd(dicomDir)
dirInfo = dir(dicomDir);
numFilesinDir = numel(dirInfo);

% % To sort my series number
% for imageNum = 1:numFilesinDir
%     try
%         info = dicominfo(dirInfo(imageNum).name);
%         curDicomDir = ['SeriesNum' num2str(info.SeriesNumber)];
%         if ~exist(curDicomDir,'dir')
%             mkdir(curDicomDir);
%         end
%         movefile(dirInfo(imageNum).name,curDicomDir);
%         fprintf('%s%s\n','Processing file ',dirInfo(imageNum).name);
%     catch
%         fprintf('%s%s\n','Skipping file ',dirInfo(imageNum).name);
%     end
% end


%% To sort by series description instead of series number

for imageNum = 1:numFilesinDir
    try
        info = dicominfo(dirInfo(imageNum).name);
        curDicomDir = info.SeriesDescription;
        if ~exist(curDicomDir,'dir')
            mkdir(curDicomDir);
        end
        movefile(dirInfo(imageNum).name,curDicomDir);
        fprintf('%s%s\n','Processing file ',dirInfo(imageNum).name);
    catch
        fprintf('%s%s\n','Skipping file ',dirInfo(imageNum).name);
    end
end



%%% This only works for some directories (renaming to something sensible)
% cd ..
% directories = dir('DICOM2');
% cd('DICOM2');
% for ii = 3:length(directories)
%     files = dir(directories(ii).name);
%     cd(directories(ii).name);
%     info = dicominfo(files(3).name);
%     cd ..
%     movefile(directories(ii).name,info.SeriesDescription);
% end
