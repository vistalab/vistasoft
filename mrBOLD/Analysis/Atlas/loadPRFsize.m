function images = loadPRFsize(vw, images, curSlice)
%
% load 'ecc' into images.M1 and 'pRF size' into images.M3 field (ecc is
% reloaded since it was scaled to 0-2pi at the initial loading)
% 
% images = loadPRFsize(vw, images, curSlice)

global dataTYPES

if notDefined('vw'), vw=getCurView;  end
if notDefined('images'), error('images should be defined');  end
if notDefined('curSlice'), curSlice = viewGet(vw, 'Current Slice'); end

for i=1:size(dataTYPES,2)
    if strcmp(dataTYPES(i).name, 'Averages')
        vw.curDataType = i;
    end
end
vw = selectDataType(vw,vw.curDataType);
vw = loadCorAnal(vw);

% reload ecc (initially loaded ecc was scaled into the range
% between 0 and 2*pi for atlas fitting) 
images.M1=vw.map{1}(:,:,curSlice);
% load pRF size
images.M3=vw.amp{1}(:,:,curSlice);

