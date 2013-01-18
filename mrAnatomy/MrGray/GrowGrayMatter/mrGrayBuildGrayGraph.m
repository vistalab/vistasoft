function mrGrayBuildGrayGraph(classFile, numLayers, outFile)
% Builds nodes and edges from a class file.
% mrGrayBuildGrayGraph(classFile, numLayers, outFile)
% 
% Builds and save a gray graph from a class file. Does both hemispheres.
% Only tested on new NIFTI-class files, but might work on old '.class'
% class files. 
%
% Note that numLayers is specified in voxels (as with mrGray). You probably
% want ~3mm of gray matter, which is 3 layers for a 1mm class file or 4-5
% layers for 0.7 mm class file.
%
% HISTORY:
% 2008.02.04 RFD wrote it.

opts = {'*.nii;*.nii.gz', 'NIFTI files (*.nii,*.nii.gz)'; '*.*','All Files (*.*)'};
if(~exist('classFile','var')||isempty(classFile))
    [f, p] = uigetfile(opts, 'Pick a NIFTI class file');
    if(isequal(f,0)|| isequal(p,0)) disp('user canceled.'); return; end
    classFile = fullFile(p,f);
end

hemisphere = 'b';
if(hemisphere=='r')
   hemisphere = {'right'}; 
elseif(hemisphere=='l')
   hemisphere = {'left'}; 
else
   hemisphere = {'right','left'};
end


if(~exist('numLayers','var')||isempty(numLayers)) 
   a = inputdlg('Number of gray layers:','Gray Layers',1,{'5'});
   if(isempty(a)), error('user canceled.'); end
   numLayers = str2double(a{1});
end

[p,f,e] = fileparts(classFile);
if(isempty(p)) p = pwd; end
if(strcmpi(e,'.gz')) [junk,f] = fileparts(f); end
lNodes = [];
ni = [];

for(ii=1:length(hemisphere))
   outFile = fullfile(p, [f '_' hemisphere{ii} '_' num2str(numLayers) 'layers.gray']);
   [f2,p2] = uiputfile({'*.gray'},'Save gray graph file as...',outFile);
   if(isequal(f2,0)|| isequal(p2,0)) disp('user canceled.'); return; end
   outFile = fullfile(p2,f2);

   if(isempty(ni))
      [cls,mm,ni] = readClassFile(classFile, 0, 0, hemisphere{ii});
   else
      [cls,mm,ni] = readClassFile(ni, 0, 0, hemisphere{ii});
   end

   [nodes,edges] = mrgGrowGray(cls,numLayers);
   % If we are doing the second hemisphere, check for overlay
   if(~isempty(lNodes))
      % Check for overlap between the two hemispheres
      overlap = find(ismember(lNodes(1:3,:)',nodes(1:3,:)','rows'));
      if(~isempty(overlap))
	 warning('%d nodes overlap between the hemispheres!',numel(overlap));
      else disp('No nodes overlap between the hemispheres!');
      end
      if(~isempty(ni))
         labels = mrGrayGetLabels;
         gmImg = zeros(ni.dim(1:3),'uint8');
         %tmp = flipdim(flipdim(permute(uint8(ni.data),[2 3 1]),1),2)
         inds = sub2ind(ni.dim(1:3), lNodes(3,:), ni.dim(2)-lNodes(1,:)+1, ni.dim(3)-lNodes(2,:)+1);
         gmImg(inds) = labels.leftGray;
         inds = sub2ind(ni.dim(1:3), nodes(3,:), ni.dim(2)-nodes(1,:)+1, ni.dim(3)-nodes(2,:)+1);
         gmImg(inds) = gmImg(inds)+labels.rightGray;        
      else
         gmImg = [];
      end
   elseif(length(hemisphere)>1)
      lNodes = nodes;
   end
   writeGrayGraph(outFile, nodes, edges, size(cls.data));
end

if(~isempty(ni)&&~isempty(gmImg))
   [f3,p3] = uiputfile(opts,'Save gray matter voxels to NIFTI class file...',ni.fname);
   if(isequal(f3,0)|| isequal(p3,0)) disp('user canceled.'); return; end
   ni.data = ni.data+cast(gmImg,class(ni.data));
   ni.fname = fullfile(p3,f3);
   writeFileNifti(ni);
end

return;

