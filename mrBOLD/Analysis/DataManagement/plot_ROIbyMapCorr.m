function [ corrmat] = plot_ROIbyMapCorr( view, dt,scan, roiList, mapList,mapDir )
% [ corrmat] = plot_ROIbyMapCorr( view, dt,scan, roiList, mapList,mapDir )
%  For a given view 'i' or 'g', datatype and scan 
% loads a series or rois from an roiList
% and a series of correlation maps (corrList) and map directory (mapDir)
% and plots the mean correlation value in each roi
% 
% kgs 7.12
% 
if view=='i'
    vw=initHiddenInplane(dt,scan,roiList);
elseif view=='g'
    vw=initHiddenGray(dt,scan,roiList);
else
    disp('Error view does not exist')
    return
end

nmaps=length(mapList);
nrois=length(roiList);
corrmat=zeros(nmaps,nrois);
for m=1:nmaps
    mapPath=fullfile(mapDir,mapList{m});
    vw=loadParameterMap(vw, mapPath);
 
    for r=1:nrois

        vw=viewset(vw,'selectedROI',r);
        roiname=viewget(vw,'roiname');
        
        roicorrval = getCurDataROI(vw,'map');
        corrmat(m,r)=mean(roicorrval);
    end
    
end
figure('color',[ 1 1 1],'name',['Scan ' num2str(scan)])
imagesc(corrmat);
colormap('hot')
colorbar;
axis('square');
set(gca,'Xtick', [1:nrois]  ,'XtickLabel', roiList,'Fontsize',7);
set(gca,'Ytick', [1:nmaps]  ,'YtickLabel', mapList,'Fontsize',8);


end

