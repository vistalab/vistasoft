function dist = mrFloodCityPlane(planeSize,inCalc,startPt)
%
% mrFloodFillPlane
%
%	Calculate minimum distances to pts from starting point while remaining
%	in the region specified by the boolean image inCalc.  Uses a
%	flood fill algorithm.

dist = zeros(planeSize(1),planeSize(2));
inCalc = reshape(inCalc,planeSize(1),planeSize(2));

active = [startPt,1,-1]';
inCalc(active(2),active(1)) = 0;
thepixel = active';
[themin,mindex] = min(active(3,:));

while (themin ~= 99999)
	thepixel = active(:,mindex);
	dist(thepixel(2),thepixel(1)) = thepixel(3);
	active(3,mindex) = 99999;
	for thecoord = 1:2
	    for thedir = [-1,1]
		i = 0; j = 0;
		if(thecoord == 1)
			i = i+thedir;
		else
			j = j+thedir;
		end
		if(((thepixel(2)+j) >= 1) & ((thepixel(2)+j) <= planeSize(1)) ...
		   & ((thepixel(1)+i) >= 1) &  ((thepixel(1)+i) <= planeSize(2)))
			if(inCalc(thepixel(2)+j,thepixel(1)+i))
				inCalc(thepixel(2)+j,thepixel(1)+i) = 0;
			        pdir = thepixel(4);
			        if((thecoord == pdir) || (pdir == -1))
					nudist = thepixel(3)+1;
        				pdir = thecoord;
				else  
					nudist = (thepixel(3)-1;
					nudist = nudist + sqrt(2);
					pdir = -1;
   				end
				newpixel = [thepixel(1)+i,thepixel(2)+j, ...
						nudist,pdir]';
				active = [active,newpixel];
			end
		end
	end
	[themin,mindex] = min(active(3,:));
end


