 function[x,r] = mfJacobi(x,b,para,steps);
%function[x,r] = mfJacobi(x,b,para,steps);

% n = length(b);
[r,D] = mfAu(x,para);
r     = b - r; 
D     = para.M + D;

for i=1:steps,
  ss = D\r;
  x = x + para.MGomega*ss; 
  %x = rmnspace(x,para.Z);
  r = b - mfAu(x,para);   
  %r = b - rmnspace(mfAu(x,para),para.Z); 
%   his(i) = norm(r)/norm(b);  
%   figure(2); plot(r); pause
end;

% figure(1); clf; plot(his)
% mfilename, keyboard
