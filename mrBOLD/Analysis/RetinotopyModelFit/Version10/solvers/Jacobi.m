 function[x,r] = Jacobi(x,b,para,steps);
%function[x,r] = Jacobi(x,b,para,steps);

% n = length(b);

[r,D] = Au(x,para);
r     = b - r; 
D     = para.M + D;

for i=1:steps,
  ss = D\r;
  x = x + para.MGomega*ss; 
  %x = rmnspace(x,para.Z);
  r = b - Au(x,para);   
  %r = b - rmnspace(mfAu(x,para),para.Z); 
%   his(i) = norm(r)/norm(b);  
end;

% figure(1); clf; plot(his)
% mfilename, keyboard
