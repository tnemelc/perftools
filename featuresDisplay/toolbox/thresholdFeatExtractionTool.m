classdef thresholdFeatExtractionTool < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        segOpt;
        lgr;
        dataPath;
        savePath;
        
        labeledImgMap;
        slcSerieMap;
        slcKS;
        firstRoiMaskMap;
        avgCurveTabMap;
        roiSurfaceVectMap;
        AUCMaskMap;
        SeedMaskMap;
        AUCVectMap;
        AUCStdVectMap;
        TTPVectMap;
        TTPStdVectMap;
        maxSlopePosVectMap;
        maxSlopeVectMap;
        maxSlopeStdVectMap;
        peakValueVectMap;
        peakValueStdVectMap;
        delayVectMap;
        nbRoiMap;
        searchMaskMap;
        % tools
        rAnlzr; %roi analyzer tool
    end
    
    methods (Access = public)
        %%
        function prepare(obj, slcSerieMap, searchMaskMap, opt)
            obj.lgr = logger.getInstance();
            obj.segOpt = opt;
            obj.segOpt.rScale = 1;
            obj.segOpt.maxThreshold = opt.maxThreshold;
            obj.slcSerieMap = slcSerieMap;
            obj.searchMaskMap = searchMaskMap;
            obj.slcKS = obj.slcSerieMap.keys;
            obj.initFirstRoiMaskMap();
        end
        %%
        function initFirstRoiMaskMap(obj)
            
             for l = 1 : length(obj.slcKS)
                [H, W, ~] = size(obj.slcSerieMap(char(obj.slcKS(l))));
                 obj.firstRoiMaskMap = mapInsert(obj.firstRoiMaskMap, ...
                                            char(obj.slcKS(l)), zeros(H, W));
             end
        end
        %%
        function run(obj)
            segTool = SegmentationToolAutoTempRegionGrowing();
            segTool.prepare(obj.segOpt.dataPath, obj.segOpt);
            segTool.setMaskMap(obj.searchMaskMap);
            obj.rAnlzr = strgRoiAnalyzerTool();
            obj.rAnlzr.prepare(obj.segOpt);
            for k =  1 : obj.segOpt.maxThreshold
                segTool.updateRScale(k);
                segTool.run();
                for l = 1 : length(obj.slcKS)
                    slcName = char(obj.slcKS(l));
                    obj.rAnlzr.setRoisMask(segTool.getLabledSlcImg(slcName), slcName);
%                     %get AUC mask
                    if k == 1
                        obj.AUCMaskMap = mapInsert(obj.AUCMaskMap, slcName, segTool.getAUCMask(slcName));
                        obj.SeedMaskMap = mapInsert(obj.SeedMaskMap, slcName, segTool.getSeedsMask(slcName));
                    end
                end
                obj.rAnlzr.run();
                for l = 1 : length(obj.slcKS)
                    slcName = obj.slcKS{l};
                    obj.labeledImgMap = mapInsert(obj.labeledImgMap, slcName, ...
                                                    segTool.getLabledSlcImg(slcName));
                    obj.updateFirstRoiMask(k, slcName);
                    obj.processRoiSurfaceFeat(slcName);
                    obj.processAvgTimeCurve(k, slcName);
                    obj.processAUCFeat(slcName);
                    obj.processTTPFeat(slcName);
                    
                    obj.processMaxSlope(slcName);
                    obj.processPeakValue(k, slcName);
                    obj.processAucStdFeat(slcName);
                    obj.processTTPStdFeat(slcName);
                    obj.processMaxSlopeStd(slcName);
                    obj.processPeakValueStd(slcName);
                    obj.processDelay(slcName);
                    
                end
            end
             
        end% run
        %% 
        function updateFirstRoiMask(obj, thresVal, slcName)
            mask = obj.labeledImgMap(slcName);
            mask(mask > 1) = 0;
            previousRoiMask = obj.firstRoiMaskMap(slcName);
%             previousRoiMask(previousRoiMask > 0) = 1;
            mask(previousRoiMask > 0) = 0;
            firstRoiMask = previousRoiMask + mask .* thresVal;
            obj.firstRoiMaskMap = mapInsert(obj.firstRoiMaskMap, slcName, firstRoiMask);
        end%updateFirstRoiMask
        
        %% 
        function processAvgTimeCurve(obj, threshVal, slcName)
%             imSerie = obj.slcSerieMap(slcName);
%             mask = obj.firstRoiMaskMap(slcName);
%             mask(mask > 0) = 1;
            try
                avgCurveTab = obj.avgCurveTabMap(slcName);
            catch
                % ignore exception scilently,
            end
%             [H, W, ~] = size(imSerie);
%             pos = find(mask == 1);
%             [x, y] = ind2sub([H, W], pos);
%             tmp = 0;
%             for k = 1 : length(pos)
%                 tmp = tmp + squeeze(imSerie(x(k), y(k), ...
%                                     obj.segOpt.lwTCrop : obj.segOpt.upTCrop));
%             end
%             avgCurveTab(threshVal, :) = tmp ./ length(x);
            avgCurveTab(threshVal, :) = obj.rAnlzr.getRoiAvgTic(slcName, 1);
            obj.avgCurveTabMap = mapInsert(obj.avgCurveTabMap, slcName, avgCurveTab);
        end%processRoiSurface
        
        %%
        function processRoiSurfaceFeat(obj, slcName)
            mask = obj.firstRoiMaskMap(slcName);
            mask(mask > 0) = 1;
            try
                roiSurfaceVect = [obj.roiSurfaceVectMap(slcName) length(mask(mask > 0))];
            catch
                roiSurfaceVect = length(mask(mask > 0));
            end
            obj.roiSurfaceVectMap = mapInsert(obj.roiSurfaceVectMap, slcName, roiSurfaceVect);
        end%processRoiSurface
        
        %% 
        function processAUCFeat(obj, slcName)
            auc = obj.rAnlzr.getRoiFeatVal('roiTicAuc', 1, slcName);
            if isempty(auc)
               auc = 0; 
            end
            try
                AUCVect = [obj.AUCVectMap(slcName) auc];
            catch
                AUCVect = auc;
            end
            obj.AUCVectMap = mapInsert(obj.AUCVectMap, slcName, AUCVect);
        end%processAUCFeat
        
        %% 
        function processAucStdFeat(obj, slcName)
%             imSerie = obj.slcSerieMap(slcName);
%             mask = obj.firstRoiMaskMap(slcName);
%             mask(mask > 0) = 1;
%             pos = find(mask == 1);
%             if ~isempty(pos)
%                 [H, W, ~] = size(imSerie);
%                 [x, y] = ind2sub([H, W], pos);
%                 for k = 1 : length(pos)
%                     curTimeCurve = squeeze(imSerie(x(k), y(k), obj.segOpt.lwTCrop : obj.segOpt.upTCrop));
%                     AUCVect(k) = sum(curTimeCurve);
%                 end
%                 aucStd = std(AUCVect(:));
%             else
%                 aucStd = nan;
%             end
            aucStd = -1;
            try
                AUCStdVect = [obj.AUCStdVectMap(slcName) aucStd];
            catch
                AUCStdVect = aucStd;
            end
            obj.AUCStdVectMap = mapInsert(obj.AUCStdVectMap, slcName, AUCStdVect);
        end%%processAUCstdFeat
        
        %%
        function processTTPFeat(obj, slcName)
            ttp = obj.rAnlzr.getRoiFeatVal('roiTicTtp', 1, slcName);
            if isempty(ttp)
               ttp = 0; 
            end
            try
                TTPVect = [obj.TTPVectMap(slcName) ttp];
            catch
                TTPVect = ttp;
            end
            obj.TTPVectMap = mapInsert(obj.TTPVectMap, slcName, TTPVect);
        end%processTTPFeat
        
        %%
        function processTTPStdFeat(obj, slcName)
%             imSerie = obj.slcSerieMap(slcName);
%             mask = obj.firstRoiMaskMap(slcName);
%             mask(mask > 0) = 1;
%             pos = find(mask == 1);
%             if ~isempty(pos)
%                 [H, W, ~] = size(imSerie);
%                 [x, y] = ind2sub([H, W], pos);
%                 for k = 1 : length(pos)
%                     curTimeCurve = squeeze(imSerie(x(k), y(k), obj.segOpt.lwTCrop : obj.segOpt.upTCrop));
%                     ttpVect(k) = find(curTimeCurve > 0.9 * max(curTimeCurve(:)), 1, 'first');
%                 end
%                 ttpStd = std(ttpVect(:)); 
%             else
%                 ttpStd = nan;
%             end
            ttpStd = -1;
            try
                ttpStdVect = [obj.TTPStdVectMap(slcName) ttpStd];
            catch
                ttpStdVect = ttpStd;
            end
            obj.TTPStdVectMap = mapInsert(obj.TTPStdVectMap, slcName, ttpStdVect);
        end
        %%
        function processMaxSlope(obj, slcName)
            maxSlopeFeat = obj.rAnlzr.getRoiFeatures({'roiTicMaxSlope', 'roiTicMaxSlopePos'}, 1, slcName);
            if isempty(maxSlopeFeat.roiTicMaxSlope)
                maxSlopeFeat.roiTicMaxSlope = 0;
                maxSlopeFeat.roiTicMaxSlopePos = 0;
            end
            try
                maxSlopePosVect = [obj.maxSlopePosVectMap(slcName) maxSlopeFeat.roiTicMaxSlopePos];
                maxSlopeVect = [obj.maxSlopeVectMap(slcName) maxSlopeFeat.roiTicMaxSlope];
            catch
                maxSlopePosVect = maxSlopeFeat.roiTicMaxSlopePos;
                maxSlopeVect = maxSlopeFeat.roiTicMaxSlope;
            end 
            obj.maxSlopePosVectMap = mapInsert(obj.maxSlopePosVectMap, slcName, maxSlopePosVect);
            obj.maxSlopeVectMap = mapInsert(obj.maxSlopeVectMap, slcName, maxSlopeVect);
        end%processMaxSlope
        
        %%
        function processMaxSlopeStd(obj, slcName)
%             imSerie = obj.slcSerieMap(slcName);
%             mask = obj.firstRoiMaskMap(slcName);
%             mask(mask > 0) = 1;
%             pos = find(mask == 1);
%             if ~isempty(pos)
%                 [H, W, ~] = size(imSerie);
%                 [x, y] = ind2sub([H, W], pos);
%                 for k = 1 : length(pos)
%                     curTimeCurve = squeeze(imSerie(x(k), y(k), obj.segOpt.lwTCrop : obj.segOpt.upTCrop));
%                     maxSlopeVect(k) = max(diff(curTimeCurve(:)));
%                 end
%                 maxSlopeStd = std(maxSlopeVect(:));
%             else
%                  maxSlopeStd = nan;
%             end
            maxSlopeStd = -1;
            try
                maxSlopeStdVect = [obj.maxSlopeStdVectMap(slcName) maxSlopeStd];
            catch
                maxSlopeStdVect = maxSlopeStd;
            end
            obj.maxSlopeStdVectMap = mapInsert(obj.maxSlopeStdVectMap, slcName, maxSlopeStdVect);
        end%processMaxSlopeStd
        
        %%
        function processPeakValue(obj, threshVal, slcName)
            peakVal = obj.rAnlzr.getRoiFeatVal('roiTicPeakVal', 1, slcName);
            if isempty(peakVal)
               peakVal = 0; 
            end
            try
                peakValueVect = [obj.peakValueVectMap(slcName) peakVal];
            catch
                peakValueVect = peakVal;
            end
            obj.peakValueVectMap = mapInsert(obj.peakValueVectMap, slcName, peakValueVect);
        end%processPeakValue
        
        %%
        function processPeakValueStd(obj, slcName)
%             imSerie = obj.slcSerieMap(slcName);
%             mask = obj.firstRoiMaskMap(slcName);
%             mask(mask > 0) = 1;
%             pos = find(mask == 1);
%             if ~isempty(pos)
%             [H, W, ~] = size(imSerie);
%             [x, y] = ind2sub([H, W], pos);
%             for k = 1 : length(pos)
%                 curTimeCurve = squeeze(imSerie(x(k), y(k), obj.segOpt.lwTCrop : obj.segOpt.upTCrop));
%                 peakValueVect(k) = max(curTimeCurve(:));
%             end
%                 peakValStd = std(peakValueVect(:));
%             else
%                 peakValStd = nan;
%             end
            peakValStd = -1;
            try
                peakValueStdVect = [obj.peakValueStdVectMap(slcName) peakValStd];
            catch
                peakValueStdVect = peakValStd;
            end
            obj.peakValueStdVectMap = mapInsert(obj.peakValueStdVectMap, slcName, peakValueStdVect);
        end%processPeakValueStd
        
        %%
        function processDelay(obj, slcName)
            delay = obj.rAnlzr.getRoiFeatVal('roiTicDelay', 1, slcName);
            if isempty(delay)
               delay = 0; 
            end
            try
                delayVect = [obj.delayVectMap(slcName) delay];
            catch
                delayVect = delay;
            end
            obj.delayVectMap = mapInsert(obj.delayVectMap, slcName, delayVect);
        end
        
        %% getters
        %%
        function out = getFirstRoiMask(obj, slcName)
            out = obj.firstRoiMaskMap(slcName);
        end
        %%
        function out = getAUCMask(obj, slcName)
            out = obj.AUCMaskMap(slcName);
        end%getAUCMask
        %%
        function out = getavgCurveTab(obj, slcName)
            out = obj.avgCurveTabMap(slcName);
        end
        
        %%
        function out = getroiSurfaceVect(obj, slcName)
            out = obj.roiSurfaceVectMap(slcName);
        end
        %%
        function out = getAUCVect(obj, slcName)
            out = obj.AUCVectMap(slcName);
        end
        
        %%
        function out = getAUCStdVect(obj, slcName)
            out = obj.AUCStdVectMap(slcName);
        end
        
        %%
        function out = getTTPVect(obj, slcName)
            out = obj.TTPVectMap(slcName);
        end
        %% TTPStdVectMap
        function out = getTTPStdVect(obj, slcName)
            out = obj.TTPStdVectMap(slcName);
        end
        %%
        function out = getmaxSlopePosVect(obj, slcName)
            out = obj.maxSlopePosVectMap(slcName);
        end
        
        %%
        function out = getmaxSlopeVect(obj, slcName)
            out = obj.maxSlopeVectMap(slcName);
        end
        
        %%
        function out = getmaxSlopeStdVect(obj, slcName)
            out = obj.maxSlopeStdVectMap(slcName);
        end
        %%
        function out = getpeakValueVect(obj, slcName)
            out = obj.peakValueVectMap(slcName);
        end
        %%
        function out = getDelayVect(obj, slcName)
            out = obj.delayVectMap(slcName);
        end
        
        %%
        function out = getpeakValueStdVect(obj, slcName)
            out = obj.peakValueStdVectMap(slcName);
        end
        
        %%
        function out = getnbRoi(obj, slcName)
            out = obj.nbRoiMap(slcName);
        end
        
        %%
        function out = getSeedMask(obj, slcName)
            out = obj.SeedMaskMap(slcName);
        end
        
        
    end%methods (Access = public)
    
end

