function fgspline = dtiFiberSplinefit(fg,fname) 

% Fit the spline curve for fascicle/streamlines, and produce the new fg
% structure.
%
% Dependency: This code requires Curve Fitting toolbox
% 
% INPUT:
% fg: fg structure
%
% OUTPUT:
% fgspline: fg structure with spline curve fit
% fname: File name of the output fg file (.pdb or .mat)
%
% (C) Hiromasa Takemura, CiNet HHS/Stanford VISTA Lab

% Generate new fg structure 
fgspline = fgCreate;

for i=1:length(fg.fibers)

x = fg.fibers{i}(1,:);
y = fg.fibers{i}(2,:);
z = fg.fibers{i}(3,:);

% Calculate the 3D distance from the first node
t = cumsum([0;sqrt(diff(x(:)).^2 + diff(y(:)).^2 + diff(z(:)).^2)]);

% The value of x,y,z of the curve depend on that position (t) on the curve. Polynomials are guaranteed when they join to move smoothly. Here after we calculate the spline to represent the line. Curvature can be computed on sx,sy,sz 
sx = spline(t,x);
sy = spline(t,y);
sz = spline(t,z);

% Compute the bins of fascicle trajectory in new fg structure
dt = (t(end)-t(1))./length(x);

% Compute the new curve with spline curve fit
tt = t(1):dt:t(end);
xp = ppval(sx, tt);
yp = ppval(sy, tt);
zp = ppval(sz, tt);

fgspline.fibers{i} = [xp; yp; zp]; 
end

fgspline.fibers = transpose(fgspline.fibers);

if notDefined('fname'),
 return
else
fgspline.name = fname;   
% Save file
fgWrite(fgspline);
end