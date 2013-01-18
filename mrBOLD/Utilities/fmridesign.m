
function X_cache=fmridesign(frametimes,slicetimes, ...
                            events,S,exclude,hrf_parameters)

%FMRIDESIGN
%
% Produces a set of design matrices, one for each slice, for fmristat. 
% With just the frametimes, it gives the hemodynamic response function.
%
% X_CACHE = FMRIDESIGN( FRAME_TIMES [, SLICE_TIMES [, EVENTS , [S , 
%                       [, EXCLUDE [, HRF_PARAMETERS ]]]]] )
% 
% FRAME_TIMES is a row vector of frame acquisition times in seconds. 
% 
% SLICE_TIMES is a row vector of relative slice acquisition times,
% i.e. absolute acquisition time of a slice is FRAME_TIMES + SLICE_TIMES.
% Default is 0.
% 
% EVENTS is a matrix whose rows are events and whose columns are:
% 1. id - an integer from 1:(number of events) to identify event type;
% 2. times - start of event, synchronised with frame and slice times;
% 3. durations (optional - default is 0) - duration of event;
% 4. heights (optional - default is 1) - height of response for event.
% For each event type, the response is a box function starting at the event 
% times, with the specified durations and heights, convolved with the 
% hemodynamic response function (see below). If the duration is zero, the 
% response is the hemodynamic response function whose integral is 
% the specified height - useful for `instantaneous' stimuli such as visual 
% stimuli. The response is then subsampled at the appropriate frame and slice
% times to create a design matrix for each slice, whose columns correspond
% to the event id number. EVENT_TIMES=[] will ignore event times and just 
% use the stimulus design matrix S (see next). Default is [1 0].
% 
% S: Events can also be supplied by a stimulus design matrix, 
% whose rows are the frames, and column are the event types. Events 
% are created for each column, beginning at the frame time for each row
% of S, with a duration equal to the time to the next frame, and a height
% equal to the value of S for that row and column. Note that a
% constant term is not usually required, since it is removed by the
% polynomial trend terms provided N_POLY>=0. Note that all values for
% all frames must be supplied, because smoothing and lagging by the
% hemodynamic resonse is done BEFORE excluding time points by EXCLUDE.
% Default is [].
% 
% EXCLUDE is a list of frames that should be excluded from the
% analysis. This must be used with Siemens EPI scans to remove the
% first few frames, which do not represent steady-state images.
% Default is [].
% 
% HRF_PARAMETERS is a matrix whose rows are 6 parameters for the 
% hemodynamic response function, one row for each event type and column
% of S (if there is just one row, this is repeated as necessary). 
% The hrf is modeled as the difference of two 
% gamma density functions (Glover, NeuroImage, 9:416-429). 
% The components of HRF_PARAMETERS are:
% 1. PEAK1: time to the peak of the first gamma density;
% 2. FWHM1: approximate FWHM of the first gamma density;
% 3. PEAK2: time to the peak of the second gamma density;
% 4. FWHM2: approximate FWHM of the second gamma density;
% 5. DIP: coefficient of the second gamma density;
%    Final hrf is:   gamma1/max(gamma1)-DIP*gamma2/max(gamma2)
%    scaled so that its total integral is 1. 
% 6. FIT_SCALE: 1 - fit the time scale of the hrf by convolving its 
%    derivative with the specified column of the design matrix, to create an
%    additional column for the design matrix. Dividing the effect
%    of this column by the effect of the hrf itself estimates the
%    scale shift. 0 ignores this option.
% If PEAK1=0 then there is no smoothing of that event type with the hrf.
% Default is: [5.4 5.2 10.8 7.35 0.35 0] chosen by Glover (1999) for 
% an auditory stimulus. 
% 
% X_CACHE: A cache of the design matrices; rows are the non-excluded frames, 
% columns are all the regressor variables, with slices running slowest.

%############################################################################
% COPYRIGHT:   Copyright 2000 K.J. Worsley and C. Liao, 
%              Department of Mathematics and Statistics,
%              McConnell Brain Imaging Center, 
%              Montreal Neurological Institute,
%              McGill University, Montreal, Quebec, Canada. 
%              worsley@math.mcgill.ca, liao@math.mcgill.ca
%
%              Permission to use, copy, modify, and distribute this
%              software and its documentation for any purpose and without
%              fee is hereby granted, provided that the above copyright
%              notice appear in all copies.  The author and McGill University
%              make no representations about the suitability of this
%              software for any purpose.  It is provided "as is" without
%              express or implied warranty.
%############################################################################

% Defaults:

if nargin < 2
   slicetimes=0
end
if nargin < 3
   events=[1 0]
end
if nargin < 4
   S=[]
end
if nargin < 5
   exclude=[]
end
if nargin < 6
   hrf_parameters=[5.4 5.2 10.8 7.35 0.35 0]
end

numframes=length(frametimes);
numslices=length(slicetimes);

% Keep time points that are not excluded:

allpts = 1:numframes;
allpts(exclude) = zeros(1,length(exclude));
keep = allpts( find( allpts ) );
n=length(keep);
scantimes=frametimes(keep);

if ~isempty(events)
   numevents=size(events,1);
   eventid=events(:,1);
   numeventypes=max(eventid);
   eventime=events(:,2);
   if size(events,2)>=3
      duration=events(:,3);
   else
      duration=zeros(numevents,1);
   end
   if size(events,2)>=4
      height=events(:,4);
   else
      height=ones(numevents,1);
   end
   mineventime=min(eventime);
   maxeventime=max(eventime+duration);
else
   numeventypes=0;
   mineventime=Inf;
   maxeventime=-Inf;
end

if ~isempty(S)
   numcolS=size(S,2);
else
   numcolS=0;
end

% Set up response matrix:

dt=0.02;
  startime=min(mineventime,min(frametimes)+min([slicetimes 0]));
finishtime=max(maxeventime,max(frametimes)+max([slicetimes 0]));
numtimes=ceil((finishtime-startime)/dt)+1;
numresponses=numeventypes+numcolS;
response=zeros(numtimes,numresponses);

if ~isempty(events)
   height=height./(1+(duration==0)*(dt-1));
   for k=1:numevents
      type=eventid(k);
      n1=ceil((eventime(k)-startime)/dt)+1;
      n2=ceil((eventime(k)+duration(k)-startime)/dt)+(duration(k)==0);
      if n2>=n1
         response(n1:n2,type)=response(n1:n2,type)+height(k)*ones(n2-n1+1,1);
      end
   end
end

if ~isempty(S)
   for j=1:numcolS
      for i=find(S(:,j)')
         n1=ceil((frametimes(i)-startime)/dt)+1;
         if i<numframes
            n2=ceil((frametimes(i+1)-startime)/dt);
         else
            n2=numtimes;
         end
         if n2>=n1 
            response(n1:n2,numeventypes+j)= ...
               response(n1:n2,numeventypes+j)+S(i,j)*ones(n2-n1+1,1);
         end
      end
   end
end

% Set hrf parameters:

numscale=0;
for k=1:numresponses
   if k<=size(hrf_parameters,1)
      if hrf_parameters(k,1)>0
         peak1=hrf_parameters(k,1);
         fwhm1=hrf_parameters(k,2);
         peak2=hrf_parameters(k,3);
         fwhm2=hrf_parameters(k,4);
         dip=hrf_parameters(k,5);
         alpha1=peak1^2/fwhm1^2*8*log(2);
         alpha2=peak2^2/fwhm2^2*8*log(2);
         beta1=fwhm1^2/peak1/8/log(2);
         beta2=fwhm2^2/peak2/8/log(2);
         
         numlags=ceil(max(peak1+2*fwhm1,peak2+2*fwhm2)/dt);
         time=(0:(numlags-1))'*dt;
         gamma1=(time/peak1).^alpha1.*exp(-(time-peak1)./beta1);
         gamma2=(time/peak2).^alpha2.*exp(-(time-peak2)./beta2);
         hrf=gamma1-dip*gamma2;
         sumhrf=sum(hrf);
         hrf=hrf/sumhrf;
         if hrf_parameters(k,6)==1
            fit_scale=1;
            d_hrf=((time/beta1-alpha1-1).*gamma1- ...
               dip*(time/beta2-alpha2-1).*gamma2);
            d_hrf=d_hrf/sumhrf;
         else
            fit_scale=0;
         end
      else
         fit_scale=0;
         hrf=1;
      end
   end
   eventmatrix(:,k)=conv2(response(:,k),hrf);
   if fit_scale==1
      numscale=numscale+1;
      eventmatrix(:,numresponses+numscale)=conv2(response(:,k),d_hrf);
   end
end

% Make all the design matrices for each slice:

numcolX=numresponses+numscale;
X_cache=zeros(n,numcolX*numslices);
for slice = 1:numslices
   subtime=floor((scantimes+slicetimes(slice)-startime)/dt)+1;
   X_cache(:,(1:numcolX)+(slice-1)*numcolX)=eventmatrix(subtime,:);
end

% End.
