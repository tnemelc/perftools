classdef ticFeatKMeanSegmentationTool < cPerfImSerieTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %% location masks
        roisMaskMap;
        %% features mask
        % roi average tic features masks
        roiTicPeakValMaskMap;
        roiTicTtpMaskMap;
        roiSurfaceMaskMap;
        roiTicAucMaskMap;
        roiTicMaxSlopeMaskMap;
        roiTicMaxSlopePosMaskMap;
        roiTicbaseLineLenMaskMap;
        roiTicCnrMaskMap;
        roiTicBaseLineStdMaskMap;%standard deviation on roi basline tic
        % myo average tic features masks
        myoTicBaseLineLenMaskMap;
        
        %voxels tic features masks
        voxelTicAucMaskMap;
        voxelTicMaxSlopeMaskMap;
        voxelTicCnrMaskMap;
        voxelTicPeakValMaskMap;
        voxelTicBaselineStdMaskMap; %standard deviation on voxel basline tic
        voxelTicCnrAvgOfRoiMaskMap; %avg of voxels CNR calculated on roi
        voxelTicBaselineStdAvgOfRoiMaskMap% avg of voxels standard deviation on voxel basline tic
        voxel2roiCnrRatioMaskMap;
        
        % roi to voxel average ratio
        roi2vxlPeakValRelativeErrMaskMap;% abs(voxelTicPkVal - roiTicPkVal) / voxelTicPkVal
        roiAvgRoi2vxlPeakValRelativeErrMaskMap;% roiMean(roi2vxlPeakValRelativeErrMaskMap)
        roi2vxlBaselineStdRatioMaskMap;
        roi2vxlTicRelativeSseMaskMap;% sse(roiavgtic - vxlTic) / (sum(vxlTic))^2
        roiAvgRoi2vxlTicRelativeSseMaskMap;% roiMean(roi2vxlTicRelativeSseMaskMap)
        
    end
    
    methods (Access = public)
        %%
        function obj = prepare(obj, opt)
            obj = obj.prepare@baseImgSerieTool(opt);
        end%
        %%
        function obj = run(obj, opt)
            obj = obj.run@baseImgSerieTool(opt);
            obj = obj.loadMyoMask();
            %obj = obj.loadRoisMask(opt);
            obj = obj.processMyoFeatures();
            %obj = obj.processRoisFeatures();
            obj = obj.processVoxelsFeatures();
            obj = obj.processKmeanSegmentation();
            obj = obj.sortRois();
%             obj = obj.processRoi2VoxelFeaturesRatios();
%             obj = obj.processRelativeRoi2vxlTicSse();
%             obj = obj.processRoiAvgRelativeRoiPeakValError();
        end
        %% getters
        %%
        function mask = getMyoMask(obj, isName)
            mask = obj.myoMaskMap(isName);
        end%getMyoMask
        %%
        function mask = getRoisMask(obj, isName)
            mask = obj.roisMaskMap(isName);
        end%getMyoMask
        %%
        %%
        function nbVxl = getRoiSurface(obj, isName, roiID)
             roiMask = obj.roisMaskMap(isName);
             nbVxl = length(find(roiMask == roiID));
        end%getRoiSurface
        %%
        function minTic = getRoiMinTic(obj, isName, roiID)
            roiMask = obj.roisMaskMap(isName);
            roiMask(roiMask ~= roiID) = 0;
            roiMask(roiMask == roiID) = 1;
            ticTab = obj.extractTimeCurves(roiMask, isName);
            minTic = min(ticTab);
        end
        %%
        function maxTic = getRoiMaxTic(obj, isName, roiID)
            roiMask = obj.roisMaskMap(isName);
            roiMask(roiMask ~= roiID) = 0;
            roiMask(roiMask == roiID) = 1;
            ticTab = obj.extractTimeCurves(roiMask, isName);
            maxTic = max(ticTab);
        end
        %%
        function mask = getFeaturesMask(obj, featureName, isName)
            try
                mask = eval(['obj.' featureName 'MaskMap(isName);']);
            catch
%                 obj.lgr.warn(sprintf('no mask named %sMaskMap', 'featureName'));
                mask = zeros(size(obj.myoMaskMap(isName)));
            end
        end%getFeaturesMask
        %%
        function featStruct = getRoiFeatures(obj, featuresKS, roiID, isName)
            roiMask = obj.roisMaskMap(isName);
            pos = find(roiMask == roiID, 1, 'first');% assume that all voxels of rois have same feture value
            for k = 1 : length(featuresKS)
                featName = char(featuresKS(k));
                curMask = obj.getFeaturesMask(featName, isName);
                featStruct.(featName) = curMask(pos);
            end
            
        end%getRoiFeatures
        %% 
        function avgTic = getRoiAvgTic(obj, isName, roiID)
            mask = obj.roisMaskMap(isName);
            mask(mask ~= roiID) = 0;
            mask(mask == roiID) = 1;
            ticTab = obj.extractTimeCurves(mask, isName);
            avgTic = mean(ticTab, 1);
        end%getRoiAvgTic
        %%
        function vxlTic = getVoxelTic(obj, isName, x, y)
            imSerie = obj.imSerieMap(isName);
            vxlTic = squeeze(imSerie(x, y, :));
        end%getVoxelTic
        %% 
        function updateMyoMask(obj, isName, mask)
            obj.myoMaskMap(isName) = mask;
        end%updateMyoMaskMap
        %%
        function updateMaskMaps(obj, isName, mask)
            obj.lgr.warn('function not implemented')
        end%updateMaskMaps
    end% methods (Access = public)

    methods (Access = protected)
        %%
        function obj = loadRoisMask(obj, opt)
            if ~isfield(opt, 'subfolderPath')
                subfolderPath = fullfile('featuresDisplay', 'autoRoiClustering');
                maskFileName = 'roisMask.mat';
                for k = 1 : length(obj.isKS)
                    isName = char(obj.isKS(k));
                    mask = loadmat(fullfile(obj.dataPath, subfolderPath, isName, maskFileName));
                    obj.roisMaskMap = mapInsert(obj.roisMaskMap, isName, mask);
                end
            else
                obj.lgr.warn('dirty trick for plugin Segmentation (tool: ManualMultiRoiMapDisplay)');
                %todo: plugin segementation shall save slices files in
                %separate folders
                subfolderPath = opt.subfolderPath;
                for k = 1 : length(obj.isKS)
                    isName = char(obj.isKS(k));
                    maskFileName = [opt.maskFileName isName];
                    mask = loadmat(fullfile(obj.dataPath, subfolderPath, maskFileName));
                    obj.roisMaskMap = mapInsert(obj.roisMaskMap, isName, mask);
                end
            end
            
            
        end%loadMyoMask(obj)
        %%
        function obj = processRoisFeatures_old(obj)
            for k = 1 : length(obj.isKS)
                isName = char(obj.isKS(k));
                curRoisMask = obj.roisMaskMap(isName);
                [H, W] = size(curRoisMask);
                peakValMask = zeros(H, W); ttpMask = zeros(H, W); 
                aucMask = zeros(H, W); maxSlopeMask = zeros(H, W); 
                maxSlopePosMask = zeros(H, W); baseLineLenMask = zeros(H, W);
                cnrMask = zeros(H, W); baselineStdMask = zeros(H, W);
                roiSurfaceMask = zeros(H, W);
                for l = 1 : max(curRoisMask(:))
                    curMask = curRoisMask;
                    curMask(curMask ~= l) = 0;
                    curMask(curMask == l) = 1;
                    [ticTab, maskPosVect] = obj.extractTimeCurves(curMask, isName);
                    if length(maskPosVect) > 1
                        avgTic = mean(ticTab, 1);
                    elseif length(maskPosVect) == 1
                        avgTic = ticTab;
                    else
                        %no region for this value
                        continue;
                    end
                    [peakVal, baseLineLen, auc, maxSlope, maxSlopePos] = obj.processTimeCurveFeatures(avgTic);
                    %ttp
                    ttp = obj.processTimeCurveTtp(avgTic, isName);
                    %cnr
                    %use myocardium baseline length because roi tic may be too
                    %noisy
                    myoBaselineLengthMask = obj.myoTicBaseLineLenMaskMap(isName);
                    myoBaseLineLenPos = find(myoBaselineLengthMask > 0, 1, 'first');
                    baselineLen = myoBaselineLengthMask(myoBaseLineLenPos);
                    [cnr, baselineStd] = obj.processTimeCurveCnr(avgTic, baselineLen);
                    peakValMask(maskPosVect) = peakVal;
                    ttpMask(maskPosVect) = ttp;
                    baseLineLenMask(maskPosVect) = baseLineLen;
                    aucMask(maskPosVect) = auc;
                    maxSlopeMask(maskPosVect) = maxSlope;
                    maxSlopePosMask(maskPosVect) = maxSlopePos;
                    cnrMask(maskPosVect) = cnr;
                    baselineStdMask(maskPosVect) = baselineStd;
                    roiSurfaceMask(maskPosVect) = numel(maskPosVect);
                end
                
                obj.roiTicPeakValMaskMap = mapInsert(obj.roiTicPeakValMaskMap, isName, peakValMask);
                obj.roiTicTtpMaskMap = mapInsert(obj.roiTicTtpMaskMap, isName, ttpMask);
                obj.roiTicbaseLineLenMaskMap = mapInsert(obj.roiTicbaseLineLenMaskMap, isName, baseLineLenMask);
                obj.roiTicAucMaskMap = mapInsert(obj.roiTicAucMaskMap, isName, aucMask);
                obj.roiTicMaxSlopeMaskMap = mapInsert(obj.roiTicMaxSlopeMaskMap, isName, maxSlopeMask);
                obj.roiTicMaxSlopePosMaskMap = mapInsert(obj.roiTicMaxSlopePosMaskMap, isName, maxSlopePosMask);
                obj.roiTicCnrMaskMap = mapInsert(obj.roiTicCnrMaskMap, isName, cnrMask);
                obj.roiTicBaseLineStdMaskMap = mapInsert(obj.roiTicBaseLineStdMaskMap, isName, baselineStdMask);
                obj.roiSurfaceMaskMap = mapInsert(obj.roiSurfaceMaskMap, isName, roiSurfaceMask);
            end
        end%processRoisFeatures
        %%
        function obj = processMyoFeatures(obj)
            for k = 1 : length(obj.isKS)
                isName = char(obj.isKS(k));
                curMyoMask = obj.myoMaskMap(isName);
                baselineLenMask = zeros(size(curMyoMask));
                
                [ticTab, myoPosVect] = obj.extractTimeCurves(curMyoMask, isName);
                avgTic = mean(ticTab, 1);
                [~, baseLineLen, ~, ~, ~] = processTimeCurveFeatures(obj, avgTic);
                baselineLenMask(myoPosVect) = baseLineLen;
                obj.myoTicBaseLineLenMaskMap = mapInsert(obj.myoTicBaseLineLenMaskMap, isName, baselineLenMask);
            end
        end%processMyoFeatures
        %%
        function obj = processVoxelsFeatures(obj)
            for k = 1 : length(obj.isKS)
               isName =  char(obj.isKS(k));
               curMyoMask = obj.myoMaskMap(isName);
%                curRoiMask = obj.roisMaskMap(isName);
               [H, W] = size(curMyoMask);
               voxelPeakValMask = zeros(H, W);
               voxelAucMask = zeros(H, W);
               voxelMaxSlopeMask = zeros(H, W);
               voxelCnrMask = zeros(H, W);
               voxelTicBaselineStdMask = zeros(H, W);
               voxelAvgCnrOfRoiMask = zeros(H, W);
               voxelTicAvgBaselineStdOfRoiMask = zeros(H, W);
               [ticTab, myoPosVect] = obj.extractTimeCurves(curMyoMask, isName);
               nbTic = size(ticTab, 1);
               
               %cnr
               %use myocardium baseline length because roi tic may be too
               %noisy
               myoBaselineLengthMask = obj.myoTicBaseLineLenMaskMap(isName);
               myoBaseLineLenPos = find(myoBaselineLengthMask > 0, 1, 'first');
               baselineLen = myoBaselineLengthMask(myoBaseLineLenPos);
               for m = 1 : nbTic
                   [cnr, sigma] = obj.processTimeCurveCnr(ticTab(m, :), baselineLen);
                   voxelCnrMask(myoPosVect(m)) = cnr;
                   voxelTicBaselineStdMask(myoPosVect(m)) = sigma;
                   %peakVal
                   voxelPeakValMask(myoPosVect(m)) = max(ticTab(m, 1 : end / 2));
                   %auc
                   voxelAucMask(myoPosVect(m)) = sum(ticTab(m, :));
                   %max Slope
                   ticSlope = diff(ticTab(m, : ));
                   voxelMaxSlopeMask(myoPosVect(m)) = max(ticSlope);
               end
               obj.voxelTicCnrMaskMap = mapInsert(obj.voxelTicCnrMaskMap, isName, voxelCnrMask);
               obj.voxelTicBaselineStdMaskMap = mapInsert(obj.voxelTicBaselineStdMaskMap, isName, voxelTicBaselineStdMask);
               obj.voxelTicPeakValMaskMap = mapInsert(obj.voxelTicPeakValMaskMap, isName, voxelPeakValMask);
               obj.voxelTicAucMaskMap = mapInsert(obj.voxelTicAucMaskMap, isName, voxelAucMask);
               obj.voxelTicMaxSlopeMaskMap = mapInsert(obj.voxelTicMaxSlopeMaskMap, isName, voxelMaxSlopeMask);
               %calculate mean CNR of rois
%                for m = 1 : max(curRoiMask(:))
%                    roiPos = find(curRoiMask == m);
%                    voxelAvgCnrOfRoiMask(roiPos) = mean(voxelCnrMask(roiPos));
%                    voxelTicAvgBaselineStdOfRoiMask(roiPos) = mean(voxelTicBaselineStdMask(roiPos));
%                end
                obj.voxelTicCnrAvgOfRoiMaskMap = mapInsert(obj.voxelTicCnrAvgOfRoiMaskMap, isName, voxelAvgCnrOfRoiMask);
                obj.voxelTicBaselineStdAvgOfRoiMaskMap = mapInsert(obj.voxelTicBaselineStdAvgOfRoiMaskMap, isName, voxelTicAvgBaselineStdOfRoiMask);
            end
        end%processVoxelsFeatures
        %%
        function obj = processRoi2VoxelFeaturesRatios(obj)
            for k = 1 : length(obj.isKS)
                isName =  char(obj.isKS(k));
                curMyoMask = obj.myoMaskMap(isName);
                %baseline stdev
                curRoiBaselineStdMask = obj.roiTicBaseLineStdMaskMap(isName);
                curVoxelBaselineStdMask = obj.voxelTicBaselineStdAvgOfRoiMaskMap(isName);
                roi2vxlBaselineStdMask = zeros(size(curMyoMask));
                roi2vxlBaselineStdMask(curMyoMask == 1) = curVoxelBaselineStdMask(curMyoMask == 1) ./...
                                                            curRoiBaselineStdMask(curMyoMask == 1);
                obj.roi2vxlBaselineStdRatioMaskMap = mapInsert(obj.roi2vxlBaselineStdRatioMaskMap, isName,...
                                                                roi2vxlBaselineStdMask);
                %peakVal relative error
                roi2vxlPeakValRatioMask = zeros(size(curMyoMask));
                voxelPeakValMask = obj.voxelTicPeakValMaskMap(isName);
                roiPeakValMask = obj.roiTicPeakValMaskMap(isName);
                roi2vxlPeakValRatioMask(curMyoMask == 1) = abs(voxelPeakValMask(curMyoMask == 1) - roiPeakValMask(curMyoMask == 1)) ...
                                                            ./ voxelPeakValMask(curMyoMask == 1);
                obj.roi2vxlPeakValRelativeErrMaskMap = mapInsert(obj.roi2vxlPeakValRelativeErrMaskMap, isName,...
                                                                roi2vxlPeakValRatioMask);
            end
        end%processRoi2VoxelFeaturesRatios
        %%
        function obj = processRelativeRoi2vxlTicSse(obj)
            for k = 1 : length(obj.isKS)
                isName =  char(obj.isKS(k));
                curRoisMask = obj.roisMaskMap(isName);
                roi2vxlTicRelativeSseMask = zeros(size(curRoisMask));
                roiAvgRoi2vxlTicRelativeSseMask = zeros(size(curRoisMask));
                
                for m = 1 : max(curRoisMask(:))
                    curMask = curRoisMask;
                    curMask(curMask ~= m) = 0;
                    curMask(curMask == m) = 1;
                    [ticTab, maskPosVect] = obj.extractTimeCurves(curMask, isName);
                    if length(maskPosVect) > 1
                        avgTic = mean(ticTab, 1);
                    elseif length(maskPosVect) == 1
                        avgTic = ticTab;
                    else
                        %no region for this value
                        continue;
                    end
                    for n = 1 : size(ticTab, 1)
                        %relative SSE
                        rSse = sum((ticTab(n, :) - avgTic) .^ 2) ./ sum(ticTab(n, :) .^ 2);
                        if rSse == 0
                            rSse = 10^-6;
                        end
                        roi2vxlTicRelativeSseMask(maskPosVect(n)) = rSse;
                    end
                    roiAvgRoi2vxlTicRelativeSseMask(maskPosVect) = mean(roi2vxlTicRelativeSseMask(maskPosVect));
                    
                end%for m = 1 : max(curRoisMask(:))
                obj.roi2vxlTicRelativeSseMaskMap = mapInsert(obj.roi2vxlTicRelativeSseMaskMap, isName, roi2vxlTicRelativeSseMask);
                obj.roiAvgRoi2vxlTicRelativeSseMaskMap = mapInsert(obj.roiAvgRoi2vxlTicRelativeSseMaskMap, isName, roiAvgRoi2vxlTicRelativeSseMask);
                
            end%for k = 1 : length(obj.isKS)
        end%processRelativeRoi2vxlTicSse
        %%
        function obj = processRoiAvgRelativeRoiPeakValError(obj)
            for k = 1 : length(obj.isKS)
                isName =  char(obj.isKS(k));
                curRoisMask = obj.roisMaskMap(isName);
                roiAvgRoi2vxlPeakValRelativeErrMask = zeros(size(curRoisMask));
                roi2vxlPeakValRelativeErrMask = obj.roi2vxlPeakValRelativeErrMaskMap(isName);
                for m = 1 : max(curRoisMask(:))
                    curMask = curRoisMask;
                    curMask(curMask ~= m) = 0;
                    curMask(curMask == m) = 1;
                    [~, maskPosVect] = obj.extractTimeCurves(curMask, isName);
                    if ~isempty(maskPosVect)
                        roiAvgRoi2vxlPeakValRelativeErrMask(maskPosVect) = mean(roi2vxlPeakValRelativeErrMask(maskPosVect));
                    else
                        %no region for this value
                        continue;
                    end
                end%for m = 1 : max(curRoisMask(:))
                obj.roiAvgRoi2vxlPeakValRelativeErrMaskMap = mapInsert(obj.roiAvgRoi2vxlPeakValRelativeErrMaskMap, isName, roiAvgRoi2vxlPeakValRelativeErrMask);
            end%for k = 1 : length(obj.isKS)
        end%processRoiAvgRelativeRoiPeakError
        %%
        function obj = processRoiStats(obj)
            for k = 1 : length(obj.isKS)
                isName = char(obj.isKS(k));
                curRoiMask = obj.roisMaskMap(isName);
                stats.nbRois = length(unique(curRoiMask));
            end
        end%processRoiStats
        %%
        function [ticTab, maskPosVect] = extractTimeCurves(obj, mask, isName)
            imSerie = obj.imSerieMap(isName);
            [H, W, T] = size(imSerie);
            maskPosVect = find(mask == 1);
            [x, y] = ind2sub([H, W], maskPosVect);
            ticTab = zeros(length(x), T);
            for k = 1 : length(x)
                ticTab(k, :) = imSerie(x(k), y(k), :);
            end
        end%extractTimeCurves
        %%
        function [peakVal, baseLineLen, auc, maxSlope, maxSlopePos] = processTimeCurveFeatures(obj, tic)
            ticSlope = diff(tic);
            peakVal = max(tic(1 : end/2));
            
            auc = sum(tic);
            maxSlope = max(ticSlope(:));
            maxSlopePos = find(ticSlope == maxSlope, 1, 'first');
            % baseline length is the time to reach 5% of peak value
            % on normalized curve 
            normTic = tic - min(tic(:));
            baseLineLen = find(normTic > 0.05 * max(normTic(:)), 1, 'first');
        end%processAvgTimeCurveFetures
        %% 
        function ttp = processTimeCurveTtp(obj, tic, isName)
            % use myocardial baseline length for it is more stable than
            % regional one
            myoBaselineLengthMask = obj.myoTicBaseLineLenMaskMap(isName);
            myoBaseLineLenPos = find(myoBaselineLengthMask > 0, 1, 'first');            
            myoBaselineLen = myoBaselineLengthMask(myoBaseLineLenPos);
            
            ttp = find(tic == max(tic(1 : end / 2)), 1, 'first') - myoBaselineLen;
        end%processTimeCurveTtp
        %%
        function [cnr, sigma] = processTimeCurveCnr(obj, tic, baselineLen)
            peakVal = max(tic);
            baselineAvg = mean(tic(1 : baselineLen));
            sigma = std(tic(1 : baselineLen));
            if sigma == 0
                sigma = 0.2;
            end
            cnr = (peakVal - baselineAvg) / sigma;
        end%processTimeCurveCnr
        %%
        function obj = processKmeanSegmentation(obj)
            for k = 1 : length(obj.isKS)
                isName =  char(obj.isKS(k));
                curMyoMask = obj.myoMaskMap(isName);
                curTicAucMask = obj.voxelTicAucMaskMap(isName);
                curTicPeakValMask = obj.voxelTicPeakValMaskMap(isName);
                curTicmaxSlopeMask = obj.voxelTicMaxSlopeMaskMap(isName);
                [~, myoPosVect] = obj.extractTimeCurves(curMyoMask, isName);
                nbElts = numel(myoPosVect);
                ftVect = zeros(nbElts, 3);
                for m = 1 : nbElts
                    ftVect(m, 1) = curTicAucMask(myoPosVect(m));
                    ftVect(m, 2) = curTicPeakValMask(myoPosVect(m));
                    ftVect(m, 3) = curTicmaxSlopeMask(myoPosVect(m));
                end
                %figure; plot(ftVect(:,1), ftVect(:,2), '+')
                [idx, C]= kmeans(ftVect, 3);
                roisMask = zeros(size(curMyoMask));
                for m = 1 : nbElts
                    roisMask(myoPosVect(m)) = idx(m);
                end
                obj.roisMaskMap = mapInsert(obj.roisMaskMap, isName, roisMask);
            end
        end
        %%
        function obj = sortRois(obj)
            for k = 1 : length(obj.isKS)
                isName = char(obj.isKS(k));
                roisMask = obj.roisMaskMap(isName);
                nbRois = max(roisMask(:));
                for m = 1 : nbRois
                    roiTicTab(:, m) = obj.getRoiAvgTic(isName, m);
                end
                roiAUC = sum(roiTicTab, 1);
                [~, sortedRoiIdx] = sort(roiAUC, 'ascend');
                sortedRoisMask = zeros(size(roisMask));
                for m = 1 : nbRois
                    sortedRoisMask(roisMask == sortedRoiIdx(m)) = m;
                end
                obj.roisMaskMap = mapInsert(obj.roisMaskMap, isName, sortedRoisMask);
            end
        end%sortRois
    end%methods (Access = protected)
end

