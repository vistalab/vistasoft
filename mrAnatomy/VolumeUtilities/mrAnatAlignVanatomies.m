function mrAnatAlignVanatomies(vAnatSource, vAnatTarget, vAnatSourceAligned)
%
% Simple function to align vAnatSource to vAnatTarget and save it in
% vAnatSourceAligned.
%
% See the end of this file for a sample batch script.
%
% HISTORY:
% 2007.03.22 RFD wrote it.

if(~exist('vAnatSource','var')||isempty(vAnatSource))
    [f,p] = uigetfile('*.dat','Select source vAnatomy that needs aligning...');
    if(isnumeric(f)) disp('user canceled.'); return; end
    vAnatSource = fullfile(p,f);
end
if(~exist('vAnatTarget','var')||isempty(vAnatTarget))
    [f,p] = uigetfile('*.dat','Select target vAnatomy to align to...');
    if(isnumeric(f)) disp('user canceled.'); return; end
    vAnatTarget = fullfile(p,f);
end
if(~exist('vAnatSourceAligned','var')||isempty(vAnatSourceAligned))
    [f,p] = uiputfile('*.dat','Select vAnatomy output file...');
    if(isnumeric(f)) disp('user canceled.'); return; end
    vAnatSourceAligned = fullfile(p,f);
end
interp = [7 7 7 0 0 0];

[tgt.im,tgt.mm]=readVolAnat(vAnatTarget);
[src.im,src.mm]=readVolAnat(vAnatSource);
if(~all(tgt.mm==src.mm)) error('mmPerVox mismatch! Aborting...'); end
xform =  mrAnatRegister(src.im,tgt.im);
bb = [1 1 1; size(tgt.im)];
srcAlign =  mrAnatResliceSpm(double(src.im), xform, bb, [1 1 1], interp, 0);
srcAlign(srcAlign<0|isnan(srcAlign)) = 0;
srcAlign(srcAlign>254.5) = 255;
srcAlign = uint8(round(srcAlign));

writeVolAnat(srcAlign, src.mm, vAnatSourceAligned);
    
return;

% To run a batch:
%
baseDir = '/biac2/wandell2/data/reading_longitude/dti_y3';
[y1f,y1s] = findSubjects(fullfile('/biac2/wandell2/data/reading_longitude/dti','*0*'),'*_dt6',{});
[fn,sc] = findSubjects(fullfile(baseDir,'*0*'),'*_dt6_noMask',{});
for(ii=1:length(fn))
  disp(['Processing ' sc{ii}]);
  y2VanatFile = fullfile(fileparts(fn{ii}),'t1','vAnatomy.dat');
  z = strfind(sc{ii},'0');
  y1Ind = strmatch(sc{ii}(1:z(1)),y1s);
  dt6File = y1f{y1Ind};
  y1VanatFile = fullfile(fileparts(dt6File),'t1','vAnatomy.dat');
  if(~exist(y1VanatFile,'file')|~exist(y2VanatFile,'file'))
    disp('Missing file(s)- skipping.');
  else
      mrAnatAlignVanatomies(y2VanatFile, y1VanatFile, newFname)
  end
end

% To check all the alignments:
outDir = '/biac2/wandell2/data/reading_longitude/alignCheck/';
for(ii=1:length(fn))
  y2VanatFile = fullfile(fileparts(fn{ii}),'t1','vAnatomy_alignY1.dat');
  z = strfind(sc{ii},'0');
  y1Ind = strmatch(sc{ii}(1:z(1)),y1s);
  dt6File = y1f{y1Ind};
  y1VanatFile = fullfile(fileparts(dt6File),'t1','vAnatomy.dat');
  y1 = readVolAnat(y1VanatFile);
  y2 = readVolAnat(y2VanatFile);
  sz = size(y1);
  cropSl = round(sz(3)*.32);
  sl = [cropSl:10:sz(3)-cropSl];

  m1 = makeMontage(y1,sl,'',length(sl));
  m2 = makeMontage(y2,sl,'',length(sl));
  m = uint8(vertcat(m1,m2));
  for(jj=30:30:size(m,2))
    m(:,jj) = m(:,jj)/2+127;
  end
  imwrite(m,gray(256),fullfile(outDir,[sc{ii} 'alignCheck.png']));
end
