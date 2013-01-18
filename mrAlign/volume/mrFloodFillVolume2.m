function dist = mrFloodFillVolume2(calc, sagSize, numSlices, dataRange,startPt)
%
% mrFloodFillVolume
%
%	dist = mrFloodFillVolume(calc, sagSize, numSlices, dataRange,startPt)
%
%	Calculate minimum distances to pts from starting point while remaining
%	in the region specified by the volume calc.  Uses a
%	flood fill algorithm.
%

calclen = length(calc);
dist = zeros(1,calclen);
indtab = zeros(1,calclen);
goodpts = (calc ~= 0);
tmp = 1:calclen;
coords = tmp(goodpts);
nbors = zeros(26,length(coords));	% Pointers into calc
indtab(goodpts) = 1:length(coords);	% Pointers into nbors
calc(1) = 0;				% For out of rangers
theneigh = 1;
for i = -1:1:1
   for j = -1:1:1
	for k = -1:1:1
	  if (i | j | k)
		disp(theneigh);
		newcoord = coords+i+(j*sagSize(1))+(k*prod(sagSize));
		tmp = (newcoord < 1) | (newcoord > calclen);
		newcoord(tmp) = ones(1,sum(tmp));
		nbors(theneigh,:) = newcoord;
		thedists(theneigh) = sqrt(i*i+j*j+k*k);
	        theneigh = theneigh+1;
	  end
	end
   end
end

clear tmp newcoord coords goodpts;

startPt = mr3d21d(startPt,sagSize,dataRange);
active = [startPt,1]';
calc(startPt) = 0;
thepixel = active';
count = 0;
sum(calc~=0)

while ~isempty(active)
	[themin,mindex] = min(active(2,:));
	if (mod(count,100) == 0)
		disp(count)
	end
	count = count+1;
	thepixel = active(:,mindex);
	dist(thepixel(1)) = thepixel(2);
	active(:,mindex) = [];
	poss = nbors(:,indtab(thepixel(1)));
	gooduns = (calc(poss) ~= 0);
	dists = thedists(gooduns);
	poss = poss(gooduns)';
        calc(poss) = zeros(1,length(poss));
	newpixels = [poss;dists];
	active = [active,newpixels];
end


