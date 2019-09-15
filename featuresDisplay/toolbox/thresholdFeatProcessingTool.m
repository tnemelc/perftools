classdef thresholdFeatProcessingTool < voxelFeatExtractTool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        firstRoiMaskMap;
        seedMaskMap;
        AUCMaskMap;
        slcThreshRoiFeaturesTabMap;          % features of roi average TIC  
                                             % matrix map
        slcNormalizedThreshRoiFeaturesTabMap;% normalized features of roi
                                             % TIC average matrix map
        slcThreshRoiFeaturesGradientsTabMap; % gradient of ROI average  
                                             % TIC features
        
        slcThreshRoiNormalizedFeaturesGradientsTabMap; % gradient of normalized 
                                                       % ROI average TIC features
                                                       
        slcThreshRoiFeaturesGradientsNormMap;% features gradient norm
        slcThreshRoiNormalizedFeaturesGradientsNormMap;% normalized features gradient norm
                                                       
        slcNormalizedFeaturesTabMap; % normalized features of voxels TIC
                                     % matrix map
                                     
        optimalThresholdValMap;
                                     
    end%properties (Access = protected) 
    
    methods (Access = public)
        function obj = prepare(obj, opt)
            obj = obj.prepare@featuresTool(opt);
            obj = obj.loadSlcSerie();
            obj = obj.loadMyoMask();
        end
        
        function obj = run(obj) 
            %process
            obj = obj.loadThresholdFeaturesMap();
            %
            obj = obj.loadSlcFirstRoiMask();
            obj = obj.loadSlcAUCMask();
            
            obj = obj.processFeatVect();
            obj = obj.normalizeFeatures();
            obj = obj.processThresholdFeatGradientsVect();
            obj = obj.processThresholdNormalizedFeatGradientsVect();
            obj = obj.processOptimalThresholdVals();
        end%run
        
        %getters
        function slcThreshRoiFeaturesTab = getSlcThreshRoiFeaturesTab(obj, slcName)
            slcThreshRoiFeaturesTab = obj.slcThreshRoiFeaturesTabMap(slcName);
        end%getSlcThreshRoiFeaturesTab
        %%
        function slcThreshRoiFeaturesTab = getSlcNormalizedThreshRoiFeaturesTab(obj, slcName)
            slcThreshRoiFeaturesTab = obj.slcNormalizedThreshRoiFeaturesTabMap(slcName);
        end%getSlcNormalizedThreshRoiFeaturesTab
        %%
        function slcThreshRoiSurfaceVect = getSlcThreshRoiSurfaceVect(obj, opt)
            slcThreshRoiSurfaceVect = loadmat(fullfile(opt.rootPath, opt.slcName, 'roiSurface.mat'));
            switch opt.slcName
                case 'apex'
                    slcThreshRoiSurfaceVect = squeeze(slcThreshRoiSurfaceVect(:, 1));
                case 'mid'
                    slcThreshRoiSurfaceVect = squeeze(slcThreshRoiSurfaceVect(:, 2));
                case 'base'
                    slcThreshRoiSurfaceVect = squeeze(slcThreshRoiSurfaceVect(:, 3));
            end
        end%getSlcThreshNbRoiVect
        %%
        function normalizedFeatVect = getSlcNormalizedFeatures(obj, slcName, featuresNameKS)
            tmpVect = obj.slcNormalizedFeaturesTabMap(slcName);
            for k = 1 : size(tmpVect, 2)
                for l = 1 : length(featuresNameKS)
                    switch char(featuresNameKS(l))
                        case 'PeakVal'
                            normalizedFeatVect(l, k) = tmpVect(1, k);
                        case 'TTP'
                            normalizedFeatVect(l, k) = tmpVect(2, k);
                        case 'roiSurface'
                            normalizedFeatVect(l, k) = tmpVect(3, k);
                        case 'AUC'
                            normalizedFeatVect(l, k) = tmpVect(4, k);
                        case 'maxSlope'
                            normalizedFeatVect(l, k) = tmpVect(5, k);
                        case 'maxSlopePos'
                            normalizedFeatVect(l, k) = tmpVect(6, k);
                        case 'treshold'
                            normalizedFeatVect(l, k) = tmpVect(7, k);
                    end
                end
            end
        end%getSlcNormalizedFeaturesTabMap
        %%
        function slcThreshRoiFeaturesGradientsTab = getSlcThreshRoiFeaturesGradientsTab(obj, slcName)
            slcThreshRoiFeaturesGradientsTab = obj.slcThreshRoiFeaturesGradientsTabMap(slcName);
        end%getSlcThreshRoiFeaturesTab
        %%
        function slcThreshRoiFeaturesGradientsNorm = getSlcThreshRoiFeaturesGradientsNorm(obj, slcName)
            slcThreshRoiFeaturesGradientsNorm = obj.slcThreshRoiFeaturesGradientsNormMap(slcName);
        end%getSlcThreshRoiFeaturesGradientsNormMap
        %%
        function slcThreshRoiNormalizedFeaturesGradients = getSlcThreshRoiNormalizedFeaturesGradientsTab(obj, slcName)
            slcThreshRoiNormalizedFeaturesGradients = obj.slcThreshRoiNormalizedFeaturesGradientsTabMap(slcName);
        end%getSlcThreshRoiNormalizedFeaturesGradientsTabMap
        %%
        function slcThreshRoiNormalizedFeaturesGradientsNorm = getSlcThreshRoiNormalizedFeaturesGradientsNorm(obj, slcName)
            slcThreshRoiNormalizedFeaturesGradientsNorm = obj.slcThreshRoiNormalizedFeaturesGradientsNormMap(slcName);
        end%getSlcThreshRoiNormalizedFeaturesGradientsTabMap
        %%
        function roiMask = getfirstRoiMask(obj, slcName)
            roiMask = obj.firstRoiMaskMap(slcName);
        end%getfirstRoiMask
        %%
        function aucMask = getAUCMask(obj, slcName)
            aucMask = obj.AUCMaskMap(slcName);
        end%getAUCMask
        %% 
        function seedMask = getSeedMask(obj, slcName)
            seedMask = obj.seedMaskMap(slcName);
        end
        %%
        function optThreshVal = getOptThreshVal(obj, slcName)
            optThreshVal = obj.optimalThresholdValMap(slcName);
        end%getOptThreshVal
        
        %%
        function tmp = updatemaskMaps(obj, slcName, mask)
            %tmp is used for mask addition we search the 
            % non zeros voxels in mask that are set to zeros in the map
            % and set them to 1 in the updated map.
            tmp = obj.firstRoiMaskMap(slcName);
            tmp(tmp > 1) = 1;
            tmp = tmp - mask;
            tmp(tmp == 1) = 0; 
            tmp(tmp == -1) = 1; 
            
            obj.firstRoiMaskMap(slcName) = obj.firstRoiMaskMap(slcName) .* mask + tmp;
            obj.AUCMaskMap(slcName) = obj.AUCMaskMap(slcName) .* mask + tmp;
        end%updatefirstRoiMaskMap
        
        
    end%methods (Access = public)
    
    methods (Access = protected)
%         function obj = setSliceKeyset(obj)
%             obj.slcKS = {'base', 'mid', 'apex'};
%         end%setSliceKeyset
        %%
        function obj = loadThresholdFeaturesMap(obj, opt)
            if nargin < 2
                opt.rootPath = fullfile(obj.patientPath, 'featuresDisplay');
            end
            threshRoifeaturesTab = []; % threshRoifeaturesTab : obj.maxThreshold x user slected dims x nb imseries (slices)
            for k = 1 : length(obj.dimKS)
                for l = 1 : length(obj.slcKS)
                    try
                        threshRoifeaturesTab(:, l, k) = loadmat(fullfile(opt.rootPath, char(obj.slcKS(l)), char(obj.dimKS(k))));
                    catch e
                        if strcmp(e.identifier, 'MATLAB:load:couldNotReadFile')
                            obj.lgr.info('could not load feature. will process and save it.');
                            obj.processRoiAvgTicFeatures(opt);
                            threshRoifeaturesTab(:, l, k) = loadmat(fullfile(opt.rootPath, char(obj.slcKS(l)), char(obj.dimKS(k))));
                        else
                            rethrow(e);
                        end
                    end
                end
            end% for k..
            
            for k = 1 : length(obj.slcKS)
                obj.slcThreshRoiFeaturesTabMap = mapInsert(obj.slcThreshRoiFeaturesTabMap, char(obj.slcKS(k)), squeeze(threshRoifeaturesTab(:, k, :)));
            end
        end%loadThresholdFeaturesMap
        %%
        function obj = normalizeFeatures(obj)
            % normalize roi average curve features vector first
            % to keep relativity
            for k = 1 : length(obj.slcKS)
                threshRoifeaturesTab = obj.slcThreshRoiFeaturesTabMap(char(obj.slcKS(k)));
                for l = 1 : length(obj.dimKS)
                    maxVal = max(squeeze(threshRoifeaturesTab(:, l)));
                    minVal = min(squeeze(threshRoifeaturesTab(:, l)));
                    %because relatives values min and max values shall be
                    %taken from the voxels features
%                     maxVal = max(obj.getSlcFeatures(char(obj.slcKS(k)), obj.dimKS(l)));
%                     minVal = min(obj.getSlcFeatures(char(obj.slcKS(k)), obj.dimKS(l)));
                    if (minVal ~= maxVal) 
                        threshRoifeaturesTab(:, l) = (threshRoifeaturesTab(:, l) - minVal) / (maxVal - minVal);
                    else
                        threshRoifeaturesTab(:, l) = zeros(numel(threshRoifeaturesTab(:, l)), 1);
                    end
                end
                
                obj.slcNormalizedThreshRoiFeaturesTabMap = mapInsert(obj.slcNormalizedThreshRoiFeaturesTabMap, ...
                                                            char(obj.slcKS(k)), threshRoifeaturesTab);
            end
            
            %then normalize voxels curves features
            for k = 1 : length(obj.slcKS)
                featVect = obj.slcFeatureTabMap(char(obj.slcKS(k)));
                for l = 1 : (size(featVect, 1) - 1) % we don't normalize threshold
                    maxVal = max(featVect(l, :));
                    minVal = min(featVect(l, :));
                    if minVal ~= maxVal
                        featVect(l, :) = (featVect(l, :) - minVal) / (maxVal - minVal);
                    else
                        featVect(l, :) = zeros(1, numel(featVect(l, :)));
                    end
                    
                end
                obj.slcNormalizedFeaturesTabMap = mapInsert(obj.slcNormalizedFeaturesTabMap, ...
                                       char(obj.slcKS(k)), featVect);
            end
        end% normalizeFeatures
        %%
        function obj = loadSlcFirstRoiMask(obj, opt)
            if nargin < 2
                rootPath = fullfile(obj.patientPath, 'featuresDisplay');
            else
                rootPath = opt.rootPath;
            end 
            for k = 1 : length(obj.slcKS)
                
                slcRoiMask = loadmat(fullfile(rootPath, char(obj.slcKS(k)), 'firstRoiMask.mat'));
                if ~isa(obj.firstRoiMaskMap,'containers.Map')% create map if does not exists
                    obj.firstRoiMaskMap = containers.Map(char(obj.slcKS(k)), slcRoiMask);
                else % else insert into map
                    obj.firstRoiMaskMap(char(obj.slcKS(k))) = slcRoiMask;
                end
            end
        end%loadSlcFirstRoiMask
        %%
        function obj = loadSlcAUCMask(obj)
            for k = 1 : length(obj.slcKS)
                try
                    mask = loadmat(fullfile(obj.patientPath, 'featuresDisplay', char(obj.slcKS(k)), 'AUCMask.mat'));
                catch
                    obj.lgr.info('no AUC mask, will load myo mask instead');
                    mask = loadmat(fullfile(obj.patientPath, 'dataPrep', char(obj.slcKS(k)), 'mask.mat'));
                end
                obj.AUCMaskMap = mapInsert(obj.AUCMaskMap, char(obj.slcKS(k)), mask);
            end
        end%loadSlcAUCMask
        %%
        function loadSeedMask(obj)
            for k = 1 : length(obj.slcKS)
                try
                    mask = loadmat(fullfile(obj.patientPath, 'featuresDisplay', char(obj.slcKS(k)), 'seedMask.mat'));
                catch
                    obj.lgr.info('no seedMask mask in %s, will load myo mask instead');
                    mask = loadmat(fullfile(obj.patientPath, 'dataPrep', char(obj.slcKS(k)), 'mask.mat'));
                end
                obj.seedMaskMap = mapInsert(obj.seedMaskMap, char(obj.slcKS(k)), mask);
            end
        end%loadSeedMask
        %%
        function obj = processFeatVect(obj)            
            %set mask map necessarry for parent featVect function
%             for k = 1 : length(obj.slcKS)
%                 %mask = obj.firstRoiMaskMap(char(obj.slcKS(k)));
%                 %mask(mask ~= 0) = mask(mask ~= 0) ./ mask(mask ~= 0); 
%                 if ~isa(obj.maskMap,'containers.Map')% create map if does not exists
%                     obj.maskMap = containers.Map(char(obj.slcKS(k)), mask) ;
%                 else % else insert into map
%                     obj.maskMap(char(obj.slcKS(k))) = mask;
%                 end
%             end
%             obj = obj.loadMyoMask();
            obj = obj.processFeatVect@voxelFeatExtractTool();
            %apend threshold feature
            for k = 1 : length(obj.slcKS)
                mask = obj.firstRoiMaskMap(char(obj.slcKS(k)));
                [H, W] = size(mask);
                pos = find(mask > 0);
                [x, y] = ind2sub([H, W], pos);
                featVect = obj.slcFeatureTabMap(char(obj.slcKS(k)));
                featVect = [featVect; zeros(1,size(featVect, 2))];
                % add fictive feature being the threshold value needed to
                % integrate voxel in the found roi
                for l = 1 : length(x)
                   featVect(end, l) = mask(x(l), y(l)); 
                end
                obj.slcFeatureTabMap(char(obj.slcKS(k))) = featVect; 
            end
        end%processFeatVect
        %%
        function obj = processThresholdFeatGradientsVect(obj)
%             nbRoifeatVect = obj.slcThreshRoiFeaturesTabMap('roiSurface'); 
            for k = 1 : obj.slcPathMap.length
                featVect = obj.slcThreshRoiFeaturesTabMap(char(obj.slcKS(k)));
                featVectGradients = diff(featVect);
                
                if ~isa(obj.slcThreshRoiFeaturesGradientsTabMap,'containers.Map')% create map if does not exists
                    obj.slcThreshRoiFeaturesGradientsTabMap = containers.Map(char(obj.slcKS(k)), featVectGradients) ;
                else % else insert into map
                    obj.slcThreshRoiFeaturesGradientsTabMap(char(obj.slcKS(k))) = featVectGradients;
                end
                
                featVectGradientsNorm = zeros(1, size(featVectGradients, 1));
                for l = 1 : size(featVectGradients, 1)
                    featVectGradientsNorm(l) = norm(featVectGradients(l, :));
                end
                
                if ~isa(obj.slcThreshRoiFeaturesGradientsNormMap,'containers.Map')% create map if does not exists
                    obj.slcThreshRoiFeaturesGradientsNormMap = containers.Map(char(obj.slcKS(k)), featVectGradientsNorm) ;
                else % else insert into map
                    obj.slcThreshRoiFeaturesGradientsNormMap(char(obj.slcKS(k))) = featVectGradientsNorm;
                end
            end
        end%processThresholdFeatGradientsVect
        %%
        function obj = processThresholdNormalizedFeatGradientsVect(obj, opt)
            if nargin < 2
                opt.rootPath = fullfile(obj.patientPath, 'featuresDisplay');
            end
            for k = 1 : obj.slcPathMap.length
                
                opt.slcName = char(obj.slcKS(k));
                threshRoiSurfaceVect = obj.getSlcThreshRoiSurfaceVect(opt);
                
                normalizedFeatVect = obj.slcNormalizedThreshRoiFeaturesTabMap(char(obj.slcKS(k)));
                normalizedFeatVectGradients = diff(normalizedFeatVect);
                
                normalizedFeatVectGradients(1 : 5, :) = normalizedFeatVectGradients(1:5, :) * 0.01;
                %filter first variations
%                 for l = 1 : size(normalizedFeatVectGradients, 1)
%                     if threshRoiSurfaceVect(l) < 8
%                         normalizedFeatVectGradients(l,:) = 0;
%                     else
%                         break;
%                     end
%                 end
                
                if ~isa(obj.slcThreshRoiNormalizedFeaturesGradientsTabMap,'containers.Map')% create map if does not exists
                    obj.slcThreshRoiNormalizedFeaturesGradientsTabMap = containers.Map(char(obj.slcKS(k)), normalizedFeatVectGradients) ;
                else % else insert into map
                    obj.slcThreshRoiNormalizedFeaturesGradientsTabMap(char(obj.slcKS(k))) = normalizedFeatVectGradients;
                end
                
                normalizedFeatVectGradientsNorm = zeros(1, size(normalizedFeatVectGradients, 1));
                for l = 1 : size(normalizedFeatVectGradients, 1)
                    normalizedFeatVectGradientsNorm(l) = norm(normalizedFeatVectGradients(l, :));
                end
                if ~isa(obj.slcThreshRoiNormalizedFeaturesGradientsNormMap,'containers.Map')% create map if does not exists
                    obj.slcThreshRoiNormalizedFeaturesGradientsNormMap = containers.Map(char(obj.slcKS(k)), normalizedFeatVectGradientsNorm) ;
                else % else insert into map
                    obj.slcThreshRoiNormalizedFeaturesGradientsNormMap(char(obj.slcKS(k))) = normalizedFeatVectGradientsNorm;
                end
            end
        end%processThresholdNormalizedFeatGradientsVect
        %%
        function obj = processOptimalThresholdVals(obj)
            for k = 1 : length(obj.slcKS)
                slcName = char(obj.slcKS(k));
                featVectGradientsNorm = obj.slcThreshRoiNormalizedFeaturesGradientsNormMap(slcName);
                optThreshold = find(featVectGradientsNorm == max(featVectGradientsNorm), 1, 'first');
                obj.optimalThresholdValMap = mapInsert(obj.optimalThresholdValMap, slcName, optThreshold);
            end
        end
        %%
        function featureVectMap = processRoiAvgTicFeatures(obj, opt)
            featExtractorTool = thresholdFeatExtractionTool();
            ftExtractopt = obj.getFeatureExtractOptions();
            ftExtractopt.dataPath = obj.patientPath;
            if isfield(opt, 'maskPath')
                ftExtractopt.maskPath = opt.maskPath;
            end
            featExtractorTool.prepare(obj.slcSerieMap, obj.myoMaskMap, ftExtractopt);
            featExtractorTool.run();
            
            for k = 1 : length(obj.slcKS)
                slcName = char(obj.slcKS(k));
                emptyDir(fullfile(opt.rootPath, slcName));
                savemat(fullfile(opt.rootPath, slcName, 'firstRoiMask.mat'), featExtractorTool.getFirstRoiMask(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'seedMask.mat'), featExtractorTool.getSeedMask(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'avgCurve.mat'), featExtractorTool.getavgCurveTab(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'roiSurface.mat'), featExtractorTool.getroiSurfaceVect(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'AUCMask.mat'), featExtractorTool.getAUCMask(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'AUC.mat'), featExtractorTool.getAUCVect(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'AUCStd.mat'), featExtractorTool.getAUCStdVect(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'TTP.mat'), featExtractorTool.getTTPVect(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'TTPStd.mat'), featExtractorTool.getTTPStdVect(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'maxSlopePos.mat'), featExtractorTool.getmaxSlopePosVect(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'maxSlope.mat'), featExtractorTool.getmaxSlopeVect(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'maxSlopeStd.mat'), featExtractorTool.getmaxSlopeStdVect(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'peakVal.mat'), featExtractorTool.getpeakValueVect(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'peakValStd.mat'), featExtractorTool.getpeakValueStdVect(slcName));
                savemat(fullfile(opt.rootPath, slcName, 'delay.mat'), featExtractorTool.getDelayVect(slcName));
%                 savemat(fullfile(opt.rootPath, slcName, 'nbRoi.mat'), featExtractorTool.getnbRoi(slcName));
            end
        end%processFeature
        %%
        function opt = getFeatureExtractOptions(obj)
            opt.xScale = 0;
            opt.yScale = 0;
            opt.merge = 0;
            opt.lwTCrop = obj.lwTCrop;
            opt.upTCrop = obj.upTCrop;
            opt.seedCriterion = 'min_area_under_curve';
            opt.thresholdType = 'absolute';
            opt.nbIt = 40;
            opt.pkImg = 29;
            opt.maxThreshold = obj.maxThreshold;
        end
    end%(Access = protected)
    
end%classdef

