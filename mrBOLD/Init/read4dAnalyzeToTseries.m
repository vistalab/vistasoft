function view=read4dAnalyzeToTseries(view,inFile,scan,volsToSkip,flipLRflag,timesRot90,flipSliceOrder)
% view=read4dAnalyzeToTseries(view,inFile,scan,volsToSkip,flipLR,timesRot90,flipSliceOrder)
%
% reads in a 4d analyze file and writes TSeries for MRL
% Uses read_avw to read in 4d analyze files. Then saves out the block as
% mlr TSeries while skipping over any initial 'junk frames';
% The roatations and flip are executed in the order of the arguments
% The NumOfRota param allows to you rotate the functional data by doRotate*90 degrees
% timesRot90=1 90� counterclockwise
% timesRot90=2 180� counterclockwise
% timesRot90=3 means 90� clockwise
% a flipUpDown can be performed by timesRot90 and flipLR
%
% 2006.03.20 Mark Schira wrote it 


if (~exist('volsToSkip','var'))
    volsToSkip=0;
end

if (~exist('timesRot90','var'))
    timesRot90=0; % This is off by default. 
end

if (~exist('flipLRflag','var'))
    flipLRflag=0; % This is off by default. Flips left/right after rotation
end

if (~exist('flipSliceOrder','var'))
    flipSliceOrder=0; % This is off by default. Flips left/right after rotation
end

disp('Reading volume');
funcVol=read_avw(inFile);


% Crop the skipped frames
funcVol=funcVol(:,:,:,(volsToSkip+1):end);
[y x nSlices nVols]=size(funcVol);

if y == x
	for thisSlice=1:nSlices
		 for thisVol=1:nVols
				%rotate 
			  if timesRot90>0
					 funcVol(:,:,thisSlice,thisVol)=rot90(squeeze(funcVol(:,:,thisSlice,thisVol)),timesRot90);
			  end %FlipLR
			  if flipLRflag 
					funcVol(:,:,thisSlice,thisVol)=flipLR(squeeze(funcVol(:,:,thisSlice,thisVol)));
			  end
		 end
	end
else		% can't rot90 non-square slices of 4D data
	if timesRot90>0
		for r = 1:timesRot90
			funcVol = permute(funcVol,[2 1 3 4]);
			for thisSlice = 1:nSlices
				for thisVol = 1:nVols
					funcVol(:,:,thisSlice,thisVol) = flipUD(funcVol(:,:,thisSlice,thisVol));
				end
			end
		end
	elseif timesRot90<0
		for r = 1:abs(timesRot90)
			funcVol = permute(funcVol,[2 1 3 4]);
			for thisSlice = 1:nSlices
				for thisVol = 1:nVols
					funcVol(:,:,thisSlice,thisVol) = flipLR(funcVol(:,:,thisSlice,thisVol));
				end
			end
		end
	end
	if flipLRflag
		for thisSlice = 1:nSlices
			for thisVol = 1:nVols
				funcVol(:,:,thisSlice,thisVol) = flipLR(funcVol(:,:,thisSlice,thisVol));
			end
		end
	end
end

% Now write them out in a different format
fprintf('\nDone reading data: Writing now...\n');
if flipSliceOrder
    for t=1:nSlices

        tSeries=squeeze(funcVol(:,:,nSlices-t+1,:));
        tSeries=reshape(tSeries,x*y,nVols);
        tSeries=tSeries';
        saveTSeries(tSeries,view,scan,t);

        fprintf('_');
    end
else
    for t=1:nSlices

        tSeries=squeeze(funcVol(:,:,t,:));
        tSeries=reshape(tSeries,x*y,nVols);
        tSeries=tSeries';
        saveTSeries(tSeries,view,scan,t);

        fprintf('_');
    end
end

fprintf('\nDone\n');
disp(' ');disp(' ');

