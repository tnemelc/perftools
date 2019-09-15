classdef roiAnalyzerTool < baseImgSerieTool
    %roiAnalyzerTool
    %   tool that processes roi and voxel time intensity curves (tic)
    %   features:
    %   -PeakVal : maximun intensity curve value of tic after tic foot and
    %       before the end of 2 thirds of the time interval
    %   -time to peak ttp: time for the ti to reach PeakVal from tic foot 
    %   -Surface: number of voxel in the ROI
    %   -area under the curve (auc) sum of the tic values on the time
    %       interval
    %   -max slope: maximum tic slope in the interval between tic foot and 
    %       tic peak
    %   -max slope pos: maximum tic slope position
    %   -baseline length: tic duration measured in seconds
    %   -delay: duration between aif tic foot and roi tic foot
    %   -CNR = roi tic cnr defined as (PeakVal - baselineVal) / std(baseline Val) 
    
    properties
        %% location masks
        myoMaskMap;
        roisMaskMap;
        %% features mask
        % roi average tic features masks
        roiTicPeakValMaskMap;
        roiTicPeakPosMaskMap;
        roiTicTtpMaskMap;
        roiSurfaceMaskMap;
        roiTicAucMaskMap;
        roiTicMaxSlopeMaskMap;
        roiTicMaxSlopePosMaskMap;
        roiTicMaxSlopeDateMaskMap;
        roiTicBaseLineLenMaskMap;
        roiTicCnrMaskMap;
        roiTicBaseLineStdMaskMap;%standard deviation on roi basline tic
        roiTicDelayMaskMap;% map of roi delay mask 
        roiTicFootMaskMap;
        
        %labels
        roiLabelsMap;
        
        % myo average tic features masks
        myoTicBaseLineLenMaskMap; %baseline length in seconds
        myoTicFootMaskMap; %baseline length in frames
        
        % arterial input function
        aif;
        %voxels tic features masks
        voxelTicCnrMaskMap;
        voxelTicPeakValMaskMap;
        voxelTicBaselineStdMaskMap; %standard deviation on voxel basline tic
        voxelTicCnrAvgOfRoiMaskMap; %avg of voxels CNR calculated on roi
        voxelTicBaselineStdAvgOfRoiMaskMap% avg of voxels standard deviation on voxel basline tic
        voxel2roiCnrRatioMaskMap;
        
        voxelTicDelayMaskMap;%> map of delay voxel mask calculated
        voxelTicBaseLineLenMaskMap;%> map of voxel baseline length 
        voxelTicPeakPosMaskMap; %> map of voxel's tic peak position
        voxelTicFootMaskMap; %> map of voxels's foot position
        
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
            obj.aif = aifTool();
            aifOpt.dataPath = fullfile(opt.dataPath, 'dataPrep', 'Aif');
            obj.aif = obj.aif.prepare(aifOpt);
            obj.aif = obj.aif.run();
            obj = obj.loadMyoMask();
            obj = obj.loadImSeries();
        end%
        %%
        function obj = run(obj, ~)
            obj = obj.run@baseImgSerieTool([]);
            obj = obj.loadRoiLabels();
            obj = obj.loadRoisMask([]);
            obj = obj.processMyoFeatures();
            obj = obj.processRoisFeatures();
            obj = obj.processVoxelsFeatures();
            obj = obj.processRoi2VoxelFeaturesRatios();
            obj = obj.processRelativeRoi2vxlTicSse();
            obj = obj.processRoiAvgRelativeRoiPeakValError();
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
        function label = getRoiLabel(obj, isName, roiId)
            labelList = obj.roiLabelsMap(isName);
            label = labelList.(['roi_' num2str(roiId)]);
        end
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
        function [footVal, footDate, footPos] = getRoiTicFoot(obj, isName, roiID)
            % get needed masks
            roiTicFootPosMask = obj.roiTicFootMaskMap(isName);
            roisMask = obj.roisMaskMap(isName);
            % get time acquisition vector for date
            tAcq = obj.imSerieTimeAcqMap(isName);
            % get avg tic
            avgTic = obj.getRoiAvgTic(isName, roiID);
            % process returned values
            footPos = roiTicFootPosMask(find(roisMask == roiID, 1, 'first'));
            footVal = avgTic(footPos);
            footDate = tAcq(footPos);
        end
        %%
        function [footVal, footDate, footPos] = getVoxelTicFoot(obj, isName, x, y)
            % get needed masks
            footPosMask = obj.voxelTicFootMaskMap(isName);
            % get time acquisition vector for date
            tAcq = obj.imSerieTimeAcqMap(isName);
            % get voxel tic
            tic = obj.getVoxelTic(isName, x, y);
            % process returned values
            footPos = footPosMask(x, y);
            footVal = tic(footPos);
            footDate = tAcq(footPos);
        end
        
        %%
        function [peakVal, peakDate, peakPos] = getRoiTicPeak(obj, isName, roiID)
            % get needed masks
            roiTicPeakValMask = obj.roiTicPeakValMaskMap(isName);
            roiTicPeakPosMask = obj.roiTicPeakPosMaskMap(isName);
            roisMask = obj.roisMaskMap(isName);
            % get time acquisition vector for date
            tAcq = obj.imSerieTimeAcqMap(isName);
            % process returned values
            peakVal = roiTicPeakValMask(find(roisMask == roiID, 1, 'first'));
            peakPos = roiTicPeakPosMask(find(roisMask == roiID, 1, 'first'));
            peakDate = tAcq(peakPos);
        end
        %% 
        function [peakVal, peakDate, peakPos] = getVoxelTicPeak(obj, isName, x, y)
            % get needed masks
            peakValMask = obj.voxelTicPeakValMaskMap(isName);
            peakPosMask = obj.voxelTicPeakPosMaskMap(isName);
            % get time acquisition vector for date
            tAcq = obj.imSerieTimeAcqMap(isName);
            % process returned values
            peakVal = peakValMask(x, y);
            peakPos = peakPosMask(x, y);
            peakDate = tAcq(peakPos);
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
        function feat = getRoiFeatVal(obj, featureName, roiID, isName)
            ftStruct = obj.getRoiFeatures({featureName}, roiID, isName);
            feat = ftStruct.(featureName);
        end
        %%
        function featStruct = getRoiFeatures(obj, featuresKS, roiID, isName)
            roiMask = obj.roisMaskMap(isName);
            pos = find(roiMask == roiID, 1, 'first');% assume that all voxels of rois have same feature value
            for k = 1 : length(featuresKS)
                featName = featuresKS{k};
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
        function [aifTic, tAcq] = getAifTic(obj)
            [aifTic, tAcq] = obj.aif.getTic();
        end
        %%
        function featVal = getAifFeature(obj, featName)
            featVal = obj.aif.getFeature(featName);
        end
        %% 
        function updateMyoMask(obj, isName, mask)
            obj.myoMaskMap(slcName) = mask;
        end%updateMyoMaskMap
        %%
        function obj = updateMaskMaps(obj, isName, mask)
            obj.roisMaskMap(isName) = mask;
        end%updateMaskMaps
        %%
        function tic = getTimCurvesFromMask(obj, isName, mask)
            tic = obj.extractTimeCurves(mask, isName);
        end
    end% methods (Access = public)

    methods (Access = protected)
        %%
        function obj = loadMyoMask(obj)
            for k = 1 : length(obj.isKS)
                isName = char(obj.isKS(k));
                mask = loadmat(fullfile(obj.dataPath, 'dataPrep', isName, 'mask.mat'));
                obj.myoMaskMap = mapInsert(obj.myoMaskMap, isName, mask);
            end
        end%loadMyoMask(obj)
        %%
%         function obj = loadAif(obj)
%             obj.aifTic = loadmat(fullfile(obj.dataPath, 'dataPrep', 'Aif', 'aif.mat'));
%             obj.aifTimeVect = loadmat(fullfile(obj.dataPath, 'dataPrep', 'Aif', 'aif.mat'));
%         end%loadAif
        %%
        function obj = loadImSeries(obj)
            for k = 1 : length(obj.isKS);
                serieName = obj.isKS{k};
                imSerie = loadmat(fullfile(obj.dataPath, 'dataPrep', serieName, 'slcSerie'));
                tAcq = loadmat(fullfile(obj.dataPath, 'dataPrep', serieName, 'tAcq'));
                obj.imSerieMap = mapInsert(obj.imSerieMap, serieName, imSerie);
                obj.imSerieTimeAcqMap = mapInsert(obj.imSerieTimeAcqMap, serieName, tAcq);
            end%for
        end%loadImSeries
        
        function obj = loadRoiLabels(obj)
            for k = 1 : length(obj.isKS)
                isName = obj.isKS{k};
                root = xml2struct(fullfile(obj.dataPath, 'segmentation', 'ManualMultiRoiMapDisplay', ['roiInfo_' isName, '.xml']));
                for m = 1 : length(root.roisInfo.roi)
                       if iscell(root.roisInfo.roi)
                            curRoiInfo = root.roisInfo.roi{m};
                        else
                            curRoiInfo = root.roisInfo.roi;
                        end
                    roiLabels.(['roi_' num2str(m)]) = curRoiInfo.name.Text;
                end
                obj.roiLabelsMap = mapInsert(obj.roiLabelsMap, isName, roiLabels);
            end
        end
        %%processing
        
        %%
        function obj = processRoisFeatures(obj)
            for k = 1 : length(obj.isKS)
                isName = char(obj.isKS(k));
                curRoisMask = obj.roisMaskMap(isName);
                [H, W] = size(curRoisMask);
                peakValMask = zeros(H, W); 
                peakPosMask = zeros(H, W);
                ttpMask = zeros(H, W);
                aucMask = zeros(H, W); maxSlopeMask = zeros(H, W);
                maxSlopePosMask = zeros(H, W); maxSlopeDateMask = zeros(H, W);
                baseLineLenMask = zeros(H, W);
                cnrMask = zeros(H, W); baselineStdMask = zeros(H, W);
                roiSurfaceMask = zeros(H, W); delayMask = zeros(H, W);
                roiTicFootMask = zeros(H, W);
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
                    tAcq = obj.imSerieTimeAcqMap(isName);
                    feat = obj.processTimeCurveFeatures(avgTic, tAcq);
                    %ttp
                    feat.ttp = tAcq(feat.peakPos) - tAcq(feat.ticFoot);
                    %cnr
                    %use myocardium baseline length because roi tic may be too
                    %noisy
                    myoTicFootMask = obj.myoTicFootMaskMap(isName);
                    myoTicFootMaskPos = find(myoTicFootMask > 0, 1, 'first');
                    myoTicFoot = myoTicFootMask(myoTicFootMaskPos);
                    [cnr, baselineStd] = obj.processTimeCurveCnr(avgTic, myoTicFoot);
                    peakValMask(maskPosVect) = feat.peakVal;
                    peakPosMask(maskPosVect) = feat.peakPos;
                    ttpMask(maskPosVect) = feat.ttp;
                    baseLineLenMask(maskPosVect) = feat.baseLineLen;
                    aucMask(maskPosVect) = feat.auc;
                    maxSlopeMask(maskPosVect) = feat.maxSlope;
                    maxSlopePosMask(maskPosVect) = feat.maxSlopePos;
                    maxSlopeDateMask(maskPosVect) = feat.maxSlopeDate;
                    cnrMask(maskPosVect) = cnr;
                    baselineStdMask(maskPosVect) = baselineStd;
                    roiSurfaceMask(maskPosVect) = numel(maskPosVect);
                    delayMask(maskPosVect) = feat.delay;
                    roiTicFootMask(maskPosVect) = feat.ticFoot;
                end
                
                obj.roiTicPeakValMaskMap = mapInsert(obj.roiTicPeakValMaskMap, isName, peakValMask);
                obj.roiTicPeakPosMaskMap = mapInsert(obj.roiTicPeakPosMaskMap, isName, peakPosMask);
                obj.roiTicTtpMaskMap = mapInsert(obj.roiTicTtpMaskMap, isName, ttpMask);
                obj.roiTicBaseLineLenMaskMap = mapInsert(obj.roiTicBaseLineLenMaskMap, isName, baseLineLenMask);
                obj.roiTicAucMaskMap = mapInsert(obj.roiTicAucMaskMap, isName, aucMask);
                obj.roiTicMaxSlopeMaskMap = mapInsert(obj.roiTicMaxSlopeMaskMap, isName, maxSlopeMask);
                obj.roiTicMaxSlopePosMaskMap = mapInsert(obj.roiTicMaxSlopePosMaskMap, isName, maxSlopePosMask);
                obj.roiTicMaxSlopeDateMaskMap = mapInsert(obj.roiTicMaxSlopeDateMaskMap, isName, maxSlopeDateMask);
                obj.roiTicCnrMaskMap = mapInsert(obj.roiTicCnrMaskMap, isName, cnrMask);
                obj.roiTicBaseLineStdMaskMap = mapInsert(obj.roiTicBaseLineStdMaskMap, isName, baselineStdMask);
                obj.roiSurfaceMaskMap = mapInsert(obj.roiSurfaceMaskMap, isName, roiSurfaceMask);
                obj.roiTicDelayMaskMap = mapInsert(obj.roiTicDelayMaskMap, isName, delayMask);
                obj.roiTicFootMaskMap = mapInsert(obj.roiTicFootMaskMap, isName, roiTicFootMask);
            end
        end%processRoisFeatures
        %%
        function obj = processMyoFeatures(obj)
            for k = 1 : length(obj.isKS)
                isName = char(obj.isKS(k));
                curMyoMask = obj.myoMaskMap(isName);
                baselineLenMask = zeros(size(curMyoMask));
                ticFootMask = zeros(size(curMyoMask));
                [ticTab, myoPosVect] = obj.extractTimeCurves(curMyoMask, isName);
                avgTic = mean(ticTab, 1);
                feat = obj.processTimeCurveFeatures(avgTic, obj.imSerieTimeAcqMap(isName));
                baselineLenMask(myoPosVect) = feat.baseLineLen;
                ticFootMask(myoPosVect) = feat.ticFoot;
                obj.myoTicBaseLineLenMaskMap = mapInsert(obj.myoTicBaseLineLenMaskMap, isName, baselineLenMask);
                obj.myoTicFootMaskMap = mapInsert(obj.myoTicFootMaskMap, isName, ticFootMask);
            end
        end%processMyoFeatures
        %%
        function obj = processVoxelsFeatures(obj)
            for k = 1 : length(obj.isKS)
               isName =  char(obj.isKS(k));
               curMyoMask = obj.myoMaskMap(isName);
               curRoiMask = obj.roisMaskMap(isName);
               [H, W] = size(curMyoMask);
               voxelPeakValMask = zeros(H, W);
               voxelCnrMask = zeros(H, W);
               voxelTicBaselineStdMask = zeros(H, W);
               voxelAvgCnrOfRoiMask = zeros(H, W);
               voxelTicAvgBaselineStdOfRoiMask = zeros(H, W);
               voxelTicDelayMask = zeros(H, W);
               voxelTicBaseLineLenMask = zeros(H, W);
               voxelTicPeakPosMask = zeros(H, W);
               voxelTicFootMask = zeros(H, W);
               [ticTab, myoPosVect] = obj.extractTimeCurves(curMyoMask, isName);
               nbTic = size(ticTab, 1);
               
               
               %cnr
               %use myocardium baseline length because roi tic may be too
               %noisy
               myoFootMask = obj.myoTicFootMaskMap(isName);
               maskPos = find(myoFootMask > 0, 1, 'first');
               baselineLen = myoFootMask(maskPos);
               for m = 1 : nbTic
                   feat = obj.processTimeCurveFeatures(ticTab(m, :), obj.imSerieTimeAcqMap(isName));
                   voxelTicDelayMask(myoPosVect(m)) = feat.delay;
                   voxelTicPeakPosMask(myoPosVect(m)) = feat.peakPos;
                   voxelTicFootMask(myoPosVect(m)) = feat.ticFoot;
                   voxelTicBaseLineLenMask(myoPosVect(m)) = feat.baseLineLen;
                   [cnr, sigma] = obj.processTimeCurveCnr(ticTab(m, :), baselineLen);
                   voxelCnrMask(myoPosVect(m)) = cnr;
                   voxelTicBaselineStdMask(myoPosVect(m)) = sigma;
                   %peakVal
                   voxelPeakValMask(myoPosVect(m)) = feat.peakVal;%max(ticTab(m, 1 : floor(end / 2)));
               end
               obj.voxelTicCnrMaskMap = mapInsert(obj.voxelTicCnrMaskMap, isName, voxelCnrMask);
               obj.voxelTicBaselineStdMaskMap = mapInsert(obj.voxelTicBaselineStdMaskMap, isName, voxelTicBaselineStdMask);
               obj.voxelTicPeakValMaskMap = mapInsert(obj.voxelTicPeakValMaskMap, isName, voxelPeakValMask);
               obj.voxelTicDelayMaskMap = mapInsert(obj.voxelTicDelayMaskMap, isName, voxelTicDelayMask);
               obj.voxelTicPeakPosMaskMap = mapInsert(obj.voxelTicPeakPosMaskMap, isName, voxelTicPeakPosMask);
               obj.voxelTicFootMaskMap = mapInsert(obj.voxelTicFootMaskMap, isName, voxelTicFootMask);
               obj.voxelTicBaseLineLenMaskMap = mapInsert(obj.voxelTicBaseLineLenMaskMap, isName, voxelTicBaseLineLenMask);
               %calculate mean CNR of rois
               for m = 1 : max(curRoiMask(:))
                   roiPos = find(curRoiMask == m);
                   voxelAvgCnrOfRoiMask(roiPos) = mean(voxelCnrMask(roiPos));
                   voxelTicAvgBaselineStdOfRoiMask(roiPos) = mean(voxelTicBaselineStdMask(roiPos));
               end
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
        function out = processTimeCurveFeatures(obj, tic, tAcq)
            %%
            % it would be good to try improvement by oversampling tic
            % making features extraction more precise
%             tInterp = tAcq(1) : ((tAcq(end) - tAcq(1)) / (5 * (length(tacq) - 1)))  : tAcq(end);
%             ticInterp = interp1(tAcq, tic, tInterp);
            ticSlope = diff(tic);
            firstPassEndPos = find(tAcq > obj.aif.getFeature('firstPassEndDate'), 1, 'first');
            out.peakVal = max(tic(obj.aif.getFeature('footPos') : firstPassEndPos));
            out.peakPos = obj.aif.getFeature('footPos') + find(tic(obj.aif.getFeature('footPos') : firstPassEndPos) == out.peakVal, 1, 'first') - 1;
            
            
            % baseline length is the time to reach 10% of peak value
            % on normalized curve 
            normTic = tic - min(tic(1 : obj.aif.getFeature('footPos')));
            % baseline length is a least greater than aif baseline length
            % and at most lower than peakPos. -> corp this piece of curve
            % normalize it and find the last point lower than 5% of peak
            % val
            ticCrop = tic(obj.aif.getFeature('footPos') : out.peakPos);
            normTicCrop = ticCrop - min(ticCrop);
            
            out.ticFoot = obj.aif.getFeature('footPos') + ...
                find(normTicCrop < 0.05 * max(normTicCrop), 1, 'last') - 1;
            if isempty(out.ticFoot)
                out.ticFoot = obj.aif.getFeature('footPos');
            end
            out.auc = sum(tic(out.ticFoot : out.peakPos));
            
            out.baseLineLen = tAcq(out.ticFoot);
            out.delay = out.baseLineLen - obj.aif.getFeature('footDate');
            
            out.maxSlope = max(ticSlope(out.ticFoot : firstPassEndPos));
            try
                out.maxSlopePos = out.ticFoot + find(ticSlope(out.ticFoot : firstPassEndPos) == out.maxSlope, 1, 'first') - 1;
            catch
                out.maxSlopePos = out.ticFoot;
            end
            out.maxSlopeDate = tAcq(out.maxSlopePos);  
        end%processAvgTimeCurveFeatures
        %%
        function [cnr, sigma] = processTimeCurveCnr(obj, tic, footPos)
            peakVal = max(tic);
            baselineAvg = mean(tic(1 : footPos));
            sigma = std(tic(1 : footPos));
            if sigma == 0
                sigma = 0.2;
            end
            cnr = (peakVal - baselineAvg) / sigma;
        end%processTimeCurveCnr
    end%methods (Access = protected)
    methods (Abstract, Access = protected)
        obj = loadRoisMask(obj, opt);
    end
    
end

