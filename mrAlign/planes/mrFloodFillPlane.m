function dist = mrFloodFillPlane(planeSize,inCalc,startPt)
%
% mrFloodFillPlane
%
%	Calculate minimum distances to pts from starting point while remaining
%	in the region specified by the boolean image inCalc.  Uses a
%	flood fill algorithm.

dist = zeros(planeSize(1),planeSize(2));
inCalc = reshape(inCalc,planeSize(1),planeSize(2));

active = [startPt,1]';
inCalc(active(2),active(1)) = 0;
thepixel = active';
[themin,mindex] = min(active(3,:));
%count = 0;
%sum(sum(inCalc))

while (themin ~= 99999)
%	disp(count)
%	count = count+1;
	thepixel = active(:,mindex);
	dist(thepixel(2),thepixel(1)) = thepixel(3);
	active(3,mindex) = 99999;
	for i = -1:1:1
		for j = -1:1:1
			if(((thepixel(2)+j) >= 1) & ((thepixel(2)+j) <= planeSize(1)) ...
			   & ((thepixel(1)+i) >= 1) &  ((thepixel(1)+i) <= planeSize(2)))
			if(inCalc(thepixel(2)+j,thepixel(1)+i))
				inCalc(thepixel(2)+j,thepixel(1)+i) = 0;
				tmp = thepixel(3)+sqrt(i*i+j*j);
				newpixel = [thepixel(1)+i,thepixel(2)+j,tmp]';
				active = [active,newpixel];
			end
			end
		end
	end
	[themin,mindex] = min(active(3,:));
end


