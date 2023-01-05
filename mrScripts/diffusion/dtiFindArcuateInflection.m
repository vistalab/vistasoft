%finding arcuate max curvature points
%ER wrote it 12/15

seedcoords=[-35, -45, 25]; %Look at most curvature in the vicinity of this coordinate
critDist=20; %Vicinity definition in mm

cd \\White\biac3-wandell4\data\reading_longitude\dti_y1\zs040630\dti06;
dtFile='dt6.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
dt=dtiLoadDt6(dtFile); 
cd ..\fibers\IPSproject\arcuate
arcuatepdbfile='L_Arcuate_clean.pdb';

lArcuate=mtrImportFibers(arcuatepdbfile, dt.xformToAcpc); 

leftArcuate=lArcuate.fibers;

%leftArcuate=fg.fibers(fg.subgroup==19);  //Used with MoriGroups
h=figure;
for fgID=1:length(leftArcuate)
fiber_curvature_vals=zeros([length(leftArcuate{fgID}) 1]); 
[indices, bestSqDist] = nearpoints(leftArcuate{fgID}, seedcoords');  
[x, closest(fgID)]=min(bestSqDist); 
 fiber_curvature_vals(bestSqDist<(critDist^2))=dtiFiberCurvature(leftArcuate{fgID}(:, bestSqDist<(critDist^2)));
 [a(fgID), b(fgID)]=max( fiber_curvature_vals);
 subplot(1, 2, 1); 
 if a~=0
 plot3(leftArcuate{fgID}(1, b(fgID)),leftArcuate{fgID}(2, b(fgID)), leftArcuate{fgID}(3, b(fgID)), 'rX');
 plot3(leftArcuate{fgID}(1, closest(fgID)),leftArcuate{fgID}(2, closest(fgID)), leftArcuate{fgID}(3, closest(fgID)), 'gX');
 end
 hold on;
subplot(1, 2, 2); 
inflectioncoord(fgID, :)=leftArcuate{fgID}(:, b(fgID)); 
tubeplot(leftArcuate{fgID}(1, :), leftArcuate{fgID}(2, :) , leftArcuate{fgID}(3, :), 1, fiber_curvature_vals);
hold on;
end
camera_position=campos; 
v=axis;
subplot(1, 2, 1); 
tubeplot(leftArcuate{fgID}(1, :), leftArcuate{fgID}(2, :) , leftArcuate{fgID}(3, :), 1, fiber_curvature_vals);
title('A sample fiber randomly chosen'); 
averagecoord=mean(inflectioncoord); 
plot3(averagecoord(1), averagecoord(2), averagecoord(3), 'b*'); 
campos([camera_position]);
axis(v); 
