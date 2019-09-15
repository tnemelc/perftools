classdef segmentationTool < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        lgr;
        slcKS;
        patientPath;
        slcPathMap;
        slcSerieMap;
        maxImgMap;
        ctcSetMap;
        slcPeakImgMap;% Image of the serie with the AIF peak
        maskMap;
        aifInfo;% patient information from aif
        labelImgMap;%result labeled images map
        rScale; 
    end
    
    methods (Access = protected)
        function obj = setSliceKeyset(obj)
            obj.slcKS = {'base', 'mid', 'apex'};
            obj.slcPathMap = containers.Map(obj.slcKS, ...
                {fullfile(obj.patientPath, 'base'),...
                 fullfile(obj.patientPath, 'mid'),...
                fullfile(obj.patientPath, 'apex') });
            for k = 1 : 3 % remove possible inexistant directory
                if ~isdir(obj.slcPathMap(char(obj.slcKS(k))))
                    disp(['no direrctory ' obj.slcPathMap(char(obj.slcKS(k)))]);
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
        
        function obj = loadSlcSerie(obj)
                    for k = 1 : obj.slcPathMap.length;
                            try 
                                slcSerie = loadmat(fullfile(obj.slcPathMap(char(obj.slcKS(k))), 'slcSerie.mat'));
                            catch
                                slcSerie = loadDcm(obj.slcPathMap(char(obj.slcKS(k))));
                            end
                        % add it to the map
                        if ~isa(obj.slcSerieMap,'containers.Map')% create map if does not exists
                            obj.slcSerieMap = containers.Map(char(obj.slcKS(k)), slcSerie) ;
                        else % else insert into map
                            obj.slcSerieMap(char(obj.slcKS(k))) = slcSerie;
                        end
                        
                    end%for
        end%loadSlcSerie
        
        function obj = loadCtcset(obj)
            for k = 1 : obj.slcPathMap.length;
                % load slice ctcSet
                try 
                    ctcSet = loadmat(fullfile(obj.slcPathMap(char(obj.slcKS(k))), 'ctcSet.mat'));
                catch
                    ctcSet = loadDcm(obj.slcPathMap(char(obj.slcKS(k))));
                end
                % add it to the map
                if ~isa(obj.ctcSetMap,'containers.Map')% create map if does not exists
                    obj.ctcSetMap = containers.Map(char(obj.slcKS(k)), ctcSet) ;
                else % else insert into map
                    obj.ctcSetMap(char(obj.slcKS(k))) = ctcSet;
                end
            end
        end%loadCtcset
        
        function obj = loadPeakImage(obj)
            for k = 1 : obj.slcPathMap.length;
                % load slice ctcSet
                try
                    pkImg = loadmat([obj.slcPathMap(char(obj.slcKS(k))) 'peakImage.mat']);
                catch
                    serie = obj.slcSerieMap(char(obj.slcKS(k)));
                    pkImg = serie(:, :, 20);
                end
                % add it to the map
                if ~isa(obj.slcPeakImgMap,'containers.Map')% create map if does not exists
                    obj.slcPeakImgMap = containers.Map(char(obj.slcKS(k)), pkImg) ;
                else % else insert into map
                    obj.slcPeakImgMap(char(obj.slcKS(k))) = pkImg;
                end
            end
        end% loadPeakImage
        
        function obj = loadMask(obj)
            for k = 1 : obj.slcPathMap.length
                % load slice ctcSet
                try
                    mask = loadmat(fullfile(obj.patientPath, 'dataPrep', char(obj.slcKS(k)), 'mask.mat'));
                catch
                    % should we generate a mask?
                    switch questdlg('No search mask available. want to create it manually (Yes: create manually, No/Cancel: create mask for all image and will not be saved)?')
                        case 'Yes'
                            mask  = extractMyo(obj.slcSerieMap(char(obj.slcKS(k))), 25, false, char(obj.slcKS(k)), 3);
                            %savemat(fullfile(obj.slcPathMap(char(obj.slcKS(k))), 'mask.mat'), mask);
                            if ~isdir(fullfile(obj.patientPath, 'dataPrep', char(obj.slcKS(k))))
                                mkdir(fullfile(obj.patientPath, 'dataPrep', char(obj.slcKS(k))));
                            end
                            savemat(fullfile(obj.patientPath, 'dataPrep', char(obj.slcKS(k)), 'mask.mat'), mask);
                        case 'No'
                            [H, W] = size(obj.slcPeakImgMap(char(obj.slcKS(k))));
                            mask = ones(H, W);
                            disp('mask automatically created. Will not be saved');
%                             savemat((obj.slcPathMap(char(obj.slcKS(k))) 'mask.mat'], mask);
                        case 'Cancel'
                            throw(MException('segmentationTool:loadMask', 'operation cancelled by user'));
                    end
                end
                % add it to the map
                if ~isa(obj.maskMap,'containers.Map')% create map if does not exists
                    obj.maskMap = containers.Map(char(obj.slcKS(k)), mask) ;
                else % else insert into map
                    obj.maskMap(char(obj.slcKS(k))) = mask;
                end
            end
        end%loadMask
        
        function obj = loadPatientData(obj)
            try
                obj.aifInfo = loadmat([obj.patientPath '\Aif\aifData.mat']);
            catch
                [~, FamilyName] = fileparts(fileparts(obj.patientPath));
                obj.aifInfo = struct('dcmInfo', struct('PatientName', struct('FamilyName', FamilyName)));
            end
        end%loadPatientData
        
        function obj = insertMaxImg(obj)
            %insert max image to 
            for k = 1 : length(obj.slcKS)
                imgSerie = obj.slcSerieMap(char(obj.slcKS(k)));
                [H, W, ~] = size(imgSerie);
                maxImg = zeros(H, W);
                for l = 1 : H
                    for m = 1 : W
                      maxImg(l, m) = max(imgSerie(l, m, :));
                    end
                end
                obj.slcSerieMap(char(obj.slcKS(k))) = cat(3, maxImg, imgSerie);
            end
        end%createMaxImgMap
    end
    
    methods (Access = public)
        function obj = prepare(obj, patientPath, opt)
            obj.patientPath = patientPath;
            obj = obj.setSliceKeyset();
            obj = obj.loadSlcSerie();
            %obj = obj.insertMaxImg();
            obj = obj.loadCtcset();
            obj = obj.loadPeakImage();
            obj = obj.loadMask();
            obj = obj.loadPatientData();
            obj.lgr = logger.getInstance();
        end%prepare
        
        %getters
        function slcList = getSlcList(obj)
            slcList = obj.slcKS;
        end%getSlcList
        
        function slcPkPimage = getSlcPkImage(obj, slcName)
            slcPkPimage = obj.slcPeakImgMap(slcName);
        end%getSlcPkImage
        
        function patientName = getPatientName(obj)
            patientName = obj.aifInfo.dcmInfo(1).PatientName.FamilyName;
        end%getPatientName
        
        function labeledSlcImg = getLabledSlcImg(obj, slcName)
            labeledSlcImg = obj.labelImgMap(slcName).img;
        end %getLabledSlcImg
        
        function val = getMaxValOfProcessedCtcSet(obj, slcName)
            ctcSet = obj.ctcSetMap(slcName);
            mask = repmat(obj.maskMap(slcName), 1, 1, size(ctcSet, 3));
            ctcSet(mask == 0) = 0;
            val = max(ctcSet(:));
        end %getMaxValOfProcessedCtcSet
        
        function ctcSet = getCtcSet(obj, slcName)
            ctcSet = obj.ctcSetMap(slcName);
        end%getCtcSet
        
        function slcSerie = getSlcSerie(obj, slcName)
            slcSerie = obj.slcSerieMap(slcName);
        end%getSlcSerie
        
        function mask = getSearchingMask(obj, slcName)
            mask = obj.maskMap(slcName);
        end%getSearchingMask
        
        function nbLabels = getSlcNbLabels(obj, slcName)
            labeledSlcImg = obj.labelImgMap(slcName);
            nbLabels = max(labeledSlcImg(:));
        end
        
        %setters
        function setLabledSlcImg(obj, slcName, labeledSlcImg)
            obj.labelImgMap(slcName).img = labeledSlcImg;
        end% setLabledSlcImg
        
        function setMask(obj, slcName, mask)
            obj.maskMap(slcName) = mask;
        end% setMask
        
        %checkers
        function modifiedFlag = checkMaskModification(obj)
            for k = 1 : obj.slcPathMap.length
                try
                    mask = loadmat(fullfile(obj.patientPath, 'dataPrep', char(obj.slcKS(k)), 'mask.mat'));
                    if max(max(mask ~= obj.maskMap(char(obj.slcKS(k)))))
                        modifiedFlag = true;
                        return;
                    end
                catch
                    modifiedFlag = true;
                    return;
                end
            end
            modifiedFlag = false;
        end%checkMaskModfication
        
    end% methods (Access = public)
    
    methods (Abstract, Static, Access = public)
        run(obj);
    end
    
    
end

