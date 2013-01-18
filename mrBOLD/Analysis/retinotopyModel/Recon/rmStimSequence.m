function rmStimSequence(folder,saveFolder,tr)
    
    if ~exist('tr','var') || isempty(tr)
        %numberOfImages = 6;
        tr = 2;
    end
    
    if ~exist(folder,'dir')
        error('Presentations folder does not exist!');
    end
    
    if ~exist(saveFolder,'dir')
        mkdir(saveFolder);
    end        
    
    % Get the .mat files in the folder
    folderContents = what(folder);
    matFiles = folderContents.mat;
    

    
    % Loop through the files and load them separately
    for i = 1:length(matFiles)
        %clear stimulus; % Clear the old workspace
        if ~strcmp(char(matFiles(i)),'stimfile.mat')
        load([folder '/' char(matFiles(i))]); % Load the saved workspace
        
        % Get filename to save .par
        seqName = char(matFiles(i)); % Convert to string
        seqName = seqName( 1 : (length(seqName)-4) ); % Remove .mat        
        
        sequenceStim = stimulus.seq; % Get the sequence
        
        % Reshape the sequence to colWidth
        % This corresponds to a Xs TR (since time-steps are 50ms)
        colWidth = tr / 0.05;
        sequenceStim = reshape(sequenceStim,colWidth,length(sequenceStim(:))/colWidth);
        
        sequenceElem = min(sequenceStim);
        
        sequenceElem = sequenceElem(:);

        
        % !!DEPRECATED!!
        % Determine which condition we had
        %
        %                    FADE  /  ON    /  FADE  /  OFF
        % A:    Flashing             100ms  /        / 100ms
        % B:    Flashing             200ms  /        / 100ms
        % C:    Flashing             400ms  /        / 100ms
        % D:    Fading      150ms  / 300ms  / 150ms  / 100ms
        % E:    Fading      300ms  / 300ms  / 300ms  / 200ms        
        %
        
        condition = '-X';
        
%         if sequenceElem(1) == 43
%             condition = '-E';
%         elseif sequenceElem(1) == 25
%             condition = '-D';
%         else
%             switch length( find( sequenceStim == 1) )
%                 case 60 
%                     condition = '-A';
%                 case 84 
%                     condition = '-B';
%                 case 96
%                     condition = '-C';
%             end
%         end     
        
        % Write to the .seq file
        dlmwrite([saveFolder '/' seqName condition '.seq'], sequenceElem, '\t');        
        end
    end
    
    if ~exist([folder '/stimfile.mat'],'file')
        matfile = load([folder '/' char(matFiles(1))]);
        images = matfile.original_stimulus.images{1};
       save([folder '/stimfile.mat'],'images');
    end    