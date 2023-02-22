%% SVD - The magic machine
%
%
%

%% Make a data set
%
nSubjects = 25;
nRegions = 20;
d = randn(nRegions,nSubjects);

% The face of randomness
mrvNewGraphWin;
imagesc(d)
colormap(gray)

%% Let's describe each column
mrvNewGraphWin;
plot(d(:,1:4))
grid on
xlabel('Tract');
ylabel('Mean FA');

% The goal is to make a linear model such that we have fixed basis
% functions, and the weighted sums of these basis functions predict the
% columns of the matrix.  We use the SVD to do this calculation.
%
% There are many choices in how we might pre-process 'd' before we do this.
%  We could remove the mean, we could standardize by some measure of
%  variance, and so forth.  But the svd stands above all this in its
%  purity.
[U S V] = svd(d);

% Notice a few things about the matrices
% 1. Both U and V are orthonormal matrices.  This means that the row and
% column vector lengths are all 1.  And it means that
mrvNewGraphWin; imagesc(U*U');
imagesc(V'*V)

% S is a diagonal matrix.  The entries along the diagonal are the 'singular
% values', these are closely related to the variance accounted for by each
% of the principal components.
mrvNewGraphWin; plot(diag(S))

% The percent variance accounted for by the first, say, 3 components is
s = diag(S);
sum(s(1:3))/sum(s)
sum(s(1:3).^2)/sum(s.^2)

% Another key fact is that U*S*V' is equal to the data
d2 = U*S*V';
mrvNewGraphWin; plot(d(:),d2(:),'.')

%%  A good basis function is now easy to find
% The columns of U are the basis functions for the best fitting linear
% model. The first column is usually called the first principal component.
plot(U(:,1))

% The percent variance accounted for is
sum(s(1).^2)/sum(s.^2)

% What does this mean?  Let's find a set of weights such that the columns
% in the data matrix, d,  are well approximated by the first column of U.
% The SVD actually gives us these weights.  These are

wgts1 = s(1)*V(:,1);
plot(wgts1)

% The approximations would look like
approx1 = U(:,1)*wgts1(:)';
mrvNewGraphWin([],'tall');
subplot(2,1,1),imagesc(approx1), colormap(gray)
subplot(2,1,2), imagesc(d), colormap(gray)
mrvNewGraphWin;
plot(d(:),approx1(:),'.')
%% Well, suppose we try with a few basis functions, not just one
S2 = S;
mrvNewGraphWin; imagesc(S2); colormap(gray)
for ii=5:nRegions, S2(ii,ii) = 0; end
mrvNewGraphWin; imagesc(S2); colormap(gray)

approx4 = U*S2*V';
mrvNewGraphWin([],'tall');
subplot(2,1,1),imagesc(approx4), colormap(gray)
subplot(2,1,2), imagesc(d), colormap(gray)

mrvNewGraphWin;
plot(d(:),approx4(:),'.')

%%
S2 = S;
mrvNewGraphWin; imagesc(S2); colormap(gray)
for ii=12:nRegions, S2(ii,ii) = 0; end
mrvNewGraphWin; imagesc(S2); colormap(gray)

approx12 = U*S2*V';
mrvNewGraphWin([],'tall');
subplot(2,1,1),imagesc(approx12), colormap(gray)
subplot(2,1,2), imagesc(d), colormap(gray)

mrvNewGraphWin;
plot(d(:),approx12(:),'.')

%% The weights
% Let's use a 2-D fit so we can look at the weights in a simple graph

S2 = S;
for ii=3:nRegions, S2(ii,ii) = 0; end
mrvNewGraphWin; imagesc(S2); colormap(gray)

approx3 = U*S2*V';
mrvNewGraphWin([],'tall');
subplot(2,1,1),imagesc(approx3), colormap(gray)
subplot(2,1,2), imagesc(d), colormap(gray)

mrvNewGraphWin; plot(U(:,1:3))
xlabel('Region')
ylabel('Measure')

mrvNewGraphWin; plot(U(:,1:2))


