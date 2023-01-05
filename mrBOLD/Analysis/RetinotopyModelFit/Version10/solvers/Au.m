function [y,D] = Au(uc,para)
%function [y,D] = Au(uc,para)
% JM 2004/05/18
% computes y =(M + alpha*B'*B)*u
% where M is supposed to be diagonal and B is given via mfBu.m


y = para.M*uc + para.alpha*(para.B'*(para.B*uc));


if nargout<2, return; end;

D = para.alpha*spdiags(diag(para.B'*para.B),0,size(para.B,2),size(para.B,2));

return;
if para.dim == 2,
  a1 = 7*ones(para.m(1)+1,para.m(2));
  a1([1,end],:,:) = a1([1,end],:,:)-2;
  a1(:,[1,end],:) = a1(:,[1,end],:)-1;
  a1(:,:,[1,end]) = a1(:,:,[1,end])-1;
  
  a2 = 7*ones(para.m(1),para.m(2)+1);
  a2([1,end],:,:) = a2([1,end],:,:)-1;
  a2(:,[1,end],:) = a2(:,[1,end],:)-2;
  a2(:,:,[1,end]) = a2(:,:,[1,end])-1;
  
  D = para.h(1)*para.h(2)*para.alpha*spdiags([a1(:);a2(:)],0,length(uc),length(uc));
  keyboard
else
  a1 = 8*ones(para.m1+1,para.m2,para.m3);
  a1([1,end],:,:) = a1([1,end],:,:)-2;
  a1(:,[1,end],:) = a1(:,[1,end],:)-1;
  a1(:,:,[1,end]) = a1(:,:,[1,end])-1;
  
  a2 = 8*ones(para.m1,para.m2+1,para.m3);
  a2([1,end],:,:) = a2([1,end],:,:)-1;
  a2(:,[1,end],:) = a2(:,[1,end],:)-2;
  a2(:,:,[1,end]) = a2(:,:,[1,end])-1;
  
  a3 = 8*ones(para.m1,para.m2,para.m3+1);
  a3([1,end],:,:) = a3([1,end],:,:)-1;
  a3(:,[1,end],:) = a3(:,[1,end],:)-1;
  a3(:,:,[1,end]) = a3(:,:,[1,end])-2;
  D = para.m1^3*para.alpha*...
    spdiags([a1(:);a2(:);a3(:)],0,length(uc),length(uc));
end;

return;
