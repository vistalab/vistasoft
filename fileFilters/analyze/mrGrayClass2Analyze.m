function  [s]=mrGrayClass2Analyze(mrGrayClassFileName,analyseFileRoot,mmPerVoxel)
% function  [s]=mrGrayClass2Analyze(mrGrayClassFileName,analyseFileRoot)
% Converts Stanford VISTA lab / mrGray Class format to Analyze7.5 format.
% Analyze headers hold far more information than we have access to. In fact
% the class files have almost no info in them.
% For now, we write out a file where the mm/vox is set to [1 1 1] (unless
% otherwise specified) and all other fields are blank
% See also analyze2mrGray, mrGray2Analyze
% Returns 
% s - Analyse header modified after image write.
% ARW 012804
if (~exist('mrGrayClassFileName'))
    [mrGrayClassFile,mrGrayClassFilePath]=uigetfile( ...
       {'*.Class';'*.CLASS';'*.class';'*.*'}, ...
        'Pick a class file');
    mrGrayClassFileName=fullFile(mrGrayClassFilePath,mrGrayClassFile);
    
end
[classData]=readClassFile(mrGrayClassFileName);
% Structure fields:

 %   filename: 'right.Class'
 %     type: [1x1 struct]
 %    header: [1x1 struct]
 %      data: [256x256x256 uint8]
 
% If mmPerVox is 0, set it to 111
if (~exist('mmPerVox'))
    mmPerVox=[1 1 1];
end


classData.data=double(classData.data);

% Now we have to write out a header file and an image file. 
% We write out the header using the SPM command spm_write_vol
% We dump out the image data as uint8 bytes.

% Use spm_hwrite to write the header.
% FORMAT [s] = spm_hwrite(P,DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP);
% Need to rearrange the image. Analyze data run with sag and axial directions flipped. Also upside down in mrGray...                 
newimg=zeros(classData.header.zsize,classData.header.ysize,classData.header.xsize);

classData.data=shiftdim(classData.data,2);
% Some more work needed here...

%  
% for thisIm=1:(classData.header.xsize)     
%     newimg(thisIm,:,:)=flipud(squeeze(classData.data(thisIm,:,:)));    
% end

 for thisIm=1:(classData.header.ysize)     
     newimg(:,thisIm,:)=fliplr(squeeze(classData.data(:,thisIm,:)));    
 end

  for thisIm=1:(classData.header.zsize)     
      newimg(:,:,thisIm)=fliplr(squeeze(newimg(:,:,thisIm)));    
  end
%newimg=classData.data;


img_dim=size(newimg);
if (~exist('analyzeFileRoot'))
    [analyzeFile,analyzeFilePath]=uiputfile( ...
       {'*.hdr';'*.img';'*.*'}, ...
        'Pick an analyze file name');
    analyzeFileName=fullFile(mrGrayClassFilePath,mrGrayClassFile);
   [apathstr,aname,aextension,aver] = fileparts(analyzeFileName) 
   analyzeFileRoot=fullfile(apathstr,aname);
   
end
s=spm_hwrite(analyzeFileRoot,img_dim,mmPerVox,1,spm_type('uint8'),0);
V=spm_vol(analyzeFileRoot);
V.descrip=['Converted from mrGray class file ',mrGrayClassFileName,' on ',datestr(now)];

s=spm_write_vol(V,newimg);
