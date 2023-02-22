function [fiberMetrics, subjectCodes, year, group]=dtiGetFGProperties(summary, subjectInitials, ParameterOfInterest, labels, separator)
%Get Fiber Group properties from the properties summary structure
%
% [fiberMetrics, subjectCodes, year, group]=dtiGetFGProperties(summary, subjectInitials, [ParameterOfInterest='fiberGroupVolume'], labels)

% Pull out  values for a parameter of interest from summary structure. 
% Output variables:  
% fiberMetrics     - array of values, subjectYearXfiberGroup. 
%                   To reshape to subjecctXyearXfiberGroup use Reshape for
%                   plotting
%                   for yearI=1:4
%                    try 
%                    fiberMetricsR(yearI, :, :)=fiberMetrics(year==yearI, :, :) ;
%                    catch
%                    end
%                   end
% group           -  labels repeated measures from the same subject
% year            - used for our longitudinal reading project data, 
%                   returns years 1-4 for 2004-2007 
%                   (calendar year minus 3)
% Example:
%  labels=dtiGetMoriLabels
%  [subList,subCodes,subDirs,subjectInitials] = findSubjects; 
%  load('/biac3/wandell4/users/elenary/longitudinal/ANALYSES/Mori_Groups/summaryFiberPropertiesMoriGroups_volumeUniqueVoxels_Y1.mat');
%  [fiberMetrics, subjectCodes, year, group]=dtiGetFGProperties(summary, subjectInitials, 'FA', labels)
%
% See also: 
%  dtiFiberProperties, dti_Longitude_ComputeMoriFiberProperties
if ~exist('separator', 'var') || isempty(separator)
    separator='0'; %This is a first symbol that follows the unique ID (initials, alphabetical part) within the subjectCode. This hack was added to be able to accomodate data collected after 2010. 
end

filenames=strvcat(summary(:).subject);
filenames=cellstr(filenames);
subjectCodes=[];
datarow=0;

if ~exist('ParameterOfInterest', 'var') || isempty(ParameterOfInterest)
    %by default,
    ParameterOfInterest='fiberGroupVolume';
end


%Check whether we have a single property values, or min-average-max range.
%Use average in the latter case.  first element in the summary is "all
%fibers", not "first fiber group".
if size(summary(1).sfg(1).(ParameterOfInterest), 2)==3
    valInd=2;
elseif  size(summary(1).sfg(1).(ParameterOfInterest), 2)==1
    valInd=1;
else fprintf('Error'); return;
end


for subjectID=1:numel(subjectInitials)

    matchTemp= regexpi(filenames, [ '/' char(subjectInitials(subjectID)) separator]); %Find all structure elements with info on THIS subject, however many. 
    % The hack above will only work for our data (years before 2010), since
    % our way of discriminating between subjects "ab" and "abc" is the following zero, whcih correpond to year in our format "abyymmdd';  
   for subj_year=find(~cellfun(@isempty, matchTemp))'

        datarow=datarow+1;
        subjectCodes=[subjectCodes  cellstr(summary(subj_year).subject((matchTemp{subj_year}+1):(matchTemp{subj_year}+1)+size(char(subjectInitials(subjectID)), 2)+5))];
        year(datarow)=str2num(filenames{subj_year}(findstr(['/' subjectInitials{subjectID} separator], filenames{subj_year})+length(subjectInitials{subjectID})+2))-3;
  
        subjectlabels=strvcat(summary(subj_year).sfg(1:end).name);
        for label_fgID=1:numel(labels)
            found=0;
            for subj_fgID=1:numel(summary(subj_year).sfg)  %Find in this participant where a canonical FG is
                fg_has_data=findstr(char(labels(label_fgID)), subjectlabels(subj_fgID, :));
                if fg_has_data
                    found=1;
                    fiberMetrics(datarow, label_fgID)=summary(subj_year).sfg(subj_fgID).(ParameterOfInterest)(valInd);
                end
            end %end fiber groups that had at least one fiber in this participant
            if found==0
                fiberMetrics(datarow, label_fgID)=0;
            end
        end %end 20 canonical fiber grops of interest
    end %end years 1-4
end %end all subject with four measurements

%In case some of them had years listed in wrong order, fix that. 
[subjectCodes, IX]=sort(subjectCodes); 
fiberMetrics=fiberMetrics(IX, :); 
year=year(IX); 

a=cellfun(@(x) x(1:end-6), subjectCodes, 'UniformOutput', false);
[k, j, group]=unique(a);   %GROUP variable marks the same subject
 
