function By = mfBy(yc,para,flag);

if ~exist('flag','var'), flag = 'By';  end;

Omega = para.Omega;
dim   = length(Omega);
m     = para.m;
h     = Omega./m;
a     = sqrt(para.mu);
b     = sqrt(para.mu+para.lambda);

% Bu for elastic-grad
% yc -> [u1,u2,u3]
%
%     dim == 3,                     dim == 2,
%     | d11         |               
%     | d21         |               
%     | d31         |   | u1 |          | d11     |
%     |     d12     |   |    |          | d21     |   | u1 |
%  y= |     d22     | * | u2 |      y = |     d12 | * |    |
%     |     d32     |   |    |          |     d22 |   | u2 |
%     |         d13 |   | u3 |          | d11 d22 |
%     |         d23 |
%     |         d33 |
%     | d11 d22 d33 |

flag = ['elastic-stg-',flag,'-',int2str(dim)];

switch flag
  case 'elastic-stg-By-2'
    nc = m(1)*m(2);
    nn = (m(1)+1)*(m(2)+1);
    ns1 = (m(1)+1)*m(2);
    ns2 = m(1)*(m(2)+1);
    
    I11 = 1:nc;                        % d11 y1
    I21 = I11(end)+(1:nn-2*(m(1)+1));  % d21 y1
    I12 = I21(end)+(1:nn-2*(m(2)+1));  % d12 y2
    I22 = I12(end)+(1:nc);             % d22 y2
    I00 = I22(end)+(1:nc);             % div Y
    
    By = zeros(I00(end),1);
    
    y1 = reshape(yc(1:ns1),m(1)+1,m(2));
    y2 = reshape(yc(ns1+(1:ns2)),m(1),m(2)+1);

    %% d11 y1
    By(I11) = reshape(y1(2:end,:)-y1(1:end-1,:),length(I11),1)/h(1);

    %% d21 y1
    By(I21) = reshape(y1(:,2:end)-y1(:,1:end-1),length(I21),1)/h(2);

    %% d12 y2
    By(I12) = reshape(y2(2:end,:)-y2(1:end-1,:),length(I12),1)/h(1);
    
    %% d22 y2
    By(I22) = reshape(y2(:,2:end)-y2(:,1:end-1),length(I22),1)/h(2);
    
    %% d22 y2
    By(I00) = b*By(I11) + b*By(I22);
    By(1:I22(end)) = a*By(1:I22(end));
    

  case 'elastic-stg-By-3'

    n0 = m(1)*m(2)*m(3);
    n1 = (m(1)+1)*m(2)*m(3);
    n2 = m(1)*(m(2)+1)*m(3);
    n3 = m(1)*m(2)*(m(3)+1);
    
    j1 = m(1)*(m(2)+1)*(m(3)+1);
    j2 = (m(1)+1)*m(2)*(m(3)+1);
    j3 = (m(1)+1)*(m(2)+1)*m(3);
    
    p1 = n0 + j2 + j3;
    p2 = p1 + n0 + j1 + j3;
    p3 = p2 + n0 + j1 + j2;
    
    ly = 4*n0+2*(j1+j2+j3);

%     mfilename, keyboard
    [y1,y2,y3] = vec2array(yc,m,'stg');

    clear yc
    
    By = zeros(ly,1);

    % d11 y1 : n1 -> n0
    dummy = y1(2:end,:,:) - y1(1:end-1,:,:);        
    By(1:n0) = reshape(dummy,n0,1)/h(1);
    
    % d21 y1 : n1 -> j3
    dummy = zeros(m(1)+1,m(2)+1,m(3));
    dummy(:,2:end-1,:) = y1(:,2:end,:) - y1(:,1:end-1,:);    
    By(n0+(1:j3)) = reshape(dummy,j3,1)/h(2);
    
    % d31 y1 : n1 -> j2
    dummy = zeros(m(1)+1,m(2),m(3)+1);
    dummy(:,:,2:end-1) = y1(:,:,2:end) - y1(:,:,1:end-1);
    By(n0+j3+(1:j2)) = reshape(dummy,j2,1)/h(3);

    
    % d12 y2 : n2 -> j3
    dummy = zeros(m(1)+1,m(2)+1,m(3));
    dummy(2:end-1,:,:) = y2(2:end,:,:) - y2(1:end-1,:,:);    
    By(p1+(1:j3)) = reshape(dummy,j3,1)/h(1);

    % d22 y2 : n2 -> n0
    dummy = y2(:,2:end,:) - y2(:,1:end-1,:);    
    By(p1+j3+(1:n0)) = reshape(dummy,n0,1)/h(2);    

    % d32 y2 : n2 -> j1
    dummy = zeros(m(1),m(2)+1,m(3)+1);
    dummy(:,:,2:end-1) = y2(:,:,2:end) - y2(:,:,1:end-1);  
    By(p1+j3+n0+(1:j1)) = reshape(dummy,j1,1)/h(3);
    
    
    % d13 y3 : n3 -> j2
    dummy = zeros(m(1)+1,m(2),m(3)+1);
    dummy(2:end-1,:,:) = y3(2:end,:,:) - y3(1:end-1,:,:);
    By(p2+(1:j2)) = reshape(dummy,j2,1)/h(1);

    % d23 y3 : n3 -> j1
    dummy = zeros(m(1),m(2)+1,m(3)+1);
    dummy(:,2:end-1,:) = y3(:,2:end,:) - y3(:,1:end-1,:);
    By(p2+j2+(1:j1)) = reshape(dummy,j1,1)/h(2);
    
    % d33 y3 : n3 -> n0
    dummy = y3(:,:,2:end) - y3(:,:,1:end-1);        
    By(p2+j2+j1+(1:n0)) = reshape(dummy,n0,1)/h(3);    
    
    
    % div u
    By(end-n0+1:end) = By(1:n0)+By(p1+j3+(1:n0)) + By(p2+j2+j1+(1:n0));
    
    By(1:end-n0)     = a*By(1:end-n0);
    By(end-n0+1:end) = b*By(end-n0+1:end);

    
  case 'elastic-stg-BTy-2'
    
    
    % the input yc is the result of B*y, therefore it can be splitted into 5
    % parts: d11u1, d21u1,d12u2,d22u2,Divy
  
    nc  = m(1)*m(2);
    nn  = (m(1)+1)*(m(2)+1);
    ns1 = (m(1)+1)*m(2);
    ns2 = m(1)*(m(2)+1);
    
    By  = zeros(ns1+ns2,1);
    I11 = 1:nc;                        % d11 y1
    I21 = I11(end)+(1:nn-2*(m(1)+1));  % d21 y1
    I12 = I21(end)+(1:nn-2*(m(2)+1));  % d12 y2
    I22 = I12(end)+(1:nc);             % d22 y2
    I00 = I22(end)+(1:nc);             % div Y
    
    yd = reshape(yc(I11),m);
    zd = reshape([-yd(1,:);yd(1:end-1,:)-yd(2:end,:);yd(end,:)],ns1,1)/h(1);
    By(1:ns1) = a*zd;
    
    yd = reshape(yc(I21),m(1)+1,m(2)-1);
    zd = reshape([-yd(:,1),yd(:,1:end-1)-yd(:,2:end),yd(:,end)],ns1,1)/h(2);
    By(1:ns1) = By(1:ns1) + a*zd;

    yd = reshape(yc(I00),m);
    zd = reshape([-yd(1,:);yd(1:end-1,:)-yd(2:end,:);yd(end,:)],ns1,1)/h(1);
    By(1:ns1) = By(1:ns1) + b*zd;

    yd = reshape(yc(I12),m(1)-1,m(2)+1);
    zd = reshape([-yd(1,:);yd(1:end-1,:)-yd(2:end,:);yd(end,:)],ns2,1)/h(1);
    By(1+ns1:end) = a*zd;

    yd = reshape(yc(I22),m);
    zd = reshape([-yd(:,1),yd(:,1:end-1)-yd(:,2:end),yd(:,end)],ns2,1)/h(2);
    By(1+ns1:end) = By(1+ns1:end) + a*zd;

    yd = reshape(yc(I00),m);
    zd = reshape([-yd(:,1),yd(:,1:end-1)-yd(:,2:end),yd(:,end)],ns2,1)/h(2);
    By(1+ns1:end) = By(1+ns1:end) + b*zd;
    
  case 'elastic-stg-BTy-3'
    
    % the input yc is the result of B*y, therefore it can be splitted into 10
    % parts: d11y1, d21y1,d31y1,d12y2,d22y2,d32y2,d13y3,d23y3,u33y3,Divy
    
    n0 = m(1)*m(2)*m(3);
    n1 = (m(1)+1)*m(2)*m(3);
    n2 = m(1)*(m(2)+1)*m(3);
    n3 = m(1)*m(2)*(m(3)+1);
    
    j1 = m(1)*(m(2)+1)*(m(3)+1);
    j2 = (m(1)+1)*m(2)*(m(3)+1);
    j3 = (m(1)+1)*(m(2)+1)*m(3);
    
    p1 = n0 + j2 + j3;
    p2 = p1 + n0 + j1 + j3;
    p3 = p2 + n0 + j1 + j2;
    

    By = zeros(n1+n2+n3,1);

    % extract Divy
    Divy  = reshape(yc(end-n0+1:end),m(1),m(2),m(3));

    % ---------------------------------- part 1 of u
    % extract D11y1, boundary condition for tangential derivative
    uu = reshape(yc(1:n0),m(1),m(2),m(3));
    dummy = zeros(m(1)+1,m(2),m(3));
    dummy(1,:,:)   = -uu(1,:,:);
    dummy(end,:,:) =  uu(end,:,:);
    dummy(2:end-1,:,:) = uu(1:end-1,:,:) - uu(2:end,:,:);
    By(1:n1) = a*reshape(dummy,n1,1)/h(1);

    % extract D21y1, boundary condition for normal derivative
    uu = reshape(yc(n0+(1:j3)),m(1)+1,m(2)+1,m(3));
    uu(:,[1,end],:) = 0;
    dummy = uu(:,1:end-1,:) - uu(:,2:end,:);
    By(1:n1) = By(1:n1) + a*reshape(dummy,n1,1)/h(2);
    
    % extract D31u1, boundary condition for normal derivative
    uu = reshape(yc(n0+j3+(1:j2)),m(1)+1,m(2),m(3)+1);    
    uu(:,:,[1,end]) = 0;
    dummy = uu(:,:,1:end-1) - uu(:,:,2:end);
    By(1:n1) = By(1:n1) + a*reshape(dummy,n1,1)/h(3);
    
    % Divy, boundary condition for tangential derivative
    dummy = zeros(m(1)+1,m(2),m(3));
    dummy(1,:,:)   = -Divy(1,:,:);
    dummy(end,:,:) =  Divy(end,:,:);
    dummy(2:end-1,:,:) = Divy(1:end-1,:,:) - Divy(2:end,:,:);
    By(1:n1) = By(1:n1) + b*reshape(dummy,n1,1)/h(1);

    % ---------------------------------- part 2 of y
    % extract D12y2, boundary condition for normal derivative
    uu = reshape(yc(p1+(1:j3)),m(1)+1,m(2)+1,m(3));
    uu([1,end],:,:) = 0;
    dummy = uu(1:end-1,:,:) - uu(2:end,:,:);
    By(n1+(1:n2)) = a*reshape(dummy,n2,1)/h(1);
    
    % extract D22y2, boundary condition for tangential derivative
    uu = reshape(yc(p1+j3+(1:n0)),m(1),m(2),m(3));
    dummy = zeros(m(1),m(2)+1,m(3));
    dummy(:,1,:)   = -uu(:,1,:);
    dummy(:,end,:) =  uu(:,end,:);
    dummy(:,2:end-1,:) = uu(:,1:end-1,:) - uu(:,2:end,:);
    By(n1+(1:n2)) = By(n1+(1:n2)) + a*reshape(dummy,n2,1)/h(2);
    
    % extract D32y2, boundary condition for normal derivative
    uu = reshape(yc(p1+j3+n0+(1:j1)),m(1),m(2)+1,m(3)+1);
    uu(:,:,[1,end]) = 0;
    dummy = uu(:,:,1:end-1) - uu(:,:,2:end);
    By(n1+(1:n2)) = By(n1+(1:n2)) + a*reshape(dummy,n2,1)/h(3);
    
    % Divy, boundary condition for tangential derivative
    dummy = zeros(m(1),m(2)+1,m(3));
    dummy(:,1,:)   = -Divy(:,1,:);
    dummy(:,end,:) =  Divy(:,end,:);
    dummy(:,2:end-1,:) = Divy(:,1:end-1,:) - Divy(:,2:end,:);
    By(n1+(1:n2)) = By(n1+(1:n2)) + b*reshape(dummy,n2,1)/h(2);
    
    % ---------------------------------- part 3 of y
    % extract D13y3, boundary condition for normal derivative
    uu = reshape(yc(p2+(1:j2)),m(1)+1,m(2),m(3)+1);    
    uu([1,end],:,:) = 0;
    dummy = uu(1:end-1,:,:) - uu(2:end,:,:);
    By(n1+n2+(1:n3)) = a*reshape(dummy,n3,1)/h(1);
    
    % extract D23y3, boundary condition for normal derivative
    uu = reshape(yc(p2+j2+(1:j1)),m(1),m(2)+1,m(3)+1);
    uu(:,[1,end],:) = 0;
    dummy = uu(:,1:end-1,:) - uu(:,2:end,:);
    By(n1+n2+(1:n3)) = By(n1+n2+(1:n3)) + a*reshape(dummy,n3,1)/h(2);
    
    % extract D32y2, boundary condition for tangential derivative
    uu = reshape(yc(p2+j2+j1+(1:n0)),m(1),m(2),m(3));
    dummy = zeros(m(1),m(2),m(3)+1);
    dummy(:,:,1)   = -uu(:,:,1);
    dummy(:,:,end) =  uu(:,:,end);
    dummy(:,:,2:end-1) = uu(:,:,1:end-1) - uu(:,:,2:end);
    By(n1+n2+(1:n3)) = By(n1+n2+(1:n3)) + a*reshape(dummy,n3,1)/h(3);
    
    % Divy, boundary condition for tangential derivative    
    dummy = zeros(m(1),m(2),m(3)+1);
    dummy(:,:,1)   = -Divy(:,:,1);
    dummy(:,:,end) =  Divy(:,:,end);
    dummy(:,:,2:end-1) = Divy(:,:,1:end-1) - Divy(:,:,2:end);
    By(n1+n2+(1:n3)) = By(n1+n2+(1:n3)) + b*reshape(dummy,n3,1)/h(3);
    
  
  otherwise, jmerror(flag)
end;

% ==============================================================================
