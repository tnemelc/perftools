classdef featuresTool < baseTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        patientPath;
        slcKS;
        dimKS;
        slcPathMap;
        slcFeatureTabMap; % map of tables that contain vectors of features 
                          % of each tic in imserie matchin the myomask 
                          % table is structured as follow
                          % ln 1: peakVal
                          % ln 2: ttp
                          % ln 3: roi surface
                          % ln 4: AUC
                          % ln 5: maxslope
                          % ln 6: max slope pos
        slcSerieMap;
        lwTCrop;
        upTCrop;
        maxThreshold;
    end%properties (Access = proteted)
    
    methods (Access = public)
        %%
        function obj = prepare(obj, opt)
            obj.prepare@baseTool(opt);
            obj.lgr = logger.getInstance();
            obj.patientPath = opt.dataPath;
            obj.dimKS = opt.dimKS;
            obj.lwTCrop = 15;
            obj.upTCrop = 50;
            obj = obj.setSliceKeyset();
            obj = obj.initMaxTreshold();
        end%prepare
        %%
        function [avgTic, minTic, maxTic] = proccessRoiAvgTic(obj, slcName, mask)
            slcSerie = obj.slcSerieMap(slcName);
            [x, y] = ind2sub(size(mask), find(mask >= 1));
            ticVect = zeros(length(x), size(slcSerie, 3));
            for k = 1 : length(x)
                ticVect(k, :) = slcSerie(x(k), y(k), :);
            end
            if 1 == length(x)
                avgTic = ticVect;
                minTic = ticVect;
                maxTic = ticVect;
                return;
            end
            avgTic = mean(ticVect);
            minTic = min(ticVect);
            maxTic = max(ticVect);
        end%proccessRoiAvgTic
        %% getters
        %%
        function slcKS = getSliceKS(obj)
            slcKS = obj.slcKS;
        end%getSliceKS
        %%
        function featuresTab = getSlcFeatureTab(obj, slcName)
            featuresTab = obj.slcFeatureTabMap(slcName);
        end%getSlcFeatureTab
        %%
        function featVect = getSlcFeatures(obj, slcName, featuresNameKS)
            tmpVect = obj.slcFeatureTabMap(slcName);
            for k = 1 : size(tmpVect, 2)
                for l = 1 : length(featuresNameKS)
                    switch char(featuresNameKS(l))
                        case 'PeakVal'
                            featVect(l, k) = tmpVect(1, k);
                        case 'TTP'
                            featVect(l, k) = tmpVect(2, k);
                        case 'roiSurface'
                            featVect(l, k) = tmpVect(3, k);
                        case 'AUC'
                            featVect(l, k) = tmpVect(4, k);
                        case 'maxSlope'
                            featVect(l, k) = tmpVect(5, k);
                        case 'maxSlopePos'
                            featVect(l, k) = tmpVect(6, k);
                        case 'treshold'
                            featVect(l, k) = tmpVect(7, k);
                    end
                end
            end
        end%getSlcFeatureTab
        %%
        function slcSerie = getSlcSerieMap(obj, slcName)
            slcSerie = obj.slcSerieMap(slcName);
        end%getSlcSerieMap
        %%
        function lwTCrop = getLwTCrop(obj)
             lwTCrop = obj.lwTCrop;
         end%getLwTCrop
        %%
        function upTCrop = getUpTCrop(obj)
             upTCrop = obj.upTCrop;
         end%getLwTCrop
        %%
        function maxThreshold = getMaxTrehshold(obj)
            maxThreshold = obj.maxThreshold ;
        end
    end%(Access = public)
    
    methods (Abstract, Access = public)
    end%(Abstract, Access = public)
    
    methods (Access = protected)
        %%
        function obj = loadSlcSerie(obj)
            for k = 1 : obj.slcPathMap.length;
                try
                    slcSerie = loadmat(fullfile(obj.patientPath, 'dataPrep', char(obj.slcKS(k)), 'slcSerie.mat'));
                catch
                    slcSerie = loadDcm(fullfile(obj.patientPath, char(obj.slcKS(k))));
                end
                % add it to the map
                if ~isa(obj.slcSerieMap,'containers.Map')% create map if does not exists
                    obj.slcSerieMap = containers.Map(char(obj.slcKS(k)), slcSerie) ;
                else % else insert into map
                    obj.slcSerieMap(char(obj.slcKS(k))) = slcSerie;
                end
            end%for
        end%loadSlcSerie
        %%
        function obj = setSliceKeyset(obj)
            obj.slcKS = {'base', 'mid', 'apex'};
            obj.slcPathMap = containers.Map(obj.slcKS, ...
                {fullfile(obj.patientPath, 'base'),...
                fullfile(obj.patientPath, 'mid'),...
                fullfile(obj.patientPath, 'apex') });
            for k = 1 : 3 % remove possible inexistant directory
                if ~isdir(obj.slcPathMap(char(obj.slcKS(k))))
                    obj.lgr.warn(sprintf('no direrctory %s', obj.slcPathMap(char(obj.slcKS(k)))));
                    remove(obj.slcPathMap, char(obj.slcKS(k)));
                    continue;
                end
            end
            %remove key with not existing directory
            rmSlcCount = 0;
            for k = 1 : length(obj.slcKS)
                if ~obj.slcPathMap.isKey(char(obj.slcKS(k - rmSlcCount)))
                    obj.slcKS(k - rmSlcCount) =  '';
                    rmSlcCount = rmSlcCount + 1;
                end
            end
        end%setSliceKeyset
        %%
        function obj = initMaxTreshold(obj)
            %get first serie Dicom info and assume the B0 is the same for
            %all series
            dcmInfo = getDicomInfoList(fullfile(obj.patientPath, char(obj.slcKS(1))));
            
            if 1.5 == dcmInfo(1).MagneticFieldStrength(1)
                obj.maxThreshold = 30;
            elseif 3 == dcmInfo(1).MagneticFieldStrength(1)
                obj.maxThreshold = 15;
            else
                throw(MException('featuresTool:setMaxTreshold', 'Magnetic field strength not managed'));
            end
        end%setMaxTreshold
    end%methods (Access = protected)
end%classdef

