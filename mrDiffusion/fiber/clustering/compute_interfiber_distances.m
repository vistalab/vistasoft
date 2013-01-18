function compute_interfiber_distances(infile, npoints, method, range1start, range1end, range2start,  range2end, saveflag)
%function compute_interfiber_distances(infile, npoints, method, range1, range2, [saveflag=0])

%compute interfiber distances for fg.fibers structures in infile.mat 
%save distance matrix into outfile. Range1 ([Nfrst Nlasst]) and range2 specify groups of fibers among which the distances should be computed. 
%ER 12/2007 Infile: use prefix. range1/2start/end: supply as a string.
%(e.g., '5') -- needed for later to pass bash string arguments. 
%Set saveflag to 1 if want matrix of interfiberr distances saved. 

if(~exist('saveflag','var')||isempty(saveflag))
    saveflag = false;
end

if(isnumeric(range1start)) range1start=num2str(range1start); end
    if(isnumeric(range2start)) range2start=num2str(range2start); end
        if(isnumeric(range1end)) range1end=num2str(range1end); end
            if(isnumeric(range2end)) range2end=num2str(range2end); end 
                        if(ischar(npoints)) npoints=str2num(npoints); end 
load(infile); 
range1start=min(max(str2num(range1start), 1), size(fg.fibers, 1));
range2start=min(max(str2num(range2start), 1), size(fg.fibers, 1)) ;

range1end=max(min(str2num(range1end), size(fg.fibers, 1)), range1start);
range2end=max(min(str2num(range2end), size(fg.fibers, 1)), range2start) ;

display(['Data: ' infile ]); 
display(['Resampling each fiber to: ' num2str(npoints) ' nodes']); 
display(['Distance metric: ' method ]); 
display(['Fibergroups analyzed: ' num2str(range1start) ' to ' num2str(range1end) ' and ' num2str(range2start) ' to ' num2str(range2end)]);


fibergroup1=fg.fibers(range1start:range1end);
fibergroup2=fg.fibers(range2start:range2end);    

clear fg; 

if (range1start==range2start&range1end==range2end)
    display('One fiber group found');
    tic; distmsr =  InterfiberDistances(fibergroup1, npoints, method);  toc; 
 
else
    display('Two distinct fiber groups found');
tic; distmsr =  InterfiberDistances(fibergroup1, fibergroup2, npoints, method);  toc; 
end

if (saveflag)
outfile=[prefix(infile) 'dist' num2str(range1start) 'to' num2str(range1end) 'vs' num2str(range2start) 'to' num2str(range2end) method '.mat'];
save(outfile, 'distmsr', 'fibergroup1', 'fibergroup2', 'infile', 'range1start', 'range2start', 'range1end', 'range2end', 'method', 'npoints', '-v7.3'); 
end
