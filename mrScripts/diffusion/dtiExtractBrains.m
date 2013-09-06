imOut = '/biac3/wandell4/data/reading_longitude/betCheck';
baseDir = {'/biac3/wandell4/data/reading_longitude/dti_y1',...
		   '/biac3/wandell4/data/reading_longitude/dti_y2',...
		   '/biac3/wandell4/data/reading_longitude/dti_y3',...
		   '/biac3/wandell4/data/reading_longitude/dti_y4'};
bet = 'bet2';
% fractional intensity threshold (0->1); default=0.5; 
% smaller values give larger brain outline estimates
betF = {'0.35','0.40','0.45','0.55','0.60','0.65'};

for(jj=1:length(baseDir))
  d = dir(fullfile(baseDir{jj},'*0*'));
  for(ii=1:length(d))
    subCodes{ii} = d(ii).name;
    files{ii} = fullfile(baseDir{jj},d(ii).name,'t1','t1');
  end
  
  if(~exist(imOut,'dir')), mkdir(imOut); end
  N = length(files);
  doThese = [1:N];
  for(ii=doThese)
	if(~exist([files{ii} '.nii.gz'],'file'))
	  disp(['Skipping ' subCodes{ii} '...']);
	else
	  fprintf('Processing %s (%d of %d)...\n', files{ii}, ii, length(doThese));
	  t1 = niftiRead([files{ii} '.nii.gz']);
	  slices = [1:3:t1.dim(3)-6];
	  im = double(makeMontage(t1.data, slices));
	  clear t1;
	  im = mrAnatHistogramClip(im, 0.4, 0.99);
	  im = uint8(im./max(im(:)).*255+0.5);
	  for(jj=1:length(betF))
		outName = [files{ii} '_' betF{jj}];
		betCmd = [bet ' ' files{ii} ' ' outName ' -mnf ' betF{jj}];
		disp(['   running BET: ' betCmd '...']);
		unix(['export FSLOUTPUTTYPE=NIFTI_GZ ; ' betCmd]);
		mask = niftiRead([outName '_mask.nii.gz']);
		mask = logical(makeMontage(mask.data, slices));
		skull = im; skull(mask) = 0;
		brain = im; brain(~mask) = 0;
		rgb(:,:,1) = brain;
		rgb(:,:,2) = skull+brain;
		rgb(:,:,3) = brain;
		imwrite(rgb, fullfile(imOut, [subCodes{ii} '_betF' betF{jj}(end-2:end) '.png']));
	  end
	end
  end
end
