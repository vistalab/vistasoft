function  [fg_reoriented, startCoords, endCoords, numFlippedFibers]=dtiReorientFibers(fg, numNodes)
%Reorient and resamples fibers in a group
%
% [fg_reoriented, startCoords, endCoords, numFlippedFibers]=dtiReorientFibers(fg, [numNodes])
%
% This function goes through the fibers in a fibergroup (fg) resamples them
% and reorders the nodes if nessesary so that all the "first" nodes are
% grouped on one end of the FG, and all the "last" nodes are at another.
%
% This routine should only be run on a fairly consistent fiber bundle.
%
% If numNodes is provided, all fibers are resampled to numNodes and then
% reoriented to the first fiber.
%
% If numNodes is not provided, fibers are not resampled. Instead, endpoints
% (last and first, altogether) are clustered in the space to yield two
% distinct clusters. The obtained  cluster assignment is used to label
% endpoints as "first" (cluster 1) and "last" (cluster 2).
%
% NOTE: Because of the algorithm used here, namely matching to the first
% one, this function may end up flipping the majority of your fibers such
% that the first points become last points, etc.  It might be better to
% examine the end points first and choose an algorithm that flips the
% smallest number of fibers.
%
%HISTORY
%ER wrote it 2007
%
% (c) Stanford Vista Team 2007

if ~exist('fg','var') || isempty(fg)
    error('Please supply a fiber group')
elseif isempty(fg.fibers)
    fg_reoriented=fg;
    startCoords=[];
    endCorrds=[];
    numFlippedFibers=0;
    return
end
    
if ~exist('numNodes', 'var')
    method='cluster_endpoints';
    %display('Fiber reorienting method is cluster_endpoints');
else
    method='match_first_fiber';
    %display('Fiber reorienting method is match_a_fiber');
end

fg_reoriented=fg;

switch method
    case 'match_first_fiber'

        curve1 = dtiFiberResample(fg.fibers{1}, numNodes);
        %A "randomly picked" (first) fiber is the template to which every
        %other fiber is matched. This method is not too robust due to the
        %fact that the frst fiber picked may not span nicely the space
        %taken by the fibergroup.  We should do better.
        numFlippedFibers=0;

        for i=1:size(fg.fibers, 1)
            curve2= dtiFiberResample(fg.fibers{i}, numNodes);
            curve2flipped =fliplr(curve2);
            noflipdist = mean(sqrt((curve1(1, :)-curve2(1, :)).^2+(curve1(2, :)-curve2(2, :)).^2+(curve1(3, :)-curve2(3, :)).^2));
            flipdist= mean(sqrt((curve1(1, :)-curve2flipped(1, :)).^2+(curve1(2, :)-curve2flipped(2, :)).^2+(curve1(3, :)-curve2flipped(3, :)).^2));

            if flipdist<noflipdist
                fg_reoriented.fibers{i}=curve2flipped;
                numFlippedFibers=      numFlippedFibers+1;
            else
                fg_reoriented.fibers{i}=curve2;
            end
        end


%         if  numFlippedFibers>0
%             display(['Flipped ' num2str(      numFlippedFibers) ' fibers of ' num2str(length(fg.fibers)) ]);
%         end
        
        startCoords=zeros(3, 1);
        endCoords=zeros(3, 1);
        for fiberID=1:length(fg.fibers)
            startCoords=startCoords+fg_reoriented.fibers{fiberID}(:, 1);
            endCoords=endCoords+fg_reoriented.fibers{fiberID}(:, end);
        end
        startCoords=startCoords./length(fg.fibers);
        endCoords=endCoords./length(fg.fibers);


    case 'cluster_endpoints'

        error('cluster_endpoints not yet implemented');
        
        %method 2.  __ NEEDS TO BE FINISHED, BROKEN FOR NOW
        %Check that the all the starting points and all the end points are grouped.
        %Flip the fibers whose end point groups with the starting points of the
        %other. No need to resample the fibers.

        firstpoints=cellfun(@(x) x(:, 1), fg.fibers, 'UniformOutput',false);
        lastpoints=cellfun(@(x) x(:, end), fg.fibers, 'UniformOutput',false);
        firstpoints=horzcat(firstpoints{:});
        lastpoints=horzcat(lastpoints{:});


        T = clusterdata([firstpoints lastpoints]', 'maxclust', 2);
        Tstart=T(1:end/2); Tend=T(end/2+1:end);
        figure; plot3(firstpoints(1, :),firstpoints(2, :), firstpoints(3, :), 'rx');  hold on; plot3(lastpoints(1, :),lastpoints(2, :), lastpoints(3, :), 'bo');

        %Take first and last points in every fibers and cluster together. The two
        %clouds should be quite separate for a tract with distinct termination
        %ROIs. Looking at the labels for the start points, keep fibers
        %corresponding to classlabel=1 intact. Swap the node order for the fibers
        %corresponding to classlabel=2;
        maxnumNodes=max(cellfun(@length, fg.fibers));
        nfibers=length(fg.fibers);

        curves=zeros(3, maxnumNodes, nfibers)*NaN;
        for fID=1:length(fg.fibers)
            curves(:, 1:size(fg.fibers{fID}, 2), fID)= fg.fibers{fID};
        end

        if ~(sum(Tstart==2)==nfibers | sum(Tstart==1)==nfibers)
            if sum(Tstart==2)<sum(Tstart==1)
                curves(:, :, Tstart==2)=flipdim(curves(:, :, Tstart==2), 2);
                display(['Flipped ' num2str(sum(Tstart==2)) ' fibers of ' num2str(nfibers)]);
            else
                curves(:, :, Tstart==1)=flipdim(curves(:, :, Tstart==1), 2);
                display(['Flipped ' num2str(sum(Tstart==1)) ' fibers of ' num2str(nfibers)]);
            end
        end
        for fID=1:length(fg.fibers)
            fg_reoriented.fibers{fID,1}=curves(:, :, fID);
            fg_reoriented.fibers{fID, 1}(:,isnan(curves(1, :, fID)))=[]; %This is a hack -- assuming if X is NAN y and z are not saveable. If y or z is NaN, this woont fly.
        end

        firstpoints=cellfun(@(x) x(:, 1), fg_reoriented.fibers, 'UniformOutput',false);
        lastpoints=cellfun(@(x) x(:, end), fg_reoriented.fibers, 'UniformOutput',false);
        firstpoints=horzcat(firstpoints{:});
        lastpoints=horzcat(lastpoints{:});

        figure; plot3(firstpoints(1, :),firstpoints(2, :), firstpoints(3, :), 'rx');  hold on; plot3(lastpoints(1, :),lastpoints(2, :), lastpoints(3, :), 'bo');

    otherwise

end


return

%figure; plot3((squeeze(curves(1, 1, Tstart==1))), (squeeze(curves(2, 1, Tstart==1))), (squeeze(curves(3, 1, Tstart==1))), 'rx');
%hold on; plot3((squeeze(curves(1, end, Tend==1))), (squeeze(curves(2, end, Tend==1))), (squeeze(curves(3, end, Tend==1))), 'rx');
%plot3((squeeze(curves(1, 1, Tstart==2))), (squeeze(curves(2, 1, Tstart==2))), (squeeze(curves(3, 1, Tstart==2))), 'bx');
%hold on; plot3((squeeze(curves(1, end, Tend==2))), (squeeze(curves(2, end, Tend==2))), (squeeze(curves(3, end, Tend==2))), 'bx');




% Testing after fixing orientation
%
% mumu=[]
% for i=1:size(fg.fibers, 1)
% mumu=[mumu; dtiFiberResample(fg.fibers{i}, numNodes)];
% end
% mumuR=[];
% for i=1:size(fg_reoriented.fibers, 1)
% mumuR=[mumuR; dtiFiberResample(fg_reoriented.fibers{i}, numNodes)];
% end
%
%  figure;
% for fib=1:89
%  hold on; plot3(mumu(1*fib, :), mumu(2*fib, :), mumu(3*fib, :), 'g');
%  hold on; plot3(mumu(1*fib, 1), mumu(2*fib, 1), mumu(3*fib, 1), 'rx');
%  hold on; plot3(mumu(1*fib, 15), mumu(2*fib, 15), mumu(3*fib, 15), 'bx');
%
% end
%
% %
%
%  figure;
% for fib=1:89
%  hold on; plot3(mumuR(1*fib, :), mumuR(2*fib, :), mumuR(3*fib, :), 'g');
%  hold on; plot3(mumuR(1*fib, 1), mumuR(2*fib, 1), mumuR(3*fib, 1), 'rx');
%  hold on; plot3(mumuR(1*fib, 15), mumuR(2*fib, 15), mumuR(3*fib, 15), 'bx');
%
% end
