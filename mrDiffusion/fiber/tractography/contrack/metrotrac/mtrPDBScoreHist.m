function mtrPDBScoreHist(filename,chColor,lowThresh,dt6Filename)

% lowThresh is value between 0 and 1, i.e. 0.1 will cut off the bottom 10%
% from the histogram
% chColor can be usual 'r', 'g', 'b', ...

if ieNotDefined('dt6Filename')
  outPathName = pwd;
  [f,p] = uigetfile('*.mat', 'Select dt6 file...', outPathName);
  if(isnumeric(f)) error('User cancelled.'); end
  dt6Filename = fullfile(p,f);
end

if ieNotDefined('lowThresh')
    lowThresh = 0.1;
end

% Load pathways
dt6 = load(dt6Filename,'xformToAcPc');
disp('Loading pathways ...');
fg = mtrImportFibers(filename, dt6.xformToAcPc);

% Find length param
scoreVec = mtrGetFGScoreVec(fg);
scoreVec = sort(scoreVec,'descend');
[n,xout] = hist(scoreVec(1:end*(1-lowThresh)),linspace(-50,150,20));
%bar(xout,n,chColor);
nWithNoZeros = n;
nWithNoZeros(n==0) = 1;
plot(xout,log(nWithNoZeros).*double(n>0),chColor);
xlabel('ln(score)');
ylabel('ln(count)');
