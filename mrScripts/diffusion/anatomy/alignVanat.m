% Simple script to align a bunch of vAnatomies

baseDir = '/biac2/wandell2/data/reading_longitude/dti_y3';
[y1f,y1s] = findSubjects(fullfile('/biac2/wandell2/data/reading_longitude/dti','*0*'),'*_dt6',{});
%baseDir = '/biac2/wandell2/data/reading_longitude/dti_adults';
[fn,sc] = findSubjects(fullfile(baseDir,'*0*'),'*_dt6_noMask',{});
interp = [7 7 7 0 0 0];
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
    [y1.im,y1.mm]=readVolAnat(y1VanatFile);
    [y2.im,y2.mm]=readVolAnat(y2VanatFile);
    if(~all(y1.mm==y2.mm)) error('mm mismatch!'); end
    xform =  mrAnatRegister(y2.im,y1.im);
    bb = [1 1 1; size(y1.im)];
    y2Align =  mrAnatResliceSpm(double(y2.im), xform, bb, [1 1 1], interp, 0);
    y2Align(y2Align<0|isnan(y2Align)) = 0;
    y2Align(y2Align>254.5) = 255;
    y2Align = uint8(round(y2Align));
    [p,f,e] = fileparts(y2VanatFile);
    newFname = fullfile(p,[f '_alignY1' e]);
    writeVolAnat(y2Align, y2.mm, newFname);
  end
end

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
