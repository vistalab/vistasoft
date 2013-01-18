function [unrapt,themedians] = mrUnwrapPhase(fases, locs, binSize)
%
%  MRUNWRAPPHASE
%
%   unrapt = mrUnwrapPhase(fases, locs, binSize)
%
%	Unwraps phase data that lies at location locs.
%	Phase data is assumed to be between 0 and 2pi.
%

locs = locs-min(locs)+1;   % Guarantees range of 1:max(locs)

for i = 1:max(locs)
	range = (locs <= i) & (locs > (i-1));
	if ~isempty(fases(range))
		themedians(i) = median(fases(range));
	else
		themedians(i) = themedians(i-1);
	end
	if(i > 1)
		delmeds(i) = themedians(i-1) - themedians(i);
	else
		delmeds(i) = 0;
	end
	base(i) = 0;
end

curMed = 1;
curBase = 0;
if(binSize > 0)
while curMed < (max(locs)-binSize)
	base(curMed) = curBase;
	tot = sum(delmeds(curMed:(curMed+binSize)));
	dmed = delmeds(curMed)+delmeds(curMed+1);
	if (abs(dmed) >= pi) & (tot > 0)  %Going up
		for i = 1:binSize
			if(sum(delmeds((curMed):(curMed+i))) > 0)
				base(curMed+i) = curBase+1;
			else
				base(curMed+i) = curBase;
			end
		end
		curBase = curBase+1;
		curMed = curMed+binSize+1;
	elseif (abs(dmed) >=  pi) & (tot < 0)  %Going down
		for i = 1:binSize
			if(sum(delmeds((curMed):(curMed+i))) < 0)
				base(curMed+i) = curBase-1;
			else
				base(curMed+i) = curBase;
			end
		end
		curBase = curBase-1;
		curMed = curMed+binSize+1;
	else
		curMed = curMed+1;
	end
end	
%base = cumsum(base);
themedians = themedians+base*2*pi;
end

unrapt = fases;

for i = (1:max(locs))
	range = (locs <= i) & (locs > (i-1));
	if ~isempty(unrapt(range))
		unrapt(range) = unrapt(range) + base(i)*2*pi;
		toobig = range & ((unrapt -themedians(i)) > pi);
		unrapt(toobig) = unrapt(toobig) - (2*pi);
		toosmall = range & ((unrapt -themedians(i)) < -pi);
		unrapt(toosmall) = unrapt(toosmall) + (2*pi);
	end
end
