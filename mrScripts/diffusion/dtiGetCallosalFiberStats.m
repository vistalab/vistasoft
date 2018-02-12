% 
% This script will take a given set of fiber groups loaded in dtiFiberUI,
% which cross the callosum, and find 11 points along each fiber that are
% cented around the midsagital point of each path (5 steps to each side 
% of the center point).
% 
% For each of the fiber groups loaded it will then return the means for FA, MD, 
% RD, AD, and selected background image value, in a Nx5 array stored in the 
% variable mnVal. Currently this script is set up for use with fmap background
% images.
%
% The standard deviation will also be computed for each of the 5 vals and
% stored in a Nx5 array in the variable sdVal.
% 
% The names and sequence of fiber grous can be found in fg.name 
% 
% 
% HISTORY:
% 2008.08.08 RFD Wrote it.

%dataDir = '/biac3/wandell4/data/reading_longitude/dti_adults/ah080521_sense/dtiss06';
dataDir = '/biac3/wandell4/data/reading_longitude/dti_adults/rfd050504_SENSE/dti23';
roiDir = fullfile(fileparts(dataDir),'ROIs');

handles = guidata(gcf);
nSteps = 5;

fg = handles.fiberGroups;
nFg = numel(fg);

% Create a legend for the fiber groups
for(ii=1:nFg)
    fgCol(ii,:) = fg(ii).colorRgb;
    fgStr{ii} = fg(ii).name;
end
legImg = ones(18*nFg-1,16,3);
for(ii=1:nFg)
    for(jj=1:3)
    	yPos = (ii-1)*18+1;
    	legImg(yPos:yPos+16,:,jj) = fgCol(ii,jj)./255;
    end
end
figure(88); image(legImg); axis equal off tight;
set(gca,'units','pixels','position',[8 10 size(legImg,2) size(legImg,1)]);
for(ii=1:nFg)
  text(18,(ii-1)*18+9, strrep(fgStr{ii},'_',' '),'FontSize',10);
end

% Get the callosal ROI
ccRoi = dtiReadRoi(fullfile(roiDir,'CC'));
minDist = 0.87;

h = mrvWaitbar(0,'Processing fibers...');
msCoords = [];
for(ii=1:nFg)
    fiberCoords{ii} = [];
    for(jj=1:numel(fg(ii).fibers))
        fc = fg(ii).fibers{jj};
        % first find those points that are within the CC ROI
        [indices, bestSqDist] = nearpoints(fc, ccRoi.coords');
        keepAll = bestSqDist<=minDist^2;
        if(any(keepAll))
            midSagPos = min(abs(fc(1,keepAll)));
            midSagInd = find(abs(fc(1,:))==midSagPos & keepAll);
            if(numel(midSagInd)~=1)
                disp('ignoring fiber');
            else
                msCoords = horzcat(msCoords, fc(:,midSagInd));
                midSagInds = [midSagInd-nSteps:midSagInd+nSteps];
                if(midSagInds(1)>1 && midSagInds(end)<size(fc,2))
                    fiberCoords{ii} = horzcat(fiberCoords{ii}, fc(:,midSagInds));
                end
            end
        end
    end
    mrvWaitbar(ii/nFg,h);
end
close(h);
figure; subplot(2,1,1);
c = horzcat(fiberCoords{:});
plot(c(2,:),c(3,:),'b.');
axis equal;
subplot(2,1,2);
plot(msCoords(2,:),msCoords(3,:),'r.'); hold on;
plot(ccRoi.coords(:,2),ccRoi.coords(:,3),'ko');
hold off; axis equal tight;

% Extract the values and summarize the callosal segments
bg = handles.bg(dtiGet(handles,'curbgnum'));
bg.img = bg.img.*(bg.maxVal-bg.minVal)+bg.minVal;
for(ii=1:nFg)
    [ev1,ev2,ev3] = dtiGetValFromTensors(handles.dt6, fiberCoords{ii}, ...
        inv(handles.xformToAcpc), 'eigvals', 'nearest');
    [fa,md,rd,ad] = dtiComputeFA(horzcat(ev1,ev2,ev3));
    gv = fa<1;
    bgCoords = round(mrAnatXformCoords(inv(bg.mat),fiberCoords{ii}));
    bgInds = sub2ind(size(bg.img),bgCoords(:,1),bgCoords(:,2),bgCoords(:,3));
    bgVals = bg.img(bgInds);
    % get rid of bad values (values that are exactly zero)
    bgVals = bgVals(bgVals>0 & gv);
    mnVal(ii,:) = [mean(fa(gv)),mean(md(gv)),mean(rd(gv)),mean(ad(gv)),mean(bgVals)];
    sdVal(ii,:) = [std(fa(gv)),std(md(gv)),std(rd(gv)),std(ad(gv)),std(bgVals)];
end


error('stop here');

handles = guidata(gcf);
ccfg = handles.fiberGroups(end);
% concatenate all fibers into one big list of points
ccCoords = horzcat(ccfg.fibers{:});
[ev1,ev2,ev3] = dtiGetValFromTensors(handles.dt6, ccCoords, inv(handles.xformToAcpc), 'eigvals', 'nearest');
[fa,md,rd,ad] = dtiComputeFA(horzcat(ev1,ev2,ev3));
bgCoords = round(mrAnatXformCoords(inv(bg.mat),ccCoords));
bgInds = sub2ind(size(bg.img),bgCoords(:,1),bgCoords(:,2),bgCoords(:,3));
bgVals = bg.img(bgInds);
% get rid of bad values (values that are exactly zero)
gv = fa<1 & md>0.5 & md<1.2 & bgVals>0 & bgVals<0.27;
figure;plot(md(gv),bgVals(gv),'.')

