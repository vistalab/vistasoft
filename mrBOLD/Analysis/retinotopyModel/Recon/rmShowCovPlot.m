function rmShowCovPlot(vw,stimulus, datatype, roi, method, save)
% Just a simple function to plot saved coverage plots
%
% rmShowCovPlot(vw,stimulus,datatype[,roi[,method[,save]]])
%
% 02/2010 MB: wrote it

    if ~exist('vw','var') || isempty(vw)
        vw = initHiddenGray();
    end
    
    if ~exist('stimulus','var') || isempty(stimulus)
        error('Need stimulus number');
    end
    
    if ~exist('stimfile','var') || isempty(stimfile)
        stimfile = ['Recon/Presentations/' datatype '/stimfile.mat'];
    end     
    
    if ~exist('roi','var') || isempty(roi)
        roi = 'V1';
    end
    
    if ~exist('method','var') || isempty(method)
        method = 'clipped';
    end    
    
    if ~exist('save','var') || isempty(save)
        save = false;
    end    

    figure;
    
    mask = makecircle( 128 );
    
    i = 1;
        file_dir = [viewGet(vw,'homedir') '/' viewGet(vw,'type') '/' datatype];
        load_dir = [file_dir '/methods/' method '/'];
        
        file = ['CovPlot_' roi '_stim' num2str(stimulus) '-' method '.mat'];

        subplot(3,3,i);
        
        img = load([load_dir file]);
        
%         img = flipud( img.CovPlot ); % QUICKFIX for upside down images
%         img = fliplr( img );
        img = img.CovPlot .* mask;
        
        imagesc( img(:,:) );
        

        
        colormap(jet);
        colorbar;
        axis square;
        
        hold on;
   
    
    i = i + 2;
    
    subplot(3,3,i);
    
    a = load([viewGet(vw,'homedir') '/' stimfile]);
    img = a.images(:,:,stimulus);
    img = single(imresize(mat2gray(img,[0 255]),[128 128]));
    %img = flipud(img);
    imagesc( img(:,:) );
    title(['Natural image']);
    colormap(gray); axis off;
    
    hold on;
    
    i = i + 1;    
    
    subplot(3,3,i);
    
    img = load([viewGet(vw,'homedir') '/Recon/RFcovs/' datatype '/' roi '/' method '/RFcov-stim' num2str(stimulus) '.mat']);
    img = img.RFcov;
    img = reshape(img, [128 128]);
    img = img .* mask;
    
    imagesc( img(:,:) );
    title(['SD map']);
    colormap(jet); colorbar; axis square;
    
    hold on;
    
    i = i + 1;
    
    subplot(3,3,i);

    
    img = load([viewGet(vw,'homedir') '/Recon/pRF models/pRF_models-' roi '-stim' num2str(stimulus) '-' method '.mat']);
    
    all_models = img.all_models;
    all_models_weighted = img.all_models;
    
    switch method
         % coverage = sum(pRF(i)*w(i)) / (sum(pRF(i))
        case {'beta-sum','betasum','weight average','weightavg'}
            RFcov = sum(all_models_weighted, 2) ./ sum(all_models,2);
            
        % coverage = sum(pRF(i)*w(i)) / (sum(pRF(i)) + clipping
        case {'clipped beta-sum','clippedbeta','clipped weight average','clippedweightavg'}
            % set all pRF beyond 2 sigmas to zero
            clipval = exp( -.5 *((1./1).^2));
            % clip to FWHM
            %clipval = 2*sqrt(2*log(2));
            all_models(all_models<clipval) = 0;
            n = all_models > 0;
            
            % recompute all_models_weighted
			tmp = ones( size(all_models,1), 1, 'single' );
            all_models_weighted = all_models;
            
            % compute weighted clipped sum/average
            sumn = sum(n,2);
            mask = sumn==0;
            sumn(mask) = 1; % prevent dividing by 0
            RFcov = sum(all_models_weighted,2) ./ sum(all_models,2);
            RFcov(mask) = 0;
            
         
           
        % coverage = sum(pRF(i)*w(i)) / (sum(w(i))
        case {'sum','add','avg','average','pRF average','prfavg'}
            RFcov = sum(all_models_weighted, 2) ./ sum(weight);
        
        % coverage = sum(pRF(i)*w(i)) / (sum(w(i)) + clipping
        case {'clipped average','clipped','clipped pRF average','clippedprfavg'}
            % set all pRF beyond 2 sigmas to zero
            clipval = exp( -.5 *((2./1).^2));
            all_models(all_models<clipval) = 0;
            n = all_models > 0;
            
            % recompute all_models_weighted
			tmp = ones( size(all_models,1), 1, 'single' );
            all_models_weighted = all_models;
            
            % compute weighted clipped mean
            sumn = sum((tmp*weight).*n);
            mask = sumn==0;
            sumn(mask) = 1; % prevent dividing by 0
            RFcov = sum(all_models_weighted,2) ./ sumn;
            RFcov(mask) = 0;
            

            
        % coverage = max(pRF(i))
        case {'maximum profile', 'max', 'maximum'}
            RFcov = max(all_models_weighted,[],2);
            
        case {'signed profile'}
            RFcov  = max(all_models_weighted,[],2);
            covmin = min(all_models_weighted,[],2);
            ii = RFcov<abs(covmin);
            RFcov(ii)=covmin(ii);
            
        case {'p','probability','weighted statistic corrected for upsampling'}
            RFcov = zeros(vfc.nSamples);
			
			% I guess this upsample factor assumes your functional data are
			% 2.5 x 2.5 x 3 mm?
            upsamplefactor = 2.5*2.5*3; % sigh.....
            for ii = 1:size(all_models,1)
                s = wstat(all_models(ii,:),weight,upsamplefactor);
                if isfinite(s.tval)
                    RFcov(ii) = 1 - t2p(s.tval,1,s.df);
                end
			end
        otherwise
            error('fout');
    end
    
    RFcov = reshape(RFcov, [128 128]);
    %RFcov = RFcov .* mask;
    
    imagesc( RFcov(:,:) );
    title(['pRF coverage']);
    colormap(jet); colorbar; axis square;    
    
    if save
        print('-djpeg','overview.jpg');
    end
    
    
    
    
    
