function  summaryWithFgVolume = dtiExtrapolateFgVolumeFromCrossectionArea(summaryWithCrossectionArea, summaryWithFiberGroupLength)
%Compute crosssection area for fiber groups/subjects
%
% summary = dti_Longitude_ComputeCrossectionalArea(summaryWithCrosSectionalArea, ...
%                                                      [summaryWithFiberGroupLength])
%
% Use case 1 
% Input: a summary structure of fg properties returned by
% dtiFiberProperties 
% Output:  same summary structure with field
% diberGroupVolume added or updated.
%
% Use case 2
% If two summary structures are provided as arguments, then
% the fgVolume will be extracted from the first one, and fiberLength will
% be extracted from the second one. The resulting summary will contain ONLY
% cross-sectional area estimates, and only for subjects present in both
% input summary structures. Note:it is OK if subjects order is not
% equivalent in both input summary structures. It is NOT ok if the fiber
% groups are not -- u should check that! 
%
% Example: 
%   load('summaryFiberPropertiesMoriGroups_Roi2RoiVolumeUniqueVoxels.mat');
%   summaryWithCrossectionArea = dtiComputeCrossectionArea(summary);
%
% See a more elaborate example after "return" statement below. 
%
% See also: dtiFiberProperties, dtiComputeCrossectionalArea
%
% (c) Vistasoft

% History: ER wrote it 03/24/2010

fprintf(1, 'Computing volume of a fiber group from its crossectional area and length \n');

if nargin == 1
    summaryWithFgVolume = summaryWithCrossectionArea;
    summaryWithFiberGroupLength = summaryWithCrossectionArea;
elseif nargin == 2
    summaryWithFgVolume =[];
else
    eror ('Incorrect number of arguments');
end

for s=1:length(summaryWithCrossectionArea)

    s2 = find(arrayfun(@(x) strcmp(x.subject,summaryWithCrossectionArea(s).subject), summaryWithFiberGroupLength));

    for fg=1:numel(summaryWithCrossectionArea(s).sfg);
    
        summaryWithFgVolume(s).sfg(fg).fiberGroupVolume = summaryWithCrossectionArea(s).sfg(fg).crossectionArea*summaryWithFiberGroupLength(s2).sfg(fg).fiberLength(2);
        summaryWithFgVolume(s).sfg(fg).name = summaryWithCrossectionArea(s).sfg(fg).name;
        summaryWithFgVolume(s).subject = summaryWithCrossectionArea(s).subject;
    end
end

return

%% An 'elaborate' example
cd /biac3/wandell4/users/elenary/longitudinal/ANALYSES/Mori_Groups/
 
%load 'summary' structure with Roi2Roi cropped fiber groups' properties
load('summaryFiberPropertiesMoriGroups_Roi2RoiVolumeUniqueVoxels.mat');
%Compute crossectional areas
summaryWithCrossectionArea = dtiComputeCrossectionArea(summary);

%load 'summary' with original (full length) FG properties, incl. length
load('summaryFiberPropertiesMoriGroups_volumeUniqueVoxels.mat'); 
summaryWithFiberGroupLength = summary; 
%Compute extrapolated volume from realLength and approximated Xarea
summaryFgVolumeExtra = dtiExtrapolateFgVolumeFromCrossectionArea(summaryWithCrossectionArea, summaryWithFiberGroupLength);
  
%Now your summary(1).sfg(1).fiberGroupVolume contains actual volume of fg1 for s1,
%and summaryVolumeExtra(1).sfg(1).fiberGroupVolume contains the volume
%of fg1 for s1 estimated as crossectional area of the middle (Roi to
%Roi, more compact) portion of the fg, extrapolated to the its full
%length. 

%Now plot some stuff
labels = dtiGetMoriLabels;
labels_short=dtiGetMoriLabels(true); 
load('../../data/subjectCodesAll4Years'); %This will load subjectCodes
subjectInitials={'ab', 'ajs', 'am', 'an', 'at', 'clr', 'crb', 'ctb', 'da', 'dh', 'dm', 'es', 'jh', 'lj', 'll', 'mb', 'md', 'mho', 'mn', 'pf', 'pt', 'rd', 'rsh', 'ss', 'tm', 'vr', 'vt', 'zs'};
[fiberMetrics_realVol, subjectCodes, year, group] = dtiGetFGProperties(summaryWithFiberGroupLength, subjectInitials, 'fiberGroupVolume', labels, '0');
[fiberMetrics_realLength, subjectCodes, year, group] = dtiGetFGProperties(summaryWithFiberGroupLength, subjectInitials, 'fiberLength', labels, '0');
[fiberMetrics_XArea, subjectCodes, year, group] = dtiGetFGProperties(summaryWithCrossectionArea, subjectInitials, 'crossectionArea', labels, '0');
[fiberMetrics_extrapVol, subjectCodes, year, group] = dtiGetFGProperties(summaryFgVolumeExtra, subjectInitials, 'fiberGroupVolume', labels, '0');
[fiberMetrics_FA, subjectCodes, year, group] = dtiGetFGProperties(summaryWithFiberGroupLength, subjectInitials, 'FA', labels, '0');

%Need to know numFibers in order to collapse data across somefiber groups.
[numFibers_fullFGs, subjectCodes, year, group] = dtiGetFGProperties(summaryWithFiberGroupLength, subjectInitials, 'numberOfFibers', labels, '0');

%Reduced 20 fiber groups to 9
%collapsingVector2 = [1 2 3 4 5 6 5 6 7 8 9 10 11 12 13 14 15 16 13 14]; %will combine cingulum cingulate and hc, and will combine slf_t and slf_fp. 
collapsingVector2 = [1 1 2 2 3 3 3 3 4 5 6 6 7 7 8 8 9 9 8 8]; %will collapse symmetric fiber groups into one, will combine cingulum cingulate and hc, and will combine slf_t and slf_fp. 

[fiberMetrics_realVol, labels_New] = dti_LongitudeAggregateFiberPropertiesAcrossGroups(fiberMetrics_realVol, labels_short, collapsingVector2, 'sum');
[fiberMetrics_extrapVol, labels_New] = dti_LongitudeAggregateFiberPropertiesAcrossGroups(fiberMetrics_extrapVol, labels_short, collapsingVector2, 'sum');
[fiberMetrics_realLength, labels_New] = dti_LongitudeAggregateFiberPropertiesAcrossGroups(fiberMetrics_realLength, labels_short, collapsingVector2, 'mean', numFibers_fullFGs);
[fiberMetrics_XArea, labels_New] = dti_LongitudeAggregateFiberPropertiesAcrossGroups(fiberMetrics_XArea, labels_short, collapsingVector2, 'sum');
[fiberMetrics_FA, labels_New] = dti_LongitudeAggregateFiberPropertiesAcrossGroups(fiberMetrics_FA, labels_short, collapsingVector2, 'mean', numFibers_fullFGs);


% Length -> Volume & Extrapolated volume
figure; plot(fiberMetrics_realLength(:), fiberMetrics_extrapVol(:), 'ro'); xlabel('real length'); hold on;
plot(fiberMetrics_realLength(:), fiberMetrics_realVol(:), 'bx');  legend('Extrapolated volume, mm^3', 'Real volume, mm^3');

%figure; plot(log(realVol), log(extrapolatedVol), 'ro'); xlabel('Log (real volume)'); ylabel('Log (extrapolated volume)');
f1=figure;
screen_size = get(0, 'ScreenSize'); set(f1, 'Position', [0 0 screen_size(3) screen_size(4) ] );
colordef black

markers=getUniqueMarkers(20);
for fg=1:length(labels_New)
    ax1 = subplot(2, 3, 1); hold on;
    plot(fiberMetrics_realLength(:, fg), fiberMetrics_XArea(:, fg), markers{fg}); ylabel('Crossectional area ROi2Roi, mm^2'); xlabel('real length');
    ax2 = subplot(2, 3, 2); hold on;
    plot(fiberMetrics_realVol(:, fg), fiberMetrics_extrapVol(:, fg), markers{fg}); ylabel('extrapolated volume, mm^3'); xlabel('real volume, mm^3');
    ax3 = subplot(2,3, 3); hold on;
    plot(fiberMetrics_XArea(:, fg), fiberMetrics_realVol(:, fg), markers{fg}); ylabel('Real volume'); xlabel('crossection area Roi2Roi'); h=legend(labels_New);
    ax4 = subplot(2, 3, 4); hold on;
    plot(fiberMetrics_FA(:, fg), fiberMetrics_realLength(:, fg), markers{fg}); ylabel('realLength'); 
    ax5 = subplot(2, 3, 5); hold on; 
    plot(fiberMetrics_FA(:, fg), fiberMetrics_realVol(:, fg),  markers{fg}); ylabel('realVolume'); xlabel('FA');
    ax6 = subplot(2, 3, 6); hold on; plot(fiberMetrics_FA(:, fg), fiberMetrics_XArea(:, fg), markers{fg}); ylabel('Crossection Area'); xlabel('FA');
end
pL=get(h, 'Position'); 
p1 = get(ax1, 'Position');
set(h, 'Position', [p1(1) p1(4) pL(3) pL(4)]); 
%colordef white
