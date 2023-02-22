function motionCompMeanMovie(view,slice)
%
%    gb 04/30/05
%
%    motionCompMeanMovie(view,slice)
%
% Creates a movie of the mean maps of all scans for the choosen slice.
% Slice 18 is the default

if ieNotDefined('slice')
    slice = 18;
end

cd(dataDir(view));
curDataType = viewGet(view,'currentDataType');

if ~exist(['movie_' num2str(slice) '.avi'])
    meanImages = load('meanMap.mat');
    meanImages = meanImages.map;
    
    nScans = length(meanImages);
    mov = repmat(struct('cdata',[],'colormap',[]),1,nScans);
    for scan = 1:nScans
        frame = meanImages{scan};
        if isempty(frame)
            frame = zeros(sliceDims(view,scan));
        else
            frame = frame(:,:,slice);
            frame = uint8(round((frame - min(frame(:)))/max(frame(:))*255));
        end
        mov(scan).cdata = repmat(frame,[1 1 3]);
        
    end
    
    movie2avi(mov,['movie_' num2str(slice)]);
end

global HOMEDIR
cd(HOMEDIR)