function t=talACPCPointsToInplane
% t=talACPCPointsToInplane
% 
% Computes the coordinates of the talairach anchor points (ac,pc, sac
% etc..) in the coordinate frame of the inplanes. This is useful when
% converting all the data to analyze format for going into SPM
% Assumes that the talairach points exist in the usual anatomy directory and that mrSESSION.alignment exists.
% arw 110105 : Wrote it.
% 

% Get voxel sizes to make sure that the transformation preserves volume
mrGlobals;

ipVoxSize = mrSESSION.inplanes.voxelSize;
volVoxSize = readVolAnatHeader(vANATOMYPATH);

% Transform ROI coordinates
xform = inv(mrSESSION.alignment);
talPoints = loadTalairachXform(mrSESSION.subject);
talPoints.refPoints

rp=talPoints.refPoints;




acpc=[talPoints.refPoints.acXYZ;talPoints.refPoints.pcXYZ];
disp(acpc)
acpc2=acpc(:,[2 1 3]);

[d,t]= xformROIcoords(acpc2',xform,volVoxSize,ipVoxSize)


disp('Note: Y axis is anterior->posterior, X axis is left to right on screen (right to left in brain)');
disp('AC Coords (y,x,slice) :');
disp(round(t(1:3,1)));
disp('PC Coords (y,x,slice) :');
disp(round(t(1:3,2)));

t=t(1:3,:);
