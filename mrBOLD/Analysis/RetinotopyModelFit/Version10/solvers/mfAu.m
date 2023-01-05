function [y,D] = mfAu(uc,para)
%function [y,D] = mfAu(uc,para)
% JM 2004/05/18
% computes y =(M + alpha*B'*B)*u
% where M is supposed to be diagonal and B is given via mfBu.m

y = para.M*uc;
y = y + para.alpha*mfBy(mfBy(uc,para,'By'),para,'BTy');
% y = para.M*uc + para.alpha*mfBy(mfBy(uc,para,'By'),para,'BTy');

if nargout<2, return; end;

if para.dim == 2,
  cx = para.mu/para.h(1)^2 + (para.mu+para.lambda)/para.h(1)^2;
  cy = para.mu/para.h(2)^2;
  cc = 2*(cx + cy);
  a1 = cc*ones(para.m(1)+1,para.m(2));
  a1([1,end],:) = a1([1,end],:)-cx;
  a1(:,[1,end]) = a1(:,[1,end])-cy;
  
  cx = para.mu/para.h(1)^2;
  cy = para.mu/para.h(2)^2 + (para.mu+para.lambda)/para.h(2)^2;
  cc = 2*(cx + cy);
  a2 = cc*ones(para.m(1),para.m(2)+1);
  a2([1,end],:) = a2([1,end],:)-cx;
  a2(:,[1,end]) = a2(:,[1,end])-cy;
  
  D = para.alpha*spdiags([a1(:);a2(:)],0,length(uc),length(uc));

%   para.B = getElasticMatrixstg(para.Omega,para.m);
%   y1 = para.M*uc + para.alpha*(para.B'*(para.B*uc));
%   D1 = para.alpha*spdiags(diag(para.B'*para.B),0,size(para.B,2),size(para.B,2));
%   testAu_y = norm(y-y1)
%   testAu_D = norm(diag(D)-diag(D1))
%   
else
  m = para.m;
  a1 = 8*ones(m(1)+1,m(2),m(3));
  a1([1,end],:,:) = a1([1,end],:,:)-2;
  a1(:,[1,end],:) = a1(:,[1,end],:)-1;
  a1(:,:,[1,end]) = a1(:,:,[1,end])-1;
  
  a2 = 8*ones(m(1),m(2)+1,m(3));
  a2([1,end],:,:) = a2([1,end],:,:)-1;
  a2(:,[1,end],:) = a2(:,[1,end],:)-2;
  a2(:,:,[1,end]) = a2(:,:,[1,end])-1;
  
  a3 = 8*ones(m(1),m(2),m(3)+1);
  a3([1,end],:,:) = a3([1,end],:,:)-1;
  a3(:,[1,end],:) = a3(:,[1,end],:)-1;
  a3(:,:,[1,end]) = a3(:,:,[1,end])-2;
  D = (para.alpha/prod(para.h))*...
    spdiags([a1(:);a2(:);a3(:)],0,length(uc),length(uc));
end;

return;
