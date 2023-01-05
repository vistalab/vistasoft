function h = drawXCorrMatrix(R, clim, sigFigs);
% Show a color-coded cross-correlation matrix (or other small matrix) and 
% indicate the matrix values in each color square.
%
%   h = drawXCorrMatrix(R, [clim=-1 1]);
%
% R should be a 2D matrix that is relatively smaller (less than, say, 20x20
% -- much larger and the text readability will be impacted).
%
% clim should be a 2-vector indicating the min and max matrix values which
% map to the min and max colormap values. Right now, the matrix will be
% colored according to the color map mrvColorMaps('coolhot'). I may expand
% it if this is ever used for more than correlation matrices.
%
% Returns a vector of handles to the image and text labels.
%
% ras 04/2009.
if notDefined('R'),	error('Need a matrix to show.');		end
if notDefined('clim'),	clim = [-1 1];						end
if notDefined('sigFigs'),	sigFigs = 2;					end
	
% this default cmap actually masks the minimum value as black, and the max
% value as white. This works well for cross-correlations with a ones
% diagonal:
cmap = [0 0 0; mrvColorMaps('coolhot', 254); 1 1 1];

% draw the matrix image
h(1) = imagesc(R, clim);
axis image; axis off;
colormap(cmap);

% label the numbers in the matrix
% (I omit the first character -- so '0.2' would be '.2')
for x = 1:size(R, 2)
	for y = 1:size(R, 1)
		if R(y,x)==1
			str = '1';
		elseif R(y,x)==-1
			str = '-1';
		elseif isnan( R(y,x) )
			str = 'NaN'; 
		elseif abs(R(y,x)) < 1
			str = sprintf( ['%.' num2str(sigFigs) 'f'], R(y,x) );
			str = str(2:end);
		else
			str =  sprintf( ['%.' num2str(sigFigs) 'f'], R(y,x) );
		end
		
		h(end+1) = text(x, y, str, 'HorizontalAlignment', 'center', ...
			'FontWeight', 'bold', 'FontSize', 8, 'Color', [.8 .7 .8]);
	end
end

return
