% SegToolOptimizerRelative.m
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
% date: 23-Oct-2017  


 function [arg3, arg4] = SegToolOptimizerRelative(dataPath)
 if ~nargin
	SegToolOptimizerRelativeUI();
 return;
 end 
close all;
fm = figureMgr.getInstance();

opt.xScale = 0;
opt.yScale = 0;
opt.merge = 0;
opt.lwTCrop = 4;
opt.upTCrop = 70;
opt.seedCriterion = 'min_area_under_curve';
opt.thresholdType = 'percentage';

nbIt  = 40;
pkImg = 29;

step = 5; %percentage of scale

apex = 1;
mid  = 2;
base = 3;

slcSerieApex = loadDcm(fullfile(dataPath, 'apex'));
slcSerieMid  = loadDcm(fullfile(dataPath, 'mid'));
slcSerieBase = loadDcm(fullfile(dataPath, 'base'));


fm.newFig('peakImg');
subplot(1, 3, apex); imagesc(slcSerieApex(:, :, pkImg));  title('apex'); axis off image; colormap gray;
subplot(1, 3, mid);  imagesc(slcSerieMid(:, :, pkImg));   title('mid'); axis off image; colormap gray;
subplot(1, 3, base); imagesc(slcSerieBase(:, :, pkImg));  title('base'); axis off image; colormap gray;

plotLegend = {};
for k = 1 : nbIt
    opt.rScale = k * step;
    plotLegend = [plotLegend, num2str(k)];
    segTool = SegmentationToolAutoTempRegionGrowing();
    segTool.prepare(dataPath, opt);
    segTool.run();
    labeledImg(:, :, apex) = segTool.getLabledSlcImg('apex');
    labeledImg(:, :, mid) = segTool.getLabledSlcImg('mid');
    labeledImg(:, :, base) = segTool.getLabledSlcImg('base');
    
%     fm.newFig(['iteration_' num2str(k) '_overlay']);
%     
%     subplot(1,3, apex); imagesc(overlay(slcSerieApex(:,:,25), labeledImg(:, :, apex), 'jet')); title('apex'); axis off image;
%     subplot(1,3, mid); imagesc(overlay(slcSerieMid(:,:,25), labeledImg(:, :, mid), 'jet')); title('mid'); axis off image;
%     subplot(1,3, base); imagesc(overlay(slcSerieBase(:,:,25), labeledImg(:, :, base), 'jet')); title('base'); axis off image;

    
    nbROI(k, apex) = max(max(labeledImg(:, :, apex)));
    nbROI(k, mid) =  max(max(labeledImg(:, :, mid)));
    nbROI(k, base) = max(max(labeledImg(:, :, base)));
    
    %apex
    mask = labeledImg(:, :, apex);
    mask(mask ~=1 ) = 0;
    FirstROISurface(k, apex) = sum(mask(mask==1));
    avgTimeCurve = calculateRoiAvgCurve(mask, slcSerieApex, opt);
    AUC(k, apex) = sum(avgTimeCurve);
    ttp(k, apex) = find(avgTimeCurve == max(avgTimeCurve(:)), 1, 'first');
    slope = diff(avgTimeCurve);
    maxSlope(k, apex) = max(slope);
    maxSlopePos(k, apex) = find(slope == max(slope), 1 , 'first');
    
    fm.newFig('averageTimeCurve apex ROI 1');
    subplot(211); hold all; plot(avgTimeCurve);
    title('averageTimeCurve apex ROI 1');    
    legend(plotLegend);
    subplot(212); hold all;
    plot(slope); title('slope');    
    
    %mid
    mask = labeledImg(:, :, mid);
    mask(mask ~=1 ) = 0;
    FirstROISurface(k, mid) = sum(mask(mask==1));
    avgTimeCurve = calculateRoiAvgCurve(mask, slcSerieMid, opt);
    AUC(k, mid) = sum(avgTimeCurve);
    ttp(k, mid) = find(avgTimeCurve == max(avgTimeCurve(:)), 1, 'first');
    slope = diff(avgTimeCurve);
    maxSlope(k, mid) = max(slope);
    maxSlopePos(k, mid) = find(slope == max(slope), 1 , 'first');
    
    fm.newFig('averageTimeCurve mid ROI 1');
    subplot(211); hold all; plot(avgTimeCurve);
    title('averageTimeCurve mid ROI 1');
    legend(plotLegend);
    subplot(212); hold all;
    plot(slope); title('slope');  
    
    %base
    mask = labeledImg(:, :, base);
    mask(mask ~=1 ) = 0;
    FirstROISurface(k, base) = sum(mask(mask==1));
    avgTimeCurve = calculateRoiAvgCurve(mask, slcSerieBase, opt);
    AUC(k, base) = sum(avgTimeCurve);
    ttp(k, base) = find(avgTimeCurve == max(avgTimeCurve(:)), 1, 'first');
    slope = diff(avgTimeCurve);
    maxSlope(k, base) = max(slope);
    maxSlopePos(k, base) = find(slope == max(slope), 1 , 'first');
    
    fm.newFig('averageTimeCurve base ROI 1');
    subplot(211); hold all; plot(avgTimeCurve);
    title('averageTimeCurve base ROI 1');
    legend(plotLegend);
    subplot(212); hold all;
    plot(slope); title('slope'); 
    
end


plotData('nbROIvsIt', nbROI);
plotData('AreaUnderCurvevsIt', AUC);
plotData('FirstROISurfacevsIt', FirstROISurface);
plotData('TimeToPeakvsIt', ttp);
plotData('maxSlopevsIt', maxSlope);
plotData('maxSlopePositionvsIt', maxSlopePos);




return;



% fm.saveAll(dataPath, 'pdf');


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



    function plotData(dataName, data)        
        fm.newFig(dataName); 
        subplot(211);hold all;
        plot(data(:, apex));
        plot(data(:, mid));
        plot(data(:, base));
        legend('apex', 'mid', 'base');
        title(dataName);
        
        subplot(212); hold all;
        plot(diff(data(:, apex)));
        plot(diff(data(:, mid)));
        plot(diff(data(:, base)));
        legend('apex', 'mid', 'base');
        title('derivative');
    end
end