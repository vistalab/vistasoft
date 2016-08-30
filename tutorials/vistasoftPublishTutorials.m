function vistasoftPublishTutorials(remotename)
% Publish all the vistasoft tutorials as html pages push to gh-pages
%
% vistasoftPublishTutorials(remotename)
%
% inputs:
% remotename = string for a git remote repository. Default is 'origin'
%
% Written by JDY, Feb, 2016 from the AFQ github repository
% Modified by EK, August, 2016 for the vistasoft 'ernie' tutorials

if ~exist('remotename', 'var') || isempty(remotename)
    remotename = 'origin';
end
tdir = fullfile(vistaRootPath,'tutorials');
cd(tdir)

% List of tutorials to publish
tlist = {'t_initAnatomyFromFreesurfer.m','t_initVistaSession'};

% Publish tutorial list
opts.format = 'html';
opts.outputDir = fullfile(tdir,'htmltmp');
for ii = 1:length(tlist)
    publish(tlist{ii},opts); 
end

% Checkout gh-pages branch add tutorials, push to github and change back to
% master branch
[~, curbr] = system('git symbolic-ref --short HEAD')
system('git checkout gh-pages')
system(sprintf('mv %s %s',fullfile(tdir,'htmltmp','*'),tdir))
system(sprintf('rm -d %s %s',fullfile(tdir,'htmltmp')))
system('git add tutorials')
system('git commit -m ''changes to tutorials''')
system(sprintf('git push %s gh-pages', remotename))
system(sprintf('git checkout %s',curbr))