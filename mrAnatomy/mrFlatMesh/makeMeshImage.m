function distImage=makeMeshImage(coords,inDist,pointsInGrid)    
% function distImage=makeMeshImage(coords,inDist,pointsInGrid)    
% use griddata to make a mesh image
% Last edited ARW $Date: 2007/07/05 19:50:13 $
	minY=min(coords(:,1));
	minX=min(coords(:,2));
	maxY=max(coords(:,1));
	maxX=max(coords(:,2));
	mxm=max([maxX,maxY]);
	mim=min([minX,minY]);
	% Generate a grid
	
	[XI,YI]=meshgrid(linspace(mim,mxm,pointsInGrid));
    
	distImage=griddata(coords(:,1),coords(:,2),inDist,YI,XI,'nearest');
	distImage=reshape(distImage,pointsInGrid,pointsInGrid);
	