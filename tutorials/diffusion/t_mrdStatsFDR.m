%%  compares two groups of DTI images using tensor statistics and FDR.
%
% Probably originated with Armin Schwartzman and Bob.
% Might be deprecated or fixed up.
%
% Armin (c) Stanford VISTASOFT Team 2006???

% Load data
clear
dataPath = pwd;
dataSet = 'SIRL_DTI_sampleData';
[dataSet,dataPath] = uigetfile('*.mat','Select the sample data file.',fullfile(dataPath, dataSet));
if(isnumeric(dataSet)), error('Data file required.'); end
load(fullfile(dataPath, dataSet));
g1 = dti.groups{1};
g2 = dti.groups{2};


%% Test Statistics

% Log transformation
[vec,val] = dtiEig(dti.dt6);
logVal = log(val);
logDt6 = dtiEigComp(vec,logVal);

% Each of the following tests summarizes first the data, and then
% calls the test using the summaries only.
% This avoids having to load the data multiple times and saves memory.

% FA test
fa = dtiComputeFA(val);
[M1, S1, N1] = deal(mean(fa(:,g1),2), std(fa(:,g1),0,2), length(g1));
[M2, S2, N2] = deal(mean(fa(:,g2),2), std(fa(:,g2),0,2), length(g2));
[T, DISTR, df, M, S] = dtiTTest(M1, S1, N1, M2, S2, N2);

% Two-sample test of first eigenvector
vec1 = squeeze(vec(:,:,1,:));
[M1, S1, N1, Sbar1] = dtiDirMean(vec1(:,:,g1));
[M2, S2, N2, Sbar2] = dtiDirMean(vec1(:,:,g2));
[T, DISTR, df, M, S] = dtiDirTest(Sbar1, N1, Sbar2, N2);

% Two-sample test of frame of eigenvectors
[M1, S1, N1] = dtiLogTensorMean(logDt6(:,:,g1));
[M2, S2, N2] = dtiLogTensorMean(logDt6(:,:,g2));
[T, DISTR, df, M, S] = dtiLogTensorTest('vec', M1, S1, N1, M2, S2, N2);

% Display for any of the above tests
Timg = dtiIndToImg(T, dti.maskWM, NaN);
figure, imagesc(Timg(:,:,38)), axis image xy off, colormap('hot'), colorbar
pVal = -log10(1 - cdf(DISTR, T, df(1), df(2)));
pValImg = dtiIndToImg(pVal, dti.maskWM, NaN);
figure, imagesc(pValImg(:,:,38)), axis image xy off, colormap('hot'), colorbar


%--------------------------------------------------------------------
% FDR Analysis

% Simple FDR computation for given p-value threshold
pVal = 1 - cdf(DISTR, T, df(1), df(2));
thresh = 1e-4;
FDR = thresh ./ (sum(pVal < thresh) / length(T));


%--------------------------------------------------------------------
% FDR Analysis with empirical null

% Quantile transformation
switch DISTR,
case 't',
    T = norminv(cdf(DISTR, T, df(1), df(2)));
    DISTR = 'norm';
case 'f',
    T = chi2inv(cdf(DISTR, T, df(1), df(2)), df(1));
    DISTR = 'chi2';
end

% FDR analysis
dt = 0.2;
level = 0.05;
switch DISTR,
case 'norm',
    % Empirical null
    theoNull = fdrEmpNull(T, 'norm', dt, {});
    empNull = fdrEmpNull(Z, 'norm', dt, {'mu','s'});

    % FDR analysis (right tail)
    [fdrTNull, t] = fdrCurve(theoNull.fit, 'tail', 1); % use -1 for left tail
    [fdrENull, t] = fdrCurve(empNull.fit, 'tail', 1);
    thrTheoNull = fdrThresh(fdrTheoNull_R(:,1), t, level, 1);
    thrEmpNull = fdrThresh(fdrEmpNull_R(:,1), t, level, 1);

case 'chi2',
    % Empirical null
    theoNull = fdrEmpNull(T, 'chi2', dt, {}, df(1));
    empNull = fdrEmpNull(T, 'chi2', dt, {'a','nu'}, df(1));

    % FDR analysis (right tail)
    [fdrTNull, t] = fdrCurve(theoNull.fit, 'tail', 1);
    [fdrENull, t] = fdrCurve(empNull.fit, 'tail', 1);
    thrTheoNull = fdrThresh(fdrTNull(:,1), t, level, 1);
    thrEmpNull = fdrThresh(fdrENull(:,1), t, level, 1);
end


%-----------------------------------------------------------------------
% FDR Plots

% Histogram of test stats
figure, set(gcf, 'name', 'Histograms'), hold on
h = bar(theoNull.H.x, theoNull.H.hist, 1, 'w');
h0 = plot(theoNull.H0.x, theoNull.H0.hist, 'b');
h1 = plot(empNull.fit.x, empNull.fit.yhat, 'r');
hold off, legend([h0 h1], 'theo null','emp null',1)
xlabel('T'); ylabel('voxel count');
switch DISTR,
case 'norm',
    a=axis; axis([-4 4 a(3:4)]);
case 'chi2',
    a=axis; axis([0 prctile(T,99) a(3:4)]);
end

% FDR curves
figure,	set(gcf, 'name', 'FDR'), hold on
plot(t, fdrTNull(:,1), 'b')
plot(t, fdrENull(:,1), 'r')
legend('theo null','emp null')
plot(t, fdrTNull(:,2), 'b:', t, fdrTNull(:,3), 'b:')
plot(t, fdrENull(:,2), 'r:', t, fdrENull(:,3), 'r:')
hold off, axis([0 prctile(T,99.99) 0 1]);
xlabel('threshold'); ylabel('FDR');


%-----------------------------------------------------------------------
% Significant voxels

Timg = dtiIndToImg(T, dti.maskWM, NaN);
sgn = 1; % use -1 for left tail
fdrVol = (sgn * Timg > sgn * thrEmpNull);

figure, set(gcf, 'name', 'Significant Voxels')
bg = makeMontage(isfinite(Timg) & ~(fdrVol));
fg = makeMontage(fdrVol);
mont = cat(3, fg, 0.5*fg, bg);
image(mont); axis xy image off
