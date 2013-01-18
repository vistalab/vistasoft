function [sagSlice,sagPts,obSlice,obPts] =  mrRotSagVol(volume,obXM,obYM,obSize,sagSize,cTheta,aTheta,curSag,reflections,show,thick,curInplane)
% Author: Sunil Gandhi
% Date:   11.12.96
% Function:
%   Rotates sagittal volume coordinates by a call to C function SagittalRot. 
% then interpolates the coordinates and displays the new image, and the
% updated cTheta, aTheta, and curSag. If an oblique slice has already been 
% cut, then the oblique image will also be updated with C fcn ObliqueRot 
% such that it remains orthogonal to the rotated sagittal plane and intersects
% at the selected inplane line. Also preserves reflection settings. Updates
% image if show != 0.
% 

 global sagX sagY volslimin1 volslimax1 volslimin2 volslimax2 numSlices sagwin obwin;
 
 numextracts = 10;

%
% These might not be set if user isn't showing image.
% Matlab 5.0 generates a WARNING in these conditions since
% it wants return arguments always set.
sagPts = [];
sagSlice = [];
obSlice = [];
obPts = [];

%%%%%%%%%%%%%%%% Sagittal Rotation %%%%%%%%%%%%%
if (show ~= 0) 
 figure(sagwin);

 tempPts = SagittalRot(sagSize,aTheta,cTheta,curSag);
 % size(tempPts)
 
 sagPts = reshape(tempPts, length(tempPts)/3, 3);% reshapes vector into a 
                                                 % matrix of volume coordinates
 sagSlice = myCinterp3(volume,sagSize,numSlices,sagPts,1);

 % size(sagSlice)
 % size(sagPts)
 
 myShowImageVol(sagSlice',sagSize,max(sagSlice)*get(volslimin1,'value'),max(sagSlice)*get(volslimax1,'value'),sagX,sagY);
 
end

%%%%%%%%%%%%%%% Displaying updated variables %%%%%%%%%%%

 xlim=get(gca,'XLim');
 ylim=get(gca,'YLim');
 xt = xlim(1);
 yt = diff(ylim) + 10;
 txt = (['sagittal slice:',num2str(curSag),'    coronal,axial theta: (',num2str(cTheta),', ',num2str(aTheta),')']);
 msg(1)= text(xt,yt(1),txt);

 %%%%%%%%%%%%%%%%% Oblique Rotation %%%%%%%%%%%%%%
 
 
 % test to determine if oblique has been selected yet
 if (curInplane ~= 0) 
     obX = obXM(curInplane,:); obY = obYM(curInplane,:);
     d = sqrt((obY(2)-obY(1)).^2 + (obX(2)-obX(1)).^2); 
     unitv = [(obX(2)-obX(1))/d, (obY(2)-obY(1))/d];
     perp = [-unitv(2), unitv(1)];
     
     newX = obX-perp(1)*(thick/2);
     newY = obY-perp(2)*(thick/2); 
     
     for i = 1:numextracts
         newX = newX+perp(1)*(thick/numextracts);
         newY = newY+perp(2)*(thick/numextracts);
         
         tempPts = ObliqueRot([newX(1) newY(1)],[newX(2) newY(2)],aTheta,cTheta,numSlices,sagSize,curSag);
         
         tempPts = reshape(tempPts, length(tempPts)/3, 3);
         if (i == round(numextracts/2)) 
             obPts = tempPts;
         end
         obSlices(i,:) = myCinterp3(volume,sagSize,numSlices,tempPts,1);
     end
     
     obSlice = mean(obSlices)';
     
     if reflections(1)<0 
         [obSlice,reflections] = mrReflectObl(obSlice,obSize,reflections,1,0);
     end  
     
     if reflections(2)<0 
         [obSlice,reflections] = mrReflectObl(obSlice,obSize,reflections,2,0);
     end
     
     if (show ~= 0) 
         figure(obwin);
         myShowImageVol(obSlice',obSize,max(obSlice)*get(volslimin2,'value'),max(obSlice)*get(volslimax2,'value'),sagX,sagY);
     end
 end


return









