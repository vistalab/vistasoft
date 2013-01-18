%mrShowOblVol
[x,y] = mrGinput(2,'arrow');
obX = x;
obY = y;
line(obX,obY,'color',[1,0,0]);
sliceSize = prod(vSize);
numRows = vSize(1);
numCols = vSize(2);
obSize = round(sqrt((x(1)-x(2))^2+(y(1)-y(2))^2));
xincr = (x(2)-x(1))/obSize;
yincr = (y(2)-y(1))/obSize;

clear obPts
for col = (1:numCols)
	for row = (1:obSize)
		vrow = floor(y(1)+yincr*row);
		vcol = floor(x(1)+xincr*row);	
		obPts((col-1)*obSize+row)=(numSlices-1-(vrow-1))*...
			sliceSize+vcol+(col-1)*numRows;
	end
end
obSize = [obSize,numCols];

volselOff = [0,0]';
volselSize = obSize;
sagY = [0,obSize(1)];
mrDispOblVol;
