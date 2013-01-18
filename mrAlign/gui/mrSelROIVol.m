tmppts=mrSelVol(volselim,volselSize,[volselOff(1),volselOff(1)+volselSize(2)],...
		[volselOff(2),volselOff(2)+volselSize(1)], obSize,sagX,sagY);
volselpts = [volselpts,obPts(tmppts)];


