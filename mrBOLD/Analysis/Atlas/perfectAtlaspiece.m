function [AtlasA,AtlasE]=perfectAtlaspiece(cc,hemifield,retPhases)
% Create an ideal atlas piece for fitting
%
%   [AtlasA,AtlasE]=perfectAtlaspiece(cc,hemifield,retPhases)
%
% Purpose:
%    creates an atlaspiece out of a set of quadrilaterals and the further
%    defining properties like hemifield and retPhases. For this purpose it
%    uses a transformation that ensures that the isoeccentricity-lines of
%    two adjacent areas co-allign. The transformation also preserves the a
%    given eccentricity distribution.  
%
% History 
% written 12/03/04 by mark@ski.org
% Author: Schira (mark@ski.org), Kontsevich 

% for oversampling we work wit a bitmap just a little bigger than
% necessaray - for this purpose we quadrupel the starting coordinates
cc=cc.*4;
u1 = cc(:,2)-cc(:,1);
u2 = cc(:,3)-cc(:,4);
v1 = cc(:,4)-cc(:,1);
v2 = cc(:,3)-cc(:,2);


limitsXY = [min(cc'),max(cc')];
rangeXY = max(cc')-min(cc');
maxDimXY = max(rangeXY);

%create the two starting bitmaps (as squares)
[stdAtlasE, stdAtlasA,atlasCorners] = ...
        atlasCreateStandard(hemifield,retPhases,maxDimXY);
%creating the target matrix with fillvalues of -1
AtlasA = -1*ones(max(cc')-min(cc'));
AtlasE = -1*ones(max(cc')-min(cc'));

%computing the transformation (by Lenny)
[subJ, subI] = meshgrid(1:maxDimXY,1:maxDimXY);
X = subJ/maxDimXY; Y = subI/maxDimXY;
origXY = [X(:),Y(:)]';

% computing XY in the image
imXY = v1*origXY(2,:)+u2*(origXY(1,:).*origXY(2,:))+u1*((1-origXY(2,:)).*origXY(1,:))+cc(:,1)*ones(1,size(origXY,2));
% computing subscripts and indices in the image
imIJ = Lennyxy2ij(imXY,limitsXY,1);
imIJ = ceil(imIJ);
imInd = sub2ind(size(AtlasA),imIJ(1,:),imIJ(2,:));
% assign values to image


%aplying the transformation to the two bitmaps
AtlasA(imInd) = stdAtlasA(:);
AtlasE(imInd) = stdAtlasE(:);
AtlasA=AtlasA';
AtlasE=AtlasE';

%downsampling the desired size, by skipping overwriting -1 values 
AtlasA=atlasResample(AtlasA);
AtlasE=atlasResample(AtlasE);

return;

%% some helperfunctions

function ij = Lennyxy2ij(xy, limits, dens)
xyPos = xy - limits(1:2)'*ones(1,size(xy,2));
ij = ceil(xyPos*dens*0.999999999 + 0.00000000001);

function out=atlasResample(in)
% the special resampling method. resamples only values other than -1,
% therefore overwriting -1 at the borders, and fillig remaining cavities by
% the mean of their surroundings

out=-1.*ones(size(in,1)/2,size(in,2)/2);
for i=1:2:size(in,1)
    for y=1:2:size(in,2)
        vekt=cat(2,in(i,y),in(i+1,y),in(i,y+1),in(i+1,y+1));
        if sum(vekt==-1)<4
            out(ceil(i/2),ceil(y/2))=mean(vekt(find(vekt>0)));
        end
    end
end

in=out;
out=-1.*ones(size(in,1)/2,size(in,2)/2);
for i=1:2:size(in,1)
    for y=1:2:size(in,2)
        vekt=cat(2,in(i,y),in(i+1,y),in(i,y+1),in(i+1,y+1));
        if sum(vekt==-1)<2
            out(ceil(i/2),ceil(y/2))=mean(vekt(find(vekt>0)));
        end
    end
end

return;
