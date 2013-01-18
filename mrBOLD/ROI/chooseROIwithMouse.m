function chosenROI = chooseROIwithMouse(vw)
% 
% chosenROI = chooseROIwithMouse(vw)
%
% Use mouse click to pick an ROI.  The mouse click must be within
% a small fraction of a pixel of one of the ROIs.
% 
% djh, 1/10/98

% Programming:  This routine doesn't work properly in the 3-view window
% BW

% First put up some instructions
disp('Click on desired ROI to choose it.');

[y,x,b] = ginput(1);
z =viewGet(vw, 'Current Slice');
x=round(x);
y=round(y);
z=round(z);

chosenROI=0;
for r=1:length(vw.ROIs)
  % Check if clicked on one of the coords.
  coords = vw.ROIs(r).coords;
  % Get min distance between selected pixel and ROI
  if ~isempty(coords)
    xdiff = coords(1,:)-x;
    ydiff = coords(2,:)-y;
    zdiff = coords(3,:)-z;
    diff = xdiff.^2 + ydiff.^2 + zdiff.^2;
    if find (diff < 1e-2)
      chosenROI=r;
    end
  end
end

if chosenROI
  disp(['You have chosen: ',vw.ROIs(chosenROI).name]);
else
  myErrorDlg('You must click ON an ROI to choose it.');
end

