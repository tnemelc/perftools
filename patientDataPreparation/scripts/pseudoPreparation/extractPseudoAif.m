% extractPseudoAif.m
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
% date: 03-Jul-2018  


 function [aif, tAcq, aifPeakPosition, PDScanNber, aifMask, thresh] = extractPseudoAif(dataPath)
     if ~nargin
        extractPseudoAifUI();
        return;
     end 
     
     imSerie = loadDcm(dataPath);
     dcmInfo = getDicomInfoList(dataPath);
     
     for k = 1 : length(dcmInfo)
         tAcqStr(k, :) = dcmInfo(k).AcquisitionTime;
     end
     tAcq = getAcqTimes(tAcqStr) .* 1e-3;
     %reduce image size
     ldImSerie = nan(64, 64, size(imSerie, 3));
     for m = 1 : size(imSerie, 3)
         ldImSerie(:, :, m) = imresize(imSerie(:, :, m), [64, 64]);
     end
    [aif, aifPeakPosition, PDScanNber, aifMask, thresh] = extractAif(ldImSerie);
    
    
     
end