function Pu = mfPu(uc,dim,m,flag);
% [m1,m2,m3] = size of data related to uc
% we need to prolongations for each direction (staggered/cell centered)
% cell cent: [ 1 0 0    nodal         [ 1
%              3 0 0                    2 
%              3 1 0                    1 1 
%              1 3 0                      2
%
% call 
% uLARGE = mfPu(usmall,dim,  m1,  m2,  m3,'Pu');
% usmall = mfPu(uLARGE,dim,2*m1,2*m2,2*m3,'PTu');
% note the dimensions are related to the size of the input usmall/uLARGE

if ~exist('flag','var'), flag = 'Pu';  end;
m1 = m(1);
m2 = m(2);
if dim == 2, 
  m3 = 1; 
else
  m3 = m(3);
end;
flag = [flag,'-',int2str(dim)];

% [u1,u2,u3] = opgrid('vec2mat staggered',uc,dim,m1,m2,m3);

n1 = (m1+1)*m2*m3;
n2 = m1*(m2+1)*m3;
n3 = m1*m2*(m3+1);

u1 = reshape(uc(1:n1),m1+1,m2,m3);
u2 = reshape(uc(n1+(1:n2)),m1,m2+1,m3);
if dim == 3, 
  u3 = reshape(uc(n1+n2+(1:n3)),m1,m2,m3+1);
end;

switch flag,
  case 'Pu-2',
    u1 = expand(u1,'1-n');  u1 = expand(u1,'2-c');
    u2 = expand(u2,'1-c');  u2 = expand(u2,'2-n');
    u3 = [];
  case 'PTu-2',   
   
    u1 = shrink(u1,'1-n');  u1 = shrink(u1,'2-c');
    u2 = shrink(u2,'1-c');  u2 = shrink(u2,'2-n');
    u3 = [];
  case 'Pu-3',
    u1 = expand(u1,'1-n');  u1 = expand(u1,'2-c');  u1 = expand(u1,'3-c');
    u2 = expand(u2,'1-c');  u2 = expand(u2,'2-n');  u2 = expand(u2,'3-c');
    u3 = expand(u3,'1-c');  u3 = expand(u3,'2-c');  u3 = expand(u3,'3-n');        
  case 'PTu-3',     
    u1 = shrink(u1,'1-n');  u1 = shrink(u1,'2-c');  u1 = shrink(u1,'3-c');
    u2 = shrink(u2,'1-c');  u2 = shrink(u2,'2-n');  u2 = shrink(u2,'3-c');
    u3 = shrink(u3,'1-c');  u3 = shrink(u3,'2-c');  u3 = shrink(u3,'3-n');
  otherwise    
    jmerror(flag)
end;

Pu = [u1(:);u2(:);u3(:)];

return;
%------------------------------------------------------------------------------
function u=shrink(U,dir)

switch dir,
  case '1-n'
   C = zeros(3,1,1);
   C(:,1,1) = [1 2 1]/2;
   U = convn(U,C,'same');
   u = U(1:2:end,:,:);   
 case '1-c'
   U = U([1,1:end,end],:,:);
   C = zeros(4,1,1);
   C(:,1,1) = [1 3 3 1]/4;
   U = convn(U,C,'same');
   u = U(2:2:end-1,:,:);
 case '2-n',
   C = zeros(1,3,1);
   C(1,:,1) = [1 2 1]/2;
   U = convn(U,C,'same');
   u = U(:,1:2:end,:);   
 case '2-c'
   U = U(:,[1,1:end,end],:);
   C = zeros(1,4,1);
   C(1,:,1) = [1 3 3 1]/4;
   U = convn(U,C,'same');
   u = U(:,2:2:end-1,:);
 case '3-n',
   C = zeros(1,1,3);
   C(1,1,:) = [1 2 1]/2;
   U = convn(U,C,'same');
   u = U(:,:,1:2:end);   
 case '3-c'
   U = U(:,:,[1,1:end,end]);
   C = zeros(1,1,4);
   C(1,1,:) = [1 3 3 1]/4;
   U = convn(U,C,'same');
   u = U(:,:,2:2:end-1);
end;
return;
    
%------------------------------------------------------------------------------
%------------------------------------------------------------------------------
function U=expand(u,dir)

switch dir,
  case '1-n'
   U = zeros(2*size(u,1)-1,size(u,2),size(u,3));
   U(1:2:end,:,:)   = u;
   U(2:2:end-1,:,:) = .5*(u(1:end-1,:,:)+u(2:end,:,:));
 case '1-c'
   U = zeros(2*size(u,1),size(u,2),size(u,3));
   U([1,end],:,:)   = u([1,end],:,:);
   U(2:2:end-2,:,:) = .75*u(1:end-1,:,:)+.25*u(2:end,:,:);
   U(3:2:end-1,:,:) = .25*u(1:end-1,:,:)+.75*u(2:end,:,:);   
 case '2-n',
   U = zeros(size(u,1),2*size(u,2)-1,size(u,3));
   U(:,1:2:end,:)   = u;
   U(:,2:2:end-1,:) = .5*(u(:,1:end-1,:)+u(:,2:end,:));
 case '2-c'
   U = zeros(size(u,1),2*size(u,2),size(u,3));
   U(:,[1,end],:)   = u(:,[1,end],:);
   U(:,2:2:end-2,:) = .75*u(:,1:end-1,:)+.25*u(:,2:end,:);
   U(:,3:2:end-1,:) = .25*u(:,1:end-1,:)+.75*u(:,2:end,:);
 case '3-n',
   U = zeros(size(u,1),size(u,2),2*size(u,3)-1);
   U(:,:,1:2:end)   = u;
   U(:,:,2:2:end-1) = .5*(u(:,:,1:end-1)+u(:,:,2:end));
 case '3-c'
   U = zeros(size(u,1),size(u,2),2*size(u,3));
   U(:,:,[1,end])   = u(:,:,[1,end]);
   U(:,:,2:2:end-2) = .75*u(:,:,1:end-1)+.25*u(:,:,2:end);
   U(:,:,3:2:end-1) = .25*u(:,:,1:end-1)+.75*u(:,:,2:end);
end;
return;
%------------------------------------------------------------------------------
