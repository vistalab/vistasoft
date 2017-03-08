function colors = colorSamples(lst)
%
% lst:  A vector of integers between 1 and 20 to draw some samples
%
% RF/BW

% Check parameters

% This is static.
% This is a good list of colors that Renzo made from D3.  We use these for
% various tasks like selecting the fiber colors
colorList = [ ...
    31   119   180
    174   199   232
    255   127    14
    255   187   120
    44   160    44
    152   223   138
    214    39    40
    255   152   150
    148   103   189
    197   176   213
    140    86    75
    196   156   148
    227   119   194
    247   182   210
    127   127   127
    199   199   199
    188   189    34
    219   219   141
    23   190   207
    158   218   229];

% Here they are
colors = colorList(lst,:);
end
