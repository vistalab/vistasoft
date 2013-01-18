function [fx,fy,fz,ft] = computeDerivatives3(in1,in2)
% 
% function [fx,fy,fz,ft] = computeDerivatives3(in1,in2)
%
% in1 and in2 are volumes, 3d arrays
%
% [fx,fy,fz,ft] are volumes, derivatives of the volumes

filter = [0.03504 0.24878 0.43234 0.24878 0.03504];
dfilter = [0.10689 0.28461 0.0  -0.28461  -0.10689];

dz1 = convXYsep(convZ(in1,dfilter),filter,filter);
tmp1 = convZ(in1,filter);
dx1 = convXYsep(tmp1,dfilter,filter);
dy1 = convXYsep(tmp1,filter,dfilter);
blur1 = convXYsep(tmp1,filter,filter);

dz2 = convXYsep(convZ(in2,dfilter),filter,filter);
tmp2 = convZ(in2,filter);
dx2 = convXYsep(tmp2,dfilter,filter);
dy2 = convXYsep(tmp2,filter,dfilter);
blur2 = convXYsep(tmp2,filter,filter);

fx=(dx1+dx2)/2;
fy=(dy1+dy2)/2;
fz=(dz1+dz2)/2;
ft=(blur2-blur1);

