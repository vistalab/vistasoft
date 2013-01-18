function [n_signif,index_signif] = fdr(pvals,qlevel,method,adjustment_method,adjustment_args)
% Determine significance based on a false discovery rate (FDR) method
%
%  [n_signif,index_signif] = ...
%     fdr(pvals,qlevel,method,adjustment_method,adjustment_args)
%
% This is the main function designed for general usage for determining
% significance based on the FDR approach. The specific method used depends
% on the calling parameters.
%
% Arguments:
%
%   pvals:  a vector of pvals on which to conduct the multiple testing
%
%   qlevel: the proportion of false positives desired
%
%   method: method for performing the testing.  'original' follows
%   Benjamini & Hochberg (1995); 'general' is much more
%   conservative, requiring no assumptions on the p-values (see
%   Benjamini & Yekutieli (2001)).  We recommend using 'original',
%   and if desired, using 'adjustment.method="mean" ' to increase
%   power.
%
%   adjustment_method: method for increasing the power of the
%   procedure by estimating the proportion of alternative p-values,
%   one of 'mean', the modified Storey estimator that we suggest in
%   Ventura et al. (2004), 'storey', the method of Storey (2002),
%   or 'two-stage', the iterative approach of Benjamini et
%   al. (2001)
%
%   adjustment_args: arguments to adjustment.method; see prop_alt()
%   for description, but note that for 'two-stage', qlevel and
%   fdr_method are taken from the qlevel and method arguments to
%   fdr()
%
% Value:
%
%   index_signif:  a vector of the indices of the significant tests
%   or NA if no significant tests
%
%   n_signif: number of significant tests
%
% Examples:
%
%   signif <- fdr(pvals,method='original',adjustment.method='mean')
%
%  References:
%             Ventura, V., C.J. Paciorek, and J.S. Risbey.  2004.
%             Controlling the proportion of falsely-rejected
%             hypotheses when conducting multiple tests with
%             climatological data.  Journal of Climate, in press.
%             Also Carnegie Mellon University, Department of
%             Statistics technical report 775
%             (www.stat.cmu.edu/tr/tr775/tr775.html).
%
%             Benjamini, Y, and Y. Hochberg. 1995. Controlling the
%             false discovery rate: a practical and powerful
%             approach to multiple testing.  JRSSB 57:289-300.
%
%             Benjamini, Y. and D. Yekutieli.  2001.  The control
%             of the false discovery rate in multiple testing under
%             dependency. Annals of Statistics 29:1165-1188.
%
%             Benjamini, Y., A. Krieger, and D. Yekutieli.  2001.
%             Two staged linear step up FDR controlling procedure.
%             Technical Report, Department of Statistics and
%             Operations Research, Tel Aviv University.  URL:
%             http://www.math.tau.ac.il/~ybenja/Papers.html
%
%             Storey, J. 2002.  A direct approach to false discovery rates.  JRSSB 64: 479-498.
%
% Attribution:
%
%    Version 0.1.3;  May 10, 2004
%
%    License: GPL version 2 or later
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
%
%    Author: Chris Paciorek - please contact the author with bug
%    reports: paciorek AT alumni.cmu.edu
%

if exist('isfield') % matlab
    endline='';
else % octave
    endline='\n';
end

n = length(pvals);

a = 0;   % initialize proportion of alternative hypotheses
if nargin<2
    error(['pvals and qlevel are required arguments',endline]);
end
if nargin==2
    method='original';
end
if nargin>=4 && ~isempty(adjustment_method)
    if strcmp(adjustment_method,'two-stage')  % set things up for the "two-stage" estimator
        qlevel = qlevel/(1+qlevel);   % see Benjamini et al. (2001) for proof that this controls the FDR at level qlevel
        adjustment_args.qlevel = qlevel;
        adjustment_args.fdr_method = method;
        %fprintf(['Adjusting cutoff using two-stage approach with fdr ', ...
        %    'method %s and qlevel %.3f\n'],adjustment_args.fdr_method,...
        %    adjustment_args.qlevel);
    end
    if strcmp(adjustment_method,'mean') & nargin==4  % default arguments for "mean" method of Ventura et al. (2004)
        adjustment_args.edf_lower=0.8;
        adjustment_args.num_steps=20;
        %fprintf(['Adjusting cutoff using mean approach with edf_lower=0.8 ', ...
        %    'and num_steps=20\n']);
    end
    if strcmp(adjustment_method,'storey') & nargin==4
        error(['adjustment_args.edf_quantile not specified for Storey ', ...
            'adjustment',endline]);
    end
    a = prop_alt(pvals,adjustment_method,adjustment_args);
end
if a==1    % all hypotheses are estimated to be alternatives
    index_signif=1:n;
    n_signif=n;
else      % adjust for estimate of a; default is 0
    qlevel = qlevel/(1-a);
    [n_signif,index_signif]=fdr_master(pvals,qlevel,method);
end


function [n_signif,index_signif] = fdr_master(pvals,qlevel,method)
%
% Description:
%
%    This is an internal function that performs various versions of
%    the FDR procedure, but without the modification described in
%    section 4 of Ventura et al. (2004)
%
% Arguments:
%
%   pvals (required):  a vector of pvals on which to conduct the multiple testing
%
%   qlevel: the proportion of false positives desired
%
%   method: one of 'original', the original method of Benjamini &
%   Hochberg (1995), or 'general', the method of Benjamini &
%   Yekutieli (2001), which requires no assumptions about the
%   p-values, but which is much more conservative.  We recommend
%   'original' for climatological data, and suspect it works well
%   generally for spatial data.
%
% Value:
%
%   index_signif:  a vector of the indices of the significant tests
%   or NA if no significant tests
%
%   n_signif: number of significant tests
%
%
if nargin==2
    method='original';
end
n = length(pvals);
if strcmp(method,'general')
    qlevel = qlevel/sum(1./(1:n));  % This requires fewer assumptions but is much more conservative
else
    if(~strcmp(method,'original'))
        error('No method of type: %s\n',method);
    end
end
[n_signif,index_signif] = fdr_basic(pvals,qlevel);



function [n_signif,index_signif] = fdr_basic(pvals,qlevel)
%
% Description:
%
%    This is an internal function that performs the basic FDR of Benjamini & Hochberg (1995).
%
% Arguments:
%
%   pvals:  a vector of pvals on which to conduct the multiple testing
%
%   qlevel: the proportion of false positives desired
%
% Value:
%
%   index_signif:  a vector of the indices of the significant tests
%   or NA if no significant tests
%
%   n_signif: number of significant tests
%
n = length(pvals);
if n>1 & size(pvals,2)==1
    pvals=pvals';
end
[sorted_pvals,sort_index] = sort(pvals);
indices = (1:n).*(sorted_pvals<=qlevel*(1:n)/n);
n_signif = max(indices);
if(n_signif)
    indices = 1:n_signif;
    index_signif=sort(sort_index(indices));
else
    index_signif=nan;
end


function [a] = storey(edf_quantile,pvals)
%
% Description:
%
%    This is an internal function that calculates the basic Storey
%    (2002) estimator of a, the proportion of alternative
%    hypotheses.
%
% Arguments:
%
%   edf_quantile (required):  the quantile of the empirical
%   distribution function at which to estimate a
%
%   pvals (required):  a vector of pvals on which to estimate a
%
% Value:
%
%   a: estimate of a, the number of alternative hypotheses
%
%
if exist('isfield') % matlab
    endline='';
else % octave
    endline='\n';
end
if edf_quantile >= 1 | edf_quantile <=0
    error(['edf_quantile should be between 0 and 1',endline]);
end
a = (mean(pvals<=edf_quantile)-edf_quantile)/(1-edf_quantile);
if(a<0)
    a=0;
end




function [a] = prop_alt(pvals,adjustment_method,adjustment_args)
%
% Description:
%
%    This is an internal function that calculates an estimate of a,
%    the proportion of alternative hypotheses, using one of several
%    methods.
%
% Arguments:
%
%   pvals (required):  a vector of pvals from which to estimate a
%
%   adjustment_method: method for  estimating the proportion of
%   alternative p-values, one of "mean", the modified Storey
%   estimator suggested in Ventura et al. (2004); "storey", the
%   method of Storey (2002); or "two-stage", the iterative approach
%   of Benjamini et al. (2001)
%
%   adjustment_args: arguments to adjustment.method;
%
%      for 'mean', specify edf_lower, the smallest quantile at
%      which to estimate a, and num_steps, the number of quantiles
%      to use - the approach uses the average of the Storey (2002)
%      estimator for the num.steps quantiles starting at edf.lower
%      and finishing just less than 1
%
%      for 'storey', specify edf_quantile, the quantile at which to
%      calculate the estimator
%
%      for 'two-stage', the method uses a standard FDR approach to
%      estimate which p-values are significant; this number is the
%      estimate of a; therefore the method requires specification
%      of qlevel, the proportion of false positives and fdr.method
%      ('original' or 'general'), the FDR method to be used.  We do
%      not recommend 'general' as this is very conservative and
%      will underestimate a.

%
% Value:
%
%   a:  estimate of a, the number of alternative hypotheses
%
% Examples:
%
%   a = prop_alt(pvals,'mean')
%
if exist('isfield') % matlab
    endline='';
else % octave
    endline='\n';
end

stop=0;
n = length(pvals);
if strcmp(adjustment_method,'two-stage')
    if ~exist('adjustment_args')
        stop=1;
    else
        if exist('isfield')  % check if in Matlab
            if ~(isfield(adjustment_args,'qlevel') & ...
                    isfield(adjustment_args,'fdr_method'))
                stop=1;
            end
        else  % in octave
            if ~(struct_contains(adjustment_args,'qlevel') & ...
                    struct_contains(adjustment_args,'fdr_method'))
                stop=1;
            end
        end
    end
    if stop
        error(['adjustment_args.qlevel or adjustment_args.fdr_method ', ...
            'not specified.  Two-stage estimation of the number ',...
            'of alternative hypotheses requires specification of ', ...
            'the  FDR threshold and FDR method',endline]);
    end
    [n_signif,index_signif]=fdr_master(pvals,adjustment_args.qlevel,...
        adjustment_args.fdr_method);
    a=n_signif/n;
end
if strcmp(adjustment_method,'storey')
    if ~(exist('adjustment_args'))
        stop=1;
    else
        if exist('isfield')  % check if in Matlab
            if ~(isfield(adjustment_args,'edf_quantile'))
                stop=1;
            end
        else  % octave
            if ~(struct_contains(adjustment_args,'edf_quantile'))
                stop=1;
            end
        end
    end
    if stop
        error(['adjustment_args.edf_quantile not specified. Using method of Storey for estimating  the number of alternative hypotheses requires specification of the argument of the p-value EDF at which to do the estimation (a number close to one is recommended)',endline]);
    end
    a=storey(adjustment_args.edf_quantile,pvals);
end

if strcmp(adjustment_method,'mean')
    if ~(exist('adjustment_args'))
        stop=1;
    else
        if exist('isfield')  % check if in Matlab
            if ~(isfield(adjustment_args,'edf_lower') & ...
                    isfield(adjustment_args,'num_steps'))
                stop=1;
            end
        else % octave
            if ~(struct_contains(adjustment_args,'edf_lower') & ...
                    struct_contains(adjustment_args,'num_steps'))
                stop=1;
            end
        end
    end
    if stop
        error(['adjustment_args.edf_lower or adjustment_args.num_steps ' ...
            'is not specified. Using the method of Ventura et al. (2004) for estimating  the number of alternative hypotheses requires specification of the lowest quantile of the p-value EDF at which to do the estimation (a number close to one is recommended) and the number of steps between edf_lower and 1, starting at edf_lower, at which to do the estimation',endline])
    end
    if adjustment_args.edf_lower >=1 | adjustment_args.edf_lower<=0
        error(['adjustment_args.edf_lower must be between 0 and 1',endline]);
    end
    if adjustment_args.num_steps<1 | ~(rem(adjustment_args.num_steps,1)==0)
        error(['adjustment_args.num_steps must be an integer greater than 0',endline]);
    end
    stepsize = (1-adjustment_args.edf_lower)/adjustment_args.num_steps;
    edf_quantile=adjustment_args.edf_lower;
    a_vec=storey(edf_quantile,pvals);
    for step=1:adjustment_args.num_steps
        a_vec(step)=storey(edf_quantile,pvals);
        edf_quantile=edf_quantile+stepsize;
    end
    a=mean(a_vec);
end
