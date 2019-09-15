classdef SegmentationToolAutoLesionDetect < SegmentationToolAutoTempRegionGrowing
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        %average TIC
        avgTicTab;
        avgTicSlopeTab;
        %tic features
        avgTicAUCTab;
        avgTicTTPTab;
        avgTicMaxSlopeTab;
        avgTicMaxSlopePosTab;
        avgTicPeakValueTab;
        regionSurfaceTab;
        
        featuresMap;
        roiMaskMap;
        optimalThresholdMap;
        featVectGradientNormMap;
    end
    
    
    methods (Access = protected)
        function processRoiAvgTicFeatures(obj, roiMask, imSerie, it)
            
            avgTimeCurve = obj.processAverageTimeCurve(imSerie, roiMask);
            slope = diff(avgTimeCurve);
            obj.avgTicTab(:, it) = avgTimeCurve;
            obj.avgTicSlopeTab(:, it) = slope;
            obj.avgTicAUCTab(it) = sum(avgTimeCurve);
            obj.avgTicTTPTab(it) = find(avgTimeCurve == max(avgTimeCurve(:)), 1, 'first');
            obj.avgTicPeakValueTab(it) = max(avgTimeCurve);
            obj.avgTicMaxSlopeTab(it) = max(slope(:));
            obj.avgTicMaxSlopePosTab(it) = find(slope == max(slope), 1 , 'first');
            obj.regionSurfaceTab(it) = numel(roiMask(roiMask == 1));
            
            
            
        end%calculateRoiAvgCurve
        
        function dumpFeatIntoMap(obj, slcName)
            
            feat.avgTicTab              = obj.avgTicTab;
            feat.avgTicSlopeTab         = obj.avgTicSlopeTab;
            feat.avgTicAUCTab           = obj.avgTicAUCTab;
            feat.avgTicTTPTab           = obj.avgTicTTPTab;
            feat.avgTicMaxSlopeTab      = obj.avgTicMaxSlopeTab;
            feat.avgTicMaxSlopePosTab   = obj.avgTicMaxSlopePosTab;
            feat.avgTicPeakValueTab     = obj.avgTicPeakValueTab;
            feat.regionSurfaceTab       = obj.regionSurfaceTab;
            
            obj.avgTicTab               = [];
            obj.avgTicSlopeTab          = [];
            obj.avgTicAUCTab            = [];
            obj.avgTicTTPTab            = [];
            obj.avgTicMaxSlopeTab       = [];
            obj.avgTicMaxSlopePosTab    = [];
            obj.avgTicPeakValueTab      = [];
            obj.regionSurfaceTab        = [];
            
            obj.featuresMap = mapInsert(obj.featuresMap, slcName, feat);
        end%dumpFeatIntoMap
        
        function processOptimalThresholdMap(obj)
            for k = 1 : length(obj.slcKS)
                features = obj.featuresMap(char(obj.slcKS(k)));
                featVect(1, :) = features.avgTicTTPTab;
                featVect(2, :) = features.avgTicAUCTab;
                featVect(3, :) = features.avgTicMaxSlopeTab;
                featVect(4, :) = features.avgTicPeakValueTab;
                featVect(5, :) = features.regionSurfaceTab;
                
                %features shall be relative
                for l = 1 : size(featVect, 1)
                    maxVal = max(featVect(l, :));
                    minVal = min(featVect(l, :));
                    featVect(l, :) = (featVect(l,:) - minVal) / (maxVal - minVal);
                    featVectGradients(l, :) = diff(featVect(l, :));
                end
                for l = 1 : size(featVectGradients, 2)
                    featVectGradientNorm(l) = norm(featVectGradients(:, l));
                end
                featVectGradientNorm(1:8) = 0;
                obj.optimalThresholdMap = mapInsert(obj.optimalThresholdMap, obj.slcKS(k),...
                    find(featVectGradientNorm == max(featVectGradientNorm(:)), 1, 'first'));
                obj.featVectGradientNormMap = ...
                    mapInsert(obj.featVectGradientNormMap, obj.slcKS(k), featVectGradientNorm);
                
                features = [];
                featVect = [];
                featVectGradients = [];
                featVectGradientNorm = [];
            end
            
        end%processOptimalThresholdMap
        
        function setLabeledImages(obj)
            for k = 1 : length(obj.slcKS)
                roiMask = obj.roiMaskMap(char(obj.slcKS(k)));
               obj.labelImgMap =  mapInsert(obj.labelImgMap, obj.slcKS(k), ...
                            roiMask(:,:, obj.optimalThresholdMap(char(obj.slcKS(k)))));
            end
        end%setLabeledImage
    end%(Access =protected)
    
    methods(Access = public)
        function run(obj)
            obj.processTimeCurvesSum();
            
            for k = 1 : length(obj.slcKS)
                curSumMap = obj.timeCurveSumMap(char(obj.slcKS(k)));
                curCtcSet = obj.ctcSetMap(char(obj.slcKS(k)));
                curMask = obj.maskMap(char(obj.slcKS(k)));
                [H, W] = size(curMask);
                seedsMask = zeros(H, W);
                
                seedPos = obj.searchNewSeed(curSumMap, curMask);
                seedsMask(seedPos.x, seedPos.y) = 1;
                roiMask = zeros(H, W);
                it = 1;
                while true
                    roiMask(:, :, it) = obj.extendRoi(seedPos, curMask, curCtcSet, it);
                    obj.processRoiAvgTicFeatures(roiMask(:, :, it), curCtcSet, it);
                    %outloop condition
                    if ~(max(curMask - sum(roiMask, 3)))
                        break;
                    end
                    it = it + 1;
                end%while
                
                % add curLabeledImg to the labelImgMap
                obj.seedsMaskMap = mapInsert(obj.seedsMaskMap, obj.slcKS(k), seedsMask);
                obj.roiMaskMap = mapInsert(obj.roiMaskMap, obj.slcKS(k), roiMask);
                obj.dumpFeatIntoMap(char(obj.slcKS(k)));
            end
            obj.processOptimalThresholdMap();
            obj.setLabeledImages();
        end%run
        
        %getters
        function optThresh = getOptimalThreshold(obj, slcName)
            optThresh = obj.optimalThresholdMap(slcName);
        end%getOptimalThreshold
        
        function featGradientNorm = getFeatGradientNorm(obj, slcName)
            featGradientNorm = obj.featVectGradientNormMap(slcName);
        end%getFeatGradientNorm
        
        function roiMask = getRoiMask(obj, slcName, dimNum)
            roiMask = obj.roiMaskMap(slcName);
            if 2 == dimNum
                for k = size(roiMask, 3) : -1 : 2
                    roiMask(:,:,k) = (roiMask(:,:,k) - roiMask(:, :, k - 1)) .* k;
                end
                roiMask = sum(roiMask, 3);
            end
        end%getroiMask
        
        function features = getFeatures(obj, slcName)
            features = obj.featuresMap(slcName);
        end%getFeatures
    end%methods(Access = public)
    
end

