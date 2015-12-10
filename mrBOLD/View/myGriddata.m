function im = myGriddata(coords,data,mask)
%
% im = myGriddata(coords,data,mask)
%
% Modification to matlab's griddata to toss parts of the
% resulting image that are far from the initial sample points.
% Assumes coords go from (1,1) to imSize.  Assigns NaNs to pixels
% that are far from the sample points.
%
% coords: 2xN array of (y,x) sample point coordinates
% data: 1xN array of data values
% mask: mask image (size of resulting image) that has 1s where you want
%   to keep the data and NaNs elsewhere.
% 
% rmk 12/1/98 added the check for NaNs and eliminated them if found
%             in the coords which was causing it to crash
%
% rmk & wap 3/11/99 removed the warnings from griddata
%
% wap & bw & hb 5/14/99
%   Finding allf below had a bug.  We worked on it.
%
% djh, 7/99
%   Modified to use precomputed mask image, rather than recomputing it
%   every time.
% Resulting image is the same size as the mask
imSize = size(mask);
if isempty(coords)
    im = NaN*ones(imSize);
else
    % Get coords and data
    y = coords(1,:);
    x = coords(2,:);
    % now that we switch tSeries and corAnal to single, but myGriddata
    % still requires double data type. This is the fix. JL 05/2007
    z = double(data);
    
    % Remove NaN coords
    allFinite = find(isfinite(x) & isfinite(y));
    x = x(allFinite);
    y = y(allFinite);
    z = z(allFinite);
    
    % Call griddata
    yi = [1:imSize(1)]';
    xi = [1:imSize(2)];
    warning off;
    
    if (checkML7)
%             im = griddata(x,y,z,xi,yi,'linear',{'QJ'});
            im = griddata(x,y,z,xi,yi,'linear');
     else         
            im = griddata(x,y,z,xi,yi,'linear');
     end
        
    
    %im = griddata(x,y,z,xi,yi,'linear',{'QJ'});
    %warning backtrace;
    
    % Apply mask
    im = im.*mask;
end
return
% Test that griddata does vector averaging for complex numbers
x = [0,0,1,0,-1,0];
y = [0,0,0,1,0,-1];
z = [1,i,1,i,-1,-i];
xi = [-1:1];
yi = [-1:1]';
foo = griddata(x,y,z,xi,yi,'nearest')
