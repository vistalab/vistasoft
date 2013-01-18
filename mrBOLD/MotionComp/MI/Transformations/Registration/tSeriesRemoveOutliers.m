function [tSeries] = tSeriesRemoveOutliers(tSeries, baseImage)
% 
%

if ~exist('baseImage')
    baseImage = tSeries(1,:,:);
end

nFrames = size(tSeries,1);
nVoxels = size(tSeries,2);
nSlices = size(tSeries,3);

indexes = [];
backup = tSeries;

for curSlice = 1:nSlices
	
	LSE_ref = tSeries(:,:,curSlice) - repmat(baseImage(:,:,curSlice),[nFrames 1]);
	MSE_ref = sqrt(sum(LSE_ref.^2,2)/(nVoxels));
	
	mn = mean(MSE_ref);
	sd = std(MSE_ref);
	
	frame = 1;
	
	while (frame <= nFrames)
        
        frameOutlier = frame;
        while (frameOutlier <= nFrames) & ((MSE_ref(frameOutlier) - mn) > 2*sd)
            frameOutlier = frameOutlier + 1;
        end
	
        if frameOutlier ~= frame
            prev = frame - 1;
            next = frameOutlier;
            
            if frame == 1
                for i = frame:(frameOutlier - 1)
                    tSeries(i,:) = tSeries(next,:);
                end
                
            elseif frameOutlier > nFrames
                for i = frame:(frameOutlier - 1)
                    tSeries(i,:) = tSeries(prev,:);
                end
                
            else
                for i = frame:(frameOutlier - 1)
                    tSeries(i,:) = (tSeries(next,:) - tSeries(prev,:))/(next - prev)*(i - prev) + tSeries(prev,:);
                end
                
            end
            
            if frameOutlier - frame > length(indexes)
                indexes = [indexes zeros(1,frameOutlier - frame + length(indexes))];
            end
            indexes(frameOutlier - frame) = indexes(frameOutlier - frame) + 1;
            
        end
        
        frame = max(frame + 1,frameOutlier);
	end
end

if sum(indexes) ~= 0

    qstring = 'Here are the number of spike artefacts detected:\n';
	for index = 1:length(indexes)
        if indexes(index) ~= 0
            if indexes(index) == 1
                occurence = 'occurence';
            else
                occurence = 'occurences';
            end
            
            qstring = [qstring sprintf('\n     - %d consecutive artefacts: %d %s ',index,indexes(index)),occurence];
        end    
	end
	
	qstring = [qstring sprintf('\n\nWould you like to remove them?')];
	
	button = questdlg(sprintf(qstring),'Remove Outliers','Yes','No','default');
    
else
    button = 'No';
end

if strcmp(button,'Yes')
   return
else
   tSeries = backup;
   return
end