function  summaryOut = dtiComputeCrossectionArea(summary, summaryWithFiberGroupLength)
%Compute crosssection area for fiber groups/subjects
%
% summary = dti_Longitude_ComputeCrossectionalArea(summaryWithFiberGroupVolume, [summaryWithFiberGroupLength])
%
% Use case 1
% Input: a summary structure of fg properties returned by
% dtiFiberProperties 
% Output:  same summary structure with an additional
% field "crossectionalArea".
%
% Use case two: if two summary structures are provided as
% arguments, then the fiberGroupVolume will be extracted from the first one, and
% fiberLength will be extracted from the second one. The resulting summary
% will contain ONLY cross-section area estimates, and only for subjects
% present in both input summary structures. 
% Note:it is OK if subjects order is not equivalent in both input summary
% structures. It is NOT ok if the fiber groups are not. TODO: add checks. 
%
% Example:
%   load('summaryFiberPropertiesAllConnectingGmMoriGroups_volumeUniqueVoxels.mat');
%   summaryWithCrossectionArea = dtiComputeCrossectionArea(summary);
%   summaryWithFiberGroupLength = summary; 
%   summaryWithFgVolume = dtiExtrapolateFgVolumeFromCrossectionArea(summaryWithCrossectionArea, summaryWithFiberGroupLength);
%
% See also: dtiFiberProperties, dtiExtrapolateFgVolumeFromCrossectionArea
%
% (c) Vistasoft

% History: ER wrote it 03/24/2010

fprintf(1, 'Computing cross-sectional area of a fiber group from its volume and length\n'); 

if nargin == 1
    
    summaryOut = summary; 
    summaryWithFiberGroupLength = summary;
    elseif nargin == 2
        summaryOut=[]; 
else
        eror ('Incorrect number of arguments'); 
end

for s=1:length(summary)
    
    s2 = find(arrayfun(@(x) strcmp(x.subject,summary(s).subject), summaryWithFiberGroupLength));

    for fg=1:numel(summary(s).sfg);
           
        summaryOut(s).sfg(fg).crossectionArea = summary(s).sfg(fg).fiberGroupVolume/summaryWithFiberGroupLength(s2).sfg(fg).fiberLength(2);
        summaryOut(s).subject = summary(s).subject;
    end
end

