% segToolOptimzerAbsolute.m
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
% date: 06-Oct-2017


function [featuresStruct, firstRoiMask] = segToolOptimzerAbsolute(dataPath)
if ~nargin
    segToolOptimzerAbsoluteUI();
    return;
end
close all;
fm = figureMgr.getInstance();

opt.xScale = 0;
opt.yScale = 0;
opt.merge = 0;
opt.lwTCrop = 4;
opt.upTCrop = 50;
opt.seedCriterion = 'min_area_under_curve';
opt.thresholdType = 'absolute';

nbIt  = 40;
pkImg = 29;

cMap = colormap(jet(nbIt));

apex = 3;
mid  = 2;
base = 1;

slcSerieApex = loadDcm(fullfile(dataPath, 'apex'));
slcSerieMid  = loadDcm(fullfile(dataPath, 'mid'));
slcSerieBase = loadDcm(fullfile(dataPath, 'base'));

[H, W, T] = size(slcSerieApex);

plotLegend = {};

firstRoiMask = zeros(H, W, 3);

for k = 1 : nbIt
    opt.rScale = k;
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
    
    firstRoiMask(:,:,apex) = updateFirstRoiMask(firstRoiMask(:,:,apex), mask, k);
    FirstROISurface(k, apex) = sum(mask(mask==1));
    avgTimeCurve = calculateRoiAvgCurve(mask, slcSerieApex, opt);
    AUC(k, apex) = sum(avgTimeCurve);
    ttp(k, apex) = find(avgTimeCurve == max(avgTimeCurve(:)), 1, 'first');
    slope = diff(avgTimeCurve);
    maxSlope(k, apex) = max(slope);
    maxSlopePos(k, apex) = find(slope == max(slope), 1 , 'first');
    peakValue(k, apex) = max(avgTimeCurve(:));
    
    fm.newFig('averageTimeCurve apex ROI 1');
    subplot(211); hold all; cplot(avgTimeCurve, cMap(k,:));
    title('averageTimeCurve apex ROI 1');    
    legend(plotLegend);
    subplot(212); hold all;
    cplot(slope, cMap(k,:)); title('slope');    
    
    %mid
    mask = labeledImg(:, :, mid);
    mask(mask ~=1 ) = 0;
    firstRoiMask(:, :, mid) = updateFirstRoiMask(firstRoiMask(:, :, mid), mask, k);
    FirstROISurface(k, mid) = sum(mask(mask==1));
    avgTimeCurve = calculateRoiAvgCurve(mask, slcSerieMid, opt);
    AUC(k, mid) = sum(avgTimeCurve);
    ttp(k, mid) = find(avgTimeCurve == max(avgTimeCurve(:)), 1, 'first');
    slope = diff(avgTimeCurve);
    maxSlope(k, mid) = max(slope);
    maxSlopePos(k, mid) = find(slope == max(slope), 1 , 'first');
    peakValue(k, mid) = max(avgTimeCurve(:));
    
    fm.newFig('averageTimeCurve mid ROI 1');
    subplot(211); hold all; cplot(avgTimeCurve, cMap(k,:));
    title('averageTimeCurve mid ROI 1');
    legend(plotLegend);
    subplot(212); hold all;
    cplot(slope, cMap(k,:)); title('slope');  
    
    %base
    mask = labeledImg(:, :, base);
    mask(mask ~=1 ) = 0;
    firstRoiMask(:, :, base) = updateFirstRoiMask(firstRoiMask(:, :, base), mask, k);
    baseMaskStack(:, :, k) = mask;
    FirstROISurface(k, base) = sum(mask(mask==1));
    avgTimeCurve = calculateRoiAvgCurve(mask, slcSerieBase, opt);
    AUC(k, base) = sum(avgTimeCurve);
    ttp(k, base) = find(avgTimeCurve == max(avgTimeCurve(:)), 1, 'first');
    slope = diff(avgTimeCurve);
    maxSlope(k, base) = max(slope);
    maxSlopePos(k, base) = find(slope == max(slope), 1 , 'first');
    peakValue(k, base) = max(avgTimeCurve(:));
    
    fm.newFig('averageTimeCurve base ROI 1');
    subplot(211); hold all; cplot(avgTimeCurve, cMap(k,:));
    title('averageTimeCurve base ROI 1');
    legend(plotLegend);
    subplot(212); hold all;
    cplot(slope, cMap(k,:)); title('slope'); 
    
end

fm.newFig('seeds');
firstSeedMask = segTool.getSeedsMask('apex'); firstSeedMask(firstSeedMask > 1) = 0;
subplot(1, 3, apex); imagesc(overlay(slcSerieApex(:, :, pkImg), firstSeedMask)); title('first ROI seed apex'); axis off image; colormap gray;
firstSeedMask = segTool.getSeedsMask('mid'); firstSeedMask(firstSeedMask > 1) = 0;
subplot(1, 3, mid);  imagesc(overlay(slcSerieMid(:, :, pkImg),  firstSeedMask));   title('first ROI seed mid'); axis off image; colormap gray;
firstSeedMask = segTool.getSeedsMask('base'); firstSeedMask(firstSeedMask > 1) = 0;
subplot(1, 3, base); imagesc(overlay(slcSerieBase(:, :, pkImg), firstSeedMask));  title('first ROI seed base'); axis off image; colormap gray;


fm.newFig('roi1vsThreshold');
subplot(1, 3, apex); imagesc(overlay(slcSerieApex(:, :, pkImg), firstRoiMask(:, :, apex))); title('first ROI vs threshold apex'); axis off image; colormap gray;
subplot(1, 3, mid);  imagesc(overlay(slcSerieMid(:, :, pkImg),  firstRoiMask(:, :, mid)));   title('first ROI vs threshold mid'); axis off image; colormap gray;
subplot(1, 3, base); imagesc(overlay(slcSerieBase(:, :, pkImg), firstRoiMask(:, :, base)));  title('first ROI vs threshold base'); axis off image; colormap gray;


plotData('nbROIvsIt', nbROI);
plotData('AreaUnderCurvevsIt', AUC);
plotData('FirstROISurfacevsIt', FirstROISurface);
plotData('TimeToPeakvsIt', ttp);
plotData('PeakValvsIt', peakValue);
plotData('maxSlopevsIt', maxSlope);
plotData('maxSlopePositionvsIt', maxSlopePos);


%return features
featuresStruct.FirstROISurface = FirstROISurface;
featuresStruct.AUC = AUC;
featuresStruct.ttp = ttp;
featuresStruct.maxSlope = maxSlope;
featuresStruct.maxSlopePos = maxSlopePos;
featuresStruct.nbROI = nbROI;
featuresStruct.peakValue = peakValue;

maskStackStruct.apex = baseMaskStack


%features space display
dimensionNamesKS = {'TTP','FirstROISurface','AUC'};
dimVectorTab = [ttp(:, 1)'; FirstROISurface(:, 1)'; AUC(:, 1)'];
displayFeaturesSpace(dimVectorTab, dimensionNamesKS, '-b');
dimVectorTab = [ttp(:, 2)'; FirstROISurface(:, 2)'; AUC(:, 2)'];
displayFeaturesSpace(dimVectorTab, dimensionNamesKS, '-g');
dimVectorTab = [ttp(:, 3)'; FirstROISurface(:, 3)'; AUC(:, 3)'];
displayFeaturesSpace(dimVectorTab, dimensionNamesKS, '-r');





%% inner functions


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

    function firstRoiMask = updateFirstRoiMask(firstRoiMask, mask, threshold)
        previousRoiMask = firstRoiMask;
        previousRoiMask(firstRoiMask > 0) = 1;
        firstRoiMask = firstRoiMask + (mask - previousRoiMask) .* threshold;
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