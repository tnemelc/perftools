% refSegmentationDisplay.m
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
% date: 24-Oct-2017  


 function ticFeatures = refSegmentationDisplay(path, tissueClass)
 if ~nargin
	refSegmentationDisplayUI();
 return;
 end 
 slcKS = {'apex', 'mid', 'base'};
 slcPk = 27;
 

for k = 1 : 3
    imSerie(:, :, :, k)= loadDcm(fullfile(path, char(slcKS(k))));
    [H, W, T, S] = size(imSerie);
    try
        mask(:, :, k) = loadmat(fullfile(path, 'segmentation', tissueClass, char(slcKS(k)), 'labeledImg001.mat'));
    catch
        mask(:, :, k) = zeros(H, W);
    end
    
    opt.lwTCrop = 4;
    opt.upTCrop = 50;
    if ~max(max(mask(:, :, k)))
        ticFeatures(:, k) = [-1; -1; -1];
    else
        ticFeatures(:, k) = getTICFeatures(calculateRoiAvgCurve(mask(:, :, k), imSerie(:, :, :, k), opt), mask);
    end
    
    figureMgr.getInstance.newFig(char(slcKS(k)));
    imagesc(overlay(correctContrastnBrightess(imSerie(:, :, slcPk, k), 1.4, 0), mask(:, :, k)));
    axis off image;
    
end

%% inner functions

     function ticFeatures = getTICFeatures(curve, mask)
         ticFeatures = ...
             [find(curve == max(curve), 1, 'first');% TTP
                length(mask(mask==1));% region surface
                sum(curve)]; % AUC
     end

     function avgCurve = calculateRoiAvgCurve(roiMask, imSerie, opt)
        [H, W, T] = size(imSerie);
        
        pos = find(roiMask == 1);
        [x, y] = ind2sub([H, W], pos);
        avgCurve = zeros(1, T);
        
        tmp = 0;
        for n = 1 : length(x)
            tmp = tmp + squeeze(imSerie(x(n), y(n), opt.lwTCrop:opt.upTCrop));
        end
        avgCurve = tmp ./ length(x);
        
    end
 
 
end