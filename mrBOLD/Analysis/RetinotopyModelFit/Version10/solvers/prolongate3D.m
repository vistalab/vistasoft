function w = prolongate3D(u,grid);

if ~exist('grid','var'), grid = 'cell centered';  end;

switch grid,
  case 'cell centered',
    z = zeros(2*size(u,1),size(u,2));
    z(1:2:end-1,:) = [u(1,:)+(u(1,:)-u(2,:))/4;...
        0.25*u(1:end-1,:)+0.75*u(2:end,:)];
    z(2:2:end,:)   = [0.75*u(1:end-1,:)+0.25*u(2:end,:);...
        u(end,:)+(u(end,:)-u(end-1,:))/4];
    
    v = zeros(2*size(u));
    v(:,1:2:end-1) = [z(:,1)+(z(:,1)-z(:,2))/4,...
        0.25*z(:,1:end-1)+0.75*z(:,2:end)];
    v(:,2:2:end)   = [0.75*z(:,1:end-1)+0.25*z(:,2:end),...
        z(:,end)+(z(:,end)-z(:,end-1))/4];
  case 'staggered-1'
    z = zeros(2*size(u,1)-1,size(u,2),size(u,3));
    z(1:2:end,:,:)   = u;
    z(2:2:end-1,:,:) = 0.5*u(1:end-1,:,:) + 0.5*u(2:end,:,:);
    
    v = zeros(2*size(u,1)-1,2*size(u,2),size(u,3));
    v(:,2:2:end-2,:) = 0.75*z(:,1:end-1,:) + 0.25*z(:,2:end,:);
    v(:,3:2:end-1,:) = 0.25*z(:,1:end-1,:) + 0.75*z(:,2:end,:);
    v(:,1,:)   = 2*v(:,2,:)    -v(:,3,:);
    v(:,end,:) = 2*v(:,end-1,:)-v(:,end-2,:);
    
    w = zeros(2*size(u,1)-1,2*size(u,2),2*size(u,3));
    w(:,:,2:2:end-2) = 0.75*v(:,:,1:end-1) + 0.25*v(:,:,2:end);
    w(:,:,3:2:end-1) = 0.25*v(:,:,1:end-1) + 0.75*v(:,:,2:end);
    w(:,:,1)   = 2*w(:,:,2)    -w(:,:,3);
    w(:,:,end) = 2*w(:,:,end-1)-w(:,:,end-2);
    
  case 'staggered-2'
    z = zeros(size(u,1),2*size(u,2)-1,size(u,3));
    z(:,1:2:end,:)   = u;
    z(:,2:2:end-1,:) = 0.5*u(:,1:end-1,:) + 0.5*u(:,2:end,:);    
    
    v = zeros(2*size(u,1),2*size(u,2)-1,size(u,3));
    v(2:2:end-2,:,:) = 0.75*z(1:end-1,:,:) + 0.25*z(2:end,:,:);
    v(3:2:end-1,:,:) = 0.25*z(1:end-1,:,:) + 0.75*z(2:end,:,:);
    v(1,:,:)   = 2*v(2,:,:)    -v(3,:,:);
    v(end,:,:) = 2*v(end-1,:,:)-v(end-2,:,:);
    
    w = zeros(2*size(u,1),2*size(u,2)-1,2*size(u,3));
    w(:,:,2:2:end-2) = 0.75*v(:,:,1:end-1) + 0.25*v(:,:,2:end);
    w(:,:,3:2:end-1) = 0.25*v(:,:,1:end-1) + 0.75*v(:,:,2:end);
    w(:,:,1)   = 2*w(:,:,2)    -w(:,:,3);
    w(:,:,end) = 2*w(:,:,end-1)-w(:,:,end-2);
  case 'staggered-3'
    z = zeros(size(u,1),size(u,2),2*size(u,3)-1);
    z(:,:,1:2:end)   = u;
    z(:,:,2:2:end-1) = 0.5*u(:,:,1:end-1) + 0.5*u(:,:,2:end);    
    
    v = zeros(2*size(u,1),size(u,2),2*size(u,3)-1);
    v(2:2:end-2,:,:) = 0.75*z(1:end-1,:,:) + 0.25*z(2:end,:,:);
    v(3:2:end-1,:,:) = 0.25*z(1:end-1,:,:) + 0.75*z(2:end,:,:);
    v(1,:,:)   = 2*v(2,:,:)    -v(3,:,:);
    v(end,:,:) = 2*v(end-1,:,:)-v(end-2,:,:);
    
    w = zeros(2*size(u,1),2*size(u,2),2*size(u,3)-1);
    w(:,2:2:end-2,:) = 0.75*v(:,1:end-1,:) + 0.25*v(:,2:end,:);
    w(:,3:2:end-1,:) = 0.25*v(:,1:end-1,:) + 0.75*v(:,2:end,:);
    w(:,1,:)   = 2*w(:,2,:)    -w(:,3,:);
    w(:,end,:) = 2*w(:,end-1,:)-w(:,end-2,:);
end;

