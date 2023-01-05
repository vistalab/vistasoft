function [varargout]=tubeplot(x,y,z,varargin)  

% TUBEPLOT - plots a tube r along the space curve x,y,z.
%
% tubeplot(x,y,z) plots the basic tube with radius 1
% tubeplot(x,y,z,r) plots the basic tube with variable radius r (either a vector or a value)
% tubeplot(x,y,z,r,v) plots the basic tube with coloring dependent on the values in the vector v
% tubeplot(x,y,z,r,v,s) plots the tube with s tangential subdivisions
% (default is 6)
%
% [X,Y,Z]=tubeplot(x,y,z) returns [Nx3] matrices suitable for mesh or surf
%
% Note that the tube may pinch at points where the normal and binormal 
% misbehaves. It is suitable for general space curves, not ones that 
% contain straight sections. Normally the tube is calculated using the
% Frenet frame, making the tube minimally twisted except at inflexion points.
%
% To deal with this problem there is an alternative frame:
% tubeplot(x,y,z,r,v,s,vec) calculates the tube by setting the normal to
% the cross product of the tangent and the vector vec. If it is chosen so 
% that it is always far from the tangent vector the frame will not twist unduly
%
% Example:
%
%  t=0:(2*pi/100):(2*pi);
%  x=cos(t*2).*(2+sin(t*3)*.3);
%  y=sin(t*2).*(2+sin(t*3)*.3);
%  z=cos(t*3)*.3;
%  tubeplot(x,y,z,0.14*sin(t*5)+.29,t,10)
%
% Written by Anders Sandberg, asa@nada.kth.se, 2005


  subdivs = 6;

  N=size(x,1);
  if (N==1)
    x=x';
    y=y';
    z=z';
    N=size(x,1);
  end

  if (nargin == 3)
    r=x*0+1;
  else
    r=varargin{1};
    if (size(r,1)==1 & size(r,2)==1)
      r=r*ones(N,1);
    end
  end
  if (nargin > 5)
    subdivs=varargin{3}+1;
  end
  if (nargin > 6)
    vec=varargin{4};
    [t,n,b]=frame(x,y,z,vec);
  else
    [t,n,b]=frenet(x,y,z);
  end

  

  
  


  X=zeros(N,subdivs);
  Y=zeros(N,subdivs);
  Z=zeros(N,subdivs);

  theta=0:(2*pi/(subdivs-1)):(2*pi);

  for i=1:N
    X(i,:)=x(i) + r(i)*(n(i,1)*cos(theta) + b(i,1)*sin(theta));
    Y(i,:)=y(i) + r(i)*(n(i,2)*cos(theta) + b(i,2)*sin(theta));
    Z(i,:)=z(i) + r(i)*(n(i,3)*cos(theta) + b(i,3)*sin(theta));
  end

  if (nargout==0)
    if (nargin > 4)
      V=varargin{2};
      if (size(V,1)==1)
	V=V';
      end
      V=V*ones(1,subdivs);
      surf(X,Y,Z,V);
    else
      surf(X,Y,Z);
    end
  else
    varargout(1) = {X}; 
    varargout(2) = {Y}; 
    varargout(3) = {Z}; 
  end
