function [atlasA,atlasE,atlasMask]=atlasAjustHoles(atlasA,atlasE,atlasMask)
% [atlasA,atlasE,atlasMask]=atlasAjustHoles(atlasA,atlasE,atlasMask)
% Author: Schira
% Purpose:
%    Clears little holes in an complete "Atlas"
%    basicly this is just a cosmetic operation, assuming any -1 point
%    completly surrounded by "Atlas" points is a "hole"
%    The tool fills in the mean for eccentricity and angle and the median
%    for the mask.

map=zeros(size(atlasE));
ind=find(atlasE~=-1);
map(ind)=1;
map=imdilate(map,[1 1])-map;
ind=find(map==1);
for ii=1:length(ind)
    i=ind(ii);
    b=floor(i/size(atlasE,1));
    a=i-size(atlasE,1)*b;
    b=b+1;
    vekt=cat(2,atlasA(a-1,b),atlasA(a+1,b),atlasA(a,b-1),atlasA(a,b-1));
    if sum(vekt==-1)==0
        atlasA(i)=mean([atlasA(a-1,b),atlasA(a+1,b),atlasA(a,b-1),atlasA(a,b-1)]);
        atlasE(i)=mean([atlasE(a-1,b),atlasE(a+1,b),atlasE(a,b-1),atlasE(a,b-1)]);
        atlasMask(i)=median([atlasMask(a-1,b),atlasMask(a+1,b),atlasMask(a,b-1),atlasMask(a,b-1)]);
    end
end



