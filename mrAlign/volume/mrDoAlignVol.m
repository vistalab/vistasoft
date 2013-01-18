function [trans, rot] = mrDoAlignVol(inpts, volpts, scaleFac, inpSize, ...
	sagSize, volume, numSlices, retwin, volwin, obwin);
%
%[trans, rot] = mrDoAlignVol(inpts, volpts, scaleFac, inpSize, ...
%	sagSize, volume, numSlices, retwin, volwin, obwin);
%
%	returns alignment matrix given inpts and volpts as corresponding points
%	rot rotates inpts into volpts coordinate frame.
%	scaleFac is a vector containing scalings of the x,y,and z axes 
%		such that inpts*scalefac is at the same scale as volpts

global volslimin1 volslimax1;

nuinpts = inpts ./ (ones(length(inpts),1)*scaleFac(1,:));
nuvolpts = volpts ./ (ones(length(volpts),1)*scaleFac(2,:));
nuvolpts = nuvolpts - (mean(nuvolpts)'*ones(1,length(nuvolpts)))';
nuinpts = nuinpts - (mean(nuinpts)'*ones(1,length(nuinpts)))';

H = zeros(3,3);
for i = 1:length(nuvolpts)
	H = H + (nuinpts(i,:)')*(nuvolpts(i,:));
end
[U,S,V] = svd(H);

mirrorFixer = [ 1 0 0;0 1 0; 0 0 det(U*V);];
rot = [V*mirrorFixer*(U')];

if det(rot) == -1
	disp('Warning: rotation matrix has -1 determinant');
end

alinpts = (rot*(inpts'./(ones(length(inpts),1)*scaleFac(1,:))'))';
nuvolpts = volpts ./ (ones(length(volpts),1)*scaleFac(2,:));
trans = mean(nuvolpts) - mean(alinpts);

% Check that vol = rot*inp + trans;
%alinpts = alinpts+(trans'*ones(1,length(alinpts)))';
%figure(retwin);
%hold on
%plot(inpts(:,1),inpts(:,2),'r-');
%hold off
%figure(volwin);
%hold on
%plot(alinpts(:,1),alinpts(:,2),'r-');
%hold off

% Check it out by displaying anatomy rotated to inplanes first plane

img = mrCheckAlignVol(rot,trans,scaleFac,inpSize,inpts(size(inpts,1),3), ...
			volume,sagSize,numSlices,obwin);

