% pseudoPrepareClinicalData.m
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


 function pseudoPrepareClinicalData(rootPath)
    if ~nargin
        pseudoPrepareClinicalDataUI();
        return;
    end
    
    isKS = {'base', 'mid', 'apex'};

    for k = 1 : length(isKS)
        isPath   = fullfile(rootPath, isKS{k}, 'tmp', '02_images');
        savePath = fullfile(rootPath, 'dataPrep', isKS{k});
        emptyDir(savePath);
        imSerie = loadDcm(isPath);
        dcmInfo = getDicomInfoList(isPath);
        
        for m = 1 : length(dcmInfo)
            tAcqStr(m, :) = dcmInfo(m).AcquisitionTime;
        end
        tAcq = getAcqTimes(tAcqStr) .* 1e-3;
        
        myoMask = extractMyo(imSerie, 25, false, isKS{k});
        savemat(fullfile(savePath, 'tAcq'), tAcq);
        savemat(fullfile(savePath, 'mask'), myoMask);
        savemat(fullfile(savePath, 'slcSerie'), imSerie);
    end

end