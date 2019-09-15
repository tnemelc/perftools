classdef kMeanSTRGFeatTool < cPerfImSerieTool
    %kMeanSTRGFeatTool 
    % this tool processes spatio temporal region growing (STRG)
    % Segmentation after prior kmean segmentation with k=3
    % the STRG is only performed on ROI with voxels labeled k=1 considered
    % as lesion regions
    
    properties
        kmeanSegTool;
        strgSegTool;
        kmLesionRoiMaskMap;
        strgLesionRoiMaskMap;
    end
    
    methods (Access = public)
        %%
        function obj = prepare(obj, opt)
            obj.dataPath = opt.dataPath;
            obj = obj.prepare@cPerfImSerieTool(obj);
            obj.kmeanSegTool = ticFeatKMeanSegmentationTool();
            obj.kmeanSegTool = obj.kmeanSegTool.prepare(opt);
            obj.strgSegTool = multiRoiStrgTool();
            obj.strgSegTool = obj.strgSegTool.prepare(opt);
            obj.isKS = obj.kmeanSegTool.getSeriesKS();
        end
        
        %%
        function obj = run(obj, opt)
            obj.kmeanSegTool = obj.kmeanSegTool.run(nan);
            for k = 1 : length(obj.isKS)
                obj.strgLesionRoiMaskMap = mapInsert(obj.strgLesionRoiMaskMap, obj.isKS{k}, zeros(size(obj.strgSegTool.getMyoMask(obj.isKS{k}))));
            end
            obj = obj.extractKMeanLesionRois();
            maxRoiNumber = obj.calculateMaxRoiNumber();
            for k = 1 : maxRoiNumber
                for m = 1 : length(obj.isKS)
                    lesionRoisMask = obj.kmLesionRoiMaskMap(obj.isKS{m});
                    lesionRoisMask(lesionRoisMask ~= k) = 0;
                    lesionRoisMask(lesionRoisMask == k) = 1;
                    obj.strgSegTool.updateMyoMask(obj.isKS{m}, lesionRoisMask);
                end
                obj.strgSegTool = obj.strgSegTool.run();
                for m = 1 : length(obj.isKS)
                    %get the processed strg roi mask
                    strgLesionRoiMask = obj.strgSegTool.getfirstRoiMask(obj.isKS{m});
                    %apply the optimal thresh
                    optimalThresh = obj.strgSegTool.getOptThreshVal(obj.isKS{m});
                    strgLesionRoiMask(strgLesionRoiMask > optimalThresh) = 0;
                    %add it to the global roi mask
                    strgLesionRoiMask = strgLesionRoiMask + obj.strgLesionRoiMaskMap(obj.isKS{m});
                    obj.strgLesionRoiMaskMap = mapInsert(obj.strgLesionRoiMaskMap, obj.isKS{m}, strgLesionRoiMask);
                end
            end
        end
        %%
        function [avgTic, minTic, maxTic] = proccessRoiAvgTic(obj, isName, mask)
            [avgTic, minTic, maxTic] = obj.strgSegTool.proccessRoiAvgTic(isName, mask);
        end
        %%
        function updateMyoMask(obj, isName, mask)
            obj.kmeanSegTool.updateMyoMask(isName, mask);
        end
        %%
        function saveMyoMaskUpdate(obj, isName)
            if nargin == 1
                 slcKS = obj.isKS;
             else
                 slcKS = {isName};
             end
             %check for modification
             for k = 1 : length(slcKS)
                 isName = char(slcKS(k));
                 maskFolderPath = fullfile(obj.dataPath, 'dataPrep', isName);
                 oldMask = loadmat(fullfile(maskFolderPath, 'mask.mat'));
                 maskDiff = abs(oldMask - obj.kmeanSegTool.getMyoMask(isName));
                 maskDiffFlag(k) = 0 ~= max(maskDiff(:));
             end
             
             if sum(maskDiffFlag) > 0 &&...
                     strcmp(questdlg('save myocardium mask changes (a backup of old mask will be done)?'), 'Yes')
                 for k = 1 : length(slcKS)
                     if ~maskDiffFlag(k)
                         continue;
                     end
                     isName = char(slcKS(k));
                     maskPath = fullfile(obj.dataPath, 'dataPrep', isName, 'mask.mat');
                     copyfile(maskPath, fullfile(obj.dataPath, 'dataPrep',...
                                      isName, sprintf('%s_mask.mat.bak', datestr(now, 'yyyymmddTHHMMSS'))), 'f');
                     savemat(fullfile(obj.dataPath, 'dataPrep', isName, 'mask.mat'), obj.kmeanSegTool.getMyoMask(isName));
                 end
             end
        end
        %%
        function updateMaskMaps(obj, isName, mask)
            tmp = obj.strgLesionRoiMaskMap(isName);
            tmp = tmp .* mask;
            obj.strgLesionRoiMaskMap = mapInsert(obj.strgLesionRoiMaskMap, isName, tmp);
        end
        %% getters
        function isKS = getSliceKS(obj)
            %obj.lgr.warn('this function should not exist. Instead class features display should inherit from cPerfImSerieTool and the right to be used function should be strgSegTool().');
            isKS = obj.strgSegTool.getSliceKS();
        end
        %%
        function slcSerie = getSlcSerieMap(obj, isName)
%             obj.lgr.warn('this function should not exist. Instead class features display should inherit from cPerfImSerieTool and the right to be used function should be strgSegTool().');
            slcSerie = obj.strgSegTool.getSlcSerieMap(isName);
        end
        %%
        function mask = getfirstRoiMask(obj, isName)
%             mask = obj.strgSegTool.getfirstRoiMask(isName);
%             obj.lgr.warn('obsolete function');
            mask = obj.strgLesionRoiMaskMap(isName);
        end
        %%
        function roiId = getKMeansMaskRoId(obj, slcName, x, y)
            mask = obj.kmLesionRoiMaskMap(slcName);
            roiId = mask(x, y);
        end
        %%
        function mask = getStrgMask(obj, isName, kMeanRoiId)
            mask = obj.strgLesionRoiMaskMap(isName);
            if nargin == 3
                kMeanMask = obj.kmLesionRoiMaskMap(isName);
                mask = obj.strgLesionRoiMaskMap(isName);
                mask(kMeanMask ~= kMeanRoiId) = 0;
            end
        end
        %%
        function mask = getKMeanLesionRoiMask(obj, isName)
            mask = obj.kmLesionRoiMaskMap(isName);
        end
        %%
        function mask = getMyoMask(obj, isName)
%             obj.lgr.warn('this function should not exist. Instead class features display should inherit from cPerfImSerieTool and the right to be used function should be strgSegTool().');
            mask = obj.kmeanSegTool.getMyoMask(isName);
        end
        %%
        function featuresTab = getSlcNormalizedThreshRoiFeaturesTab(obj, isName)
            featuresTab = obj.strgSegTool.getSlcNormalizedThreshRoiFeaturesTab(isName);
        end
        %%
        function roiSurfVect = getSlcThreshRoiSurfaceVect(obj, opt)
            roiSurfVect = obj.strgSegTool.getSlcThreshRoiSurfaceVect(opt);
        end
        %%
        function featureTabGradients = getSlcThreshRoiNormalizedFeaturesGradientsTab(obj, isName)
            featureTabGradients = obj.strgSegTool.getSlcThreshRoiNormalizedFeaturesGradientsTab(isName);
        end
        %%
        function featuresGradientsNorm =  getSlcThreshRoiNormalizedFeaturesGradientsNorm(obj, isName)
            featuresGradientsNorm =  obj.strgSegTool.getSlcThreshRoiNormalizedFeaturesGradientsNorm(isName);
        end
        %%
        function thresholdVect = getSlcFeatures(obj, isName, featuresNameKS)
            thresholdVect = obj.strgSegTool.getSlcFeatures(isName, featuresNameKS);
        end
        %%
        function optThresh = getOptThreshVal(obj, isName)
            optThresh = obj.strgSegTool.getOptThreshVal(isName);
        end
        %%
       function lwTCrop = getLwTCrop(obj)
           lwTCrop = obj.strgSegTool.getLwTCrop();
       end
       %%
       function upTCrop = getUpTCrop(obj)
           upTCrop = obj.strgSegTool.getUpTCrop();
       end
       %%
       function tol = getStrgTolerance(obj)
           tol = obj.strgSegTool.getVariationTolerance();
       end
    end%methods (Access = public)
    
    methods (Access = protected)
        %%
        function obj = extractKMeanLesionRois(obj)
            isKS = obj.kmeanSegTool.getSeriesKS();
            for k = 1 : length(isKS)
                isName = isKS{k};
                roisMask = obj.kmeanSegTool.getRoisMask(isName);
                %extract lesion regions
                roisMask(roisMask > 1) = 0;
                %remove possible epicadial region 
                roisMask = roisMask .* imerode((obj.kmeanSegTool.myoMaskMap(isName) + obj.kmeanSegTool.cavityMaskMap(isName)), strel('disk', 1));
                %TODO: il faut n'éliminer que les ROI totalement suprimées
                %apres l'opertion précédente
                
                % in a first time we process only one ROI (the largest one)
                [labeledLesionRois, numberOfBlobs] = bwlabel(roisMask);
                blobMeasurements = regionprops(labeledLesionRois, 'area');
                [sortedAreas, sortIndexes] = sort([blobMeasurements.Area], 'descend');
%                 labeledLesionRois(labeledLesionRois ~=sortIndexes(1)) = 0;
                
                obj.kmLesionRoiMaskMap = mapInsert(obj.kmLesionRoiMaskMap, isName, labeledLesionRois);
%                 obj.strgSegTool.updateMyoMask(isName, labeledLesionRois);
            end
        end
        %%
        function maxRoiNumber = calculateMaxRoiNumber(obj)
            maxRoiNumber = 0;
            for k = 1 : length(obj.isKS)
                lesionRoisMask = obj.kmLesionRoiMaskMap(obj.isKS{k});
                if maxRoiNumber < max(lesionRoisMask(:));
                    maxRoiNumber = max(lesionRoisMask(:));
                end
            end
        end
        
    end%methods (Access = protected)
    
end

