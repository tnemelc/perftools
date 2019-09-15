% dispOptimResInFeatSpace.m
% brief: 
%
%
% references:
%
%
% input:
% arg1: ...
% arg2: ... 
% output:
%
% arg3: ...
% arg4: ...
%
%
% keywords:
% author: C.Daviller
% date: 28-Oct-2017  


 function [arg3, arg4] = dispOptimResInFeatSpace(path, dimensionsNameKS)
     if ~nargin
        dispOptimResInFeatSpaceUI();
     return;
     end 
 
    for k = 1 : 3 %feture number
        featuresTab(:, k) = loadmat(fullfile(path, char(dimensionsNameKS(k))));
    end
 
%     FirstROISurface = loadmat(fullfile(path, 'FirstROISurface'));
%     AUC = loadmat(fullfile(path, 'AUC'));
%     ttp = loadmat(fullfile(path, 'ttp'));
    
    
    %dimvectorTab = [dimvectorTab; AUC; ttp];

    dimVectorTab = [ttp(:, 1)'; FirstROISurface(:, 1)'; AUC(:, 1)'];
    displayFeaturesSpace(dimVectorTab, dimensionsNameKS, '-m');
    dimVectorTab = [ttp(:, 2)'; FirstROISurface(:, 2)'; AUC(:, 2)'];
    displayFeaturesSpace(dimVectorTab, dimensionsNameKS, '-c');
    dimVectorTab = [ttp(:, 3)'; FirstROISurface(:, 3)'; AUC(:, 3)'];
    displayFeaturesSpace(dimVectorTab, dimensionsNameKS, '-k');

end