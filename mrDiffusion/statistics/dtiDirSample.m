function X = dtiDirSample(k, N, mu)

% X = dtiDirSample(k, [N], [mu])
%
% Generates a sample of size N (default: N = 1) from the bipolar
% Watson distribution on the sphere with concentration k and
% mean vector mu (default: mu = [0 0 1]).
% The output matrix X is 3xN.
%
% Reference:
%   Best & Fisher, "Goodnes of fit and discordancy tests for
%   samples from the Watson distribution on the sphere",
%   Austral. J. Statist. 28(1), 1986, 13-31.
%
% HISTORY:
%   2004.10.26 ASH (armins@stanford.edu) wrote it.

if ~exist('N'),
    N = 1;
end
if ~exist('mu'),
    mu = [0 0 1]';
end
if (k<=0),
    error('Please provide k > 0');
end

Nmax = 1e6;
c = k/(exp(k)-1);
z = [];
while (length(z)<N),
    u = rand(2,min(N,Nmax));
    y = log(u(1,:)*k/c + 1)/k;
    z = [z, y(u(2,:) < exp(k*(y.^2-y)))];
end
z = z(1:N);             % z = cos(theta)
r = sqrt(1-z.^2);       % r = sin(theta)
phi = 2*pi*rand(1,N);
X = [r.*cos(phi); r.*sin(phi); z];

% Rotation to mu using Rodrigues' formula
r = sqrt(mu(1)^2+mu(2)^2);
if (r>0),
    W = [0 0 mu(1); 0 0 mu(2); -mu(1) -mu(2) 0]./r;
	R = eye(3) + sqrt(1-mu(3)^2)*W + (1-mu(3))*W^2;
	X = R*X;
end
