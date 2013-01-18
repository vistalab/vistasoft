function dist = mrFloodFillVolume(calc, sagSize, numSlices, dataRange,startPt)
%
% mrFloodFillVolume
%
%	dist = mrFloodFillVolume(calc, sagSize, numSlices, dataRange,startPt)
%
%	Calculate minimum distances to pts from starting point while remaining
%	in the region specified by the volume calc.  Uses a
%	flood fill algorithm.
%

dist = zeros(1,length(calc));

active = [startPt,1]';
calc(mr3d21d(active(1:3),sagSize,dataRange)) = 0;
thepixel = active';
count = 0;
sum(calc ~= 0)

while ~isempty(active)
	[themin,mindex] = min(active(4,:));
	if (mod(count,100) == 0)
		disp(count)
	end
	count = count+1;
	thepixel = active(:,mindex);
	dist(mr3d21d(thepixel(1:3),sagSize,dataRange)) = thepixel(4);
	active(:,mindex) = [];
	for i = -1:1:1
	   for j = -1:1:1
		for k = -1:1:1
  		    nupixel = [thepixel(1)+i,thepixel(2)+j,thepixel(3)+k];
	  	    if((nupixel(3) >= dataRange(1)) & (nupixel(3) <= dataRange(2)))
			foo = mr3d21d(nupixel,sagSize,dataRange);
			if(calc(foo))
			    if(count == 1)
				foo
			    end
			    calc(foo) = 0;
			    a = i*.9375; b = j*.9375; c = k*.7;  % Convert to mm
			    tmp = thepixel(4)+ sqrt(a*a+b*b+c*c);
			    newpixel = [nupixel,tmp]';
			    active = [active,newpixel];
			end
		    end
		end
	    end
	end
end


