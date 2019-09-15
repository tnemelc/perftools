classdef dataPreparator < handle
    % brief: this class load dicom Data (images), generates time acquisition vector, 
    % converts signal to concentration, extract Aif
    
    properties
        % keySet
        slcKS;               % slices keyset
        % pathes
        aifPath;                 % path of aif images series
        slcPathMap;              % map storing pathes of each slice images series
        % images
        aifSerie;                % map storing images serie of aif
        slcSerieMap;             % map storing images serie of each slice
        %masks
        aifMask;                 % mask of selected aif pixel
        slcMaskMap;              % map storing myocardial mask of each slice
        %Curves
        aifCurve;                % aif signal time curve
        aifCtc;                  % converted aif Ctc
        aifCtcFit;               % fit of aifCtc
        aifFitParams;            %
        aifBaselineLength;       % baseline length on aif curve
        aifTimeToPeak;           % time to peak of aif curve
        slcCurveSetMap;          % map storing signal time curves
        slcCtcSetMap;            % map storing converted myocardial Ctc
        slcBaselineLengthMap;    % map storing baseline length maps of each slice
        slcBaselineAvgMap;       % map storing baseline avg of ctc maps of each slice
        slcBaselineSigmaMap;     % map storing basline sigma maps of each slice 
                                 % measured on signal baseline.
                                 % assumes that signal baseline has same length
                                 % as aif one's                          
        slcSgtBaselineAvgMap;    % map storing segments ctc baseline average
        slcSgtBaselineStdMap;    % map storing segments ctc baseline standard deviation
        slcMyoBaselineAvgMap;    % map storing myocardium ctc baseline average
        slcMyoBaselineStdMap;    % map storing myocardium ctc baseline standard deviation
        %other miscelaneous data
        aifData;
        slcDataMap;
        tAcqInitStr;
        
        %converter of signal to concentration
        sg2CtcConverter; % converter from signal time curve to [Gd] CTC
        
        savePath;
        
    end
    %% methods (Access = public)
    methods (Access = public)
        %constructor
        function obj = dataPreparator(obj)
            obj.sg2CtcConverter = signal2CtcConverter;
        end
        
        %prepare
        function obj = prepare(obj, opt)
            obj.aifPath =  [opt.path '\aif\'];
            obj.slcPathMap = [];
            obj.slcKS = {'apex', 'mid', 'base'};
            obj.slcPathMap = containers.Map(obj.slcKS, ...
                                        {[opt.path '\apex\'],...
                                         [opt.path '\mid\'],...
                                         [opt.path '\base\']}); 
            for k = 1 : 3 % remove possible inexistant directory
                if ~isdir(obj.slcPathMap(char(obj.slcKS(k))))
                    disp(['no direrctory ' obj.slcPathMap(char(obj.slcKS(k)))]);
                    remove(obj.slcPathMap, char(obj.slcKS(k)));
                    continue;
                end
            end
            %remove key with not existing directory
            for k = 1 : 3; 
                if ~obj.slcPathMap.isKey(char(obj.slcKS(k)))
                    obj.slcKS(k) =  '';
                end
            end
            obj.checkPathes();
            obj.loadAif();
            obj.loadSlc();
            obj.prepareSliceBaselineSigmaMap();
            obj.prepareSliceBaselineLengthMap();
            obj.prepareSliceBaselineAvgMap();
            obj.savePath = opt.savePath;
        end%prepare
        
        function prepareSliceBaselineSigmaMap(obj)
            [H, W, ~] = size(obj.slcSerieMap(char(obj.slcKS(1))));
            map = zeros(H, W);
            for k = 1 : length(obj.slcKS)
                if ~isa(obj.slcBaselineSigmaMap, 'containers.Map')% create map if does not exists
                    obj.slcBaselineSigmaMap = containers.Map(char(obj.slcKS(k)), map) ;
                else % else insert into map
                    obj.slcBaselineSigmaMap(char(obj.slcKS(k))) = map;
                end
            end
        end%prepareSliceBaselineSigmaMap
        
        function prepareSliceBaselineLengthMap(obj)
            [H, W, ~] = size(obj.slcSerieMap(char(obj.slcKS(1))));
            map = zeros(H, W);
            for k = 1 : length(obj.slcKS)
                if ~isa(obj.slcBaselineLengthMap, 'containers.Map')% create map if does not exists
                    obj.slcBaselineLengthMap = containers.Map(char(obj.slcKS(k)), map) ;
                else % else insert into map
                    obj.slcBaselineLengthMap(char(obj.slcKS(k))) = map;
                end
            end
        end%prepareSliceBaselineLengthMap
        
        function prepareSliceBaselineAvgMap(obj)
            [H, W, ~] = size(obj.slcSerieMap(char(obj.slcKS(1))));
            map = zeros(H, W);
            for k = 1 : length(obj.slcKS)
                if ~isa(obj.slcBaselineAvgMap, 'containers.Map')% create map if does not exists
                    obj.slcBaselineAvgMap = containers.Map(char(obj.slcKS(k)), map) ;
                else % else insert into map
                    obj.slcBaselineAvgMap(char(obj.slcKS(k))) = map;
                end
            end
        end%prepareSliceBaselineAvgMap
        
        % run
        function obj = run(obj)
            % aif
           obj = obj.processAif();
           % slices
           obj = obj.processSlc();
           % convert signal to CTC
           [opt.aifBaseLineLength, opt.aifAvgBaseLineSg] = processBaseline(obj.aifCurve(4:end), 2, 4);
           slcAvgCurve = obj.getSlcAvgCurve(char(obj.slcKS(1)));
           [~, opt.slcAvgBaseLineSg] = processBaseline(slcAvgCurve(4:end));
           opt.s0Aif = mean(obj.aifCurve(1:3));
           opt.s0Slc = mean(slcAvgCurve(1:3));
           opt.convMethod = 1;
           obj.sg2CtcConverter.prepare(obj.aifData.dcmInfo(1),...
                             obj.slcDataMap(char(obj.slcKS(1))).dcmInfo(1), ...
                        opt);
           obj.aifCtc = obj.sg2CtcConverter.convertAif(obj.aifCurve);
           %fit aif
           [obj.aifCtcFit, obj.aifFitParams] = aifFit(obj.aifCtc(4:end), obj.aifData.tAcq(4:end));
           %baseline starts imediatelly after PD scans (at tAcq(4) ) and
           % in the 2 following line we remove the PD scan duration
           obj.aifBaselineLength = obj.aifData.tAcq(processBaseline(obj.aifCtcFit, 1, 4) + 4) - obj.aifData.tAcq(4);
           obj.aifTimeToPeak = processTimeToPeak(obj.aifCtcFit, obj.aifData.tAcq(4:end) - obj.aifData.tAcq(4));
           
           % for each slice
           for k = 1 : length(obj.slcKS)
               % get the curves 
               curveSet = obj.slcCurveSetMap(char(obj.slcKS(k)));
               [nbCurves, T] = size(curveSet); % stupid! the curve set is then reshaped to be an [H,W,T] matrix
               ctcSet = zeros(nbCurves, T);
               
               
               blSigmaMap = obj.slcBaselineSigmaMap(char(obj.slcKS(k)));
               blLenMap = obj.slcBaselineLengthMap(char(obj.slcKS(k)));
               blAvgMap = obj.slcBaselineAvgMap(char(obj.slcKS(k)));
               [H, W] = size(blSigmaMap);
               idxList = find(obj.slcMaskMap(char(obj.slcKS(k)))); %bad way to do this curves should be stored in a HxWxT matrix
               for l = 1 : nbCurves
                   %convert each signal curve to ctc and store it in ctcSet
                   ctcSet(l, :) = obj.sg2CtcConverter.convertCtc(curveSet(l, :)); 
                   [blLen, baseLine] =  processBaseline(squeeze(ctcSet(l, 4:end)), 1, 4);
                   
                   if ~isempty(find(isnan(baseLine)))
                       %use aif baseline length instead
                       blLen = opt.aifBaseLineLength;
                       baseLine = mean(squeeze(ctcSet(l, 4:blLen)));
%                        debugPath = getGlobalDebugPath();
%                        savemat([debugPath 'ctc'], squeeze(ctcSet(l, :)));
%                        savemat([debugPath 'baseLine'], baseLine);
%                        throw(MException('dataPreparator:run', sprintf('baseline contains NaN. k = %d, l = %d', k, l)));
                   end
                   ctcSet(l, :) = ctcSet(l, :) - baseLine;
                   [x, y] = ind2sub([H, W], idxList(l));
                   blLenMap(x, y) = obj.slcDataMap(char(obj.slcKS(k))).tAcq(blLen + 3) - obj.slcDataMap(char(obj.slcKS(k))).tAcq(4);
                   blAvgMap(x, y) = baseLine;
                   blSigmaMap(x, y) = std(ctcSet(l, 4 : opt.aifBaseLineLength + 4)) ; %ATTENTION sigma is calculated with THE BASELINE LENGTH OF AIF
                                        % THIS IS NOT AN ERROR. calulated on this baseline length to avoid
                                        % signal baseline calculation error especially in case of low signal enhancement
               end
               %store ctcSet in the map
               if ~isa(obj.slcCtcSetMap,'containers.Map')% create map if does not exists
                   obj.slcCtcSetMap = containers.Map(char(obj.slcKS(k)), ctcSet) ;
               else % else insert into map
                   obj.slcCtcSetMap(char(obj.slcKS(k))) = ctcSet;
               end
               
               % store baseline data maps
               obj.slcBaselineSigmaMap(char(obj.slcKS(k))) = blSigmaMap;
               obj.slcBaselineLengthMap(char(obj.slcKS(k))) = blLenMap;
               obj.slcBaselineAvgMap(char(obj.slcKS(k))) = blAvgMap;
               
           end
           
        end%run
        
        %getters
             %AIF
        function aifSerie = getAifSerie(obj)
            aifSerie = obj.aifSerie;
        end%getAifSerie
        
        function aifMask = getAifMask(obj)
            aifMask = obj.aifMask;
        end%getAifMask
        
        function aifPeakImage = getAifPeakImage(obj)
            aifPeakImage = squeeze(obj.aifSerie(:, :, obj.aifData.pkPos));
        end%getAifPeakImage
        
        function aifCurve = getAifCurve(obj)
            aifCurve = obj.aifCurve;
        end%getAifCurve
        
        function aifTAcq = getAifTimeAcq(obj)
            aifTAcq = obj.aifData.tAcq;
        end%getAifTimeAcq
        
        function aifCtc = getAifCtc(obj)
            aifCtc = obj.aifCtc;
        end% getAifCtc
        
        function aifCtcFit = getAifCtcFit(obj)
            aifCtcFit = obj.aifCtcFit;
        end% getAifCtcFit
        
        function aifFitParams = getAifFitParams(obj)
            aifFitParams = obj.aifFitParams;
        end%getAifFitParams
        
        function aifBaselineLength = getAifBaselineLength(obj)
            aifBaselineLength = obj.aifBaselineLength;
        end%getAifBaselineLength
        
        function aifTimeToPeak = getAifTimeToPeak(obj)
            aifTimeToPeak = obj.aifTimeToPeak;
        end%getAifTimeToPeak
        
             %Slices
        function slcKeySet = getSlcKeySet(obj)
            slcKeySet = obj.slcKS;
        end%getSlcKeySet
        
        function slcPeakImage = getSlcPeakImage(obj, slcName)
            slcPeakImage = obj.slcSerieMap(slcName);
            slcPeakImage = slcPeakImage(:, :, obj.aifData.pkPos);
        end%getSclPeakImage
        
        function slcSerie = getSliceSerie(obj, slcName)
            slcSerie = obj.slcSerieMap(slcName);
        end%getSliceSerie
        
        function slcMask = getSlcMask(obj, slcName)
            slcMask = obj.slcMaskMap(slcName);
        end%getSlcMaskMap
        
        function slcTimeAcq = getSlcTimeAcq(obj, slcName)
            slcTimeAcq = obj.slcDataMap(slcName).tAcq;
        end%getSlcTimeAcq
        
        function slcCurveSet = getSlicesCurvesSet(obj, slcName)
            slcCurveSet = obj.slcCurveSetMap(slcName);
        end%getSlicesCurvesSet
        
        function slcAvgCurve = getSlcAvgCurve(obj, slcName)
            curveset = obj.slcCurveSetMap(slcName);
            slcAvgCurve = mean(curveset, 1);
        end%getSlcAvgCurve
        
        function slcCtcSet = getSlicesCtcSet(obj, slcName)
                slcCtcSet = obj.slcCtcSetMap(slcName);
        end%getSlicesCtcSet
        
        function slcAvgCtc = getSlcAvgCtc(obj, slcName)
            ctcSet = obj.slcCtcSetMap(slcName);
            slcAvgCtc = mean(ctcSet, 1);
        end%getSlcAvgCtc
        
        function baselineLengthMap = getSlcBaselineLengthMap(obj, slcName)
            baselineLengthMap = obj.slcBaselineLengthMap(slcName);
        end% getSlcBaselineLengthMap
        
        function baselineAvgMap = getSlcBaselineAvgMap(obj, slcName)
            baselineAvgMap = obj.slcBaselineAvgMap(slcName);
        end% getSlcBaselineAvgMap
        
        function blAvgValue = getSlcBaselineAvgValue(obj, slcName)
            baselineAvgMap = obj.slcBaselineAvgMap(slcName);
            mask = obj.slcMaskMap(slcName);
            [x, y] = ind2sub(size(mask), find(mask));
            blAvgValue = 0;
            for k = 1 : length(x)
                blAvgValue = blAvgValue + baselineAvgMap(x(k),y(k));
            end
            blAvgValue = blAvgValue / length(x);
        end%getSlcBaselineAvgValue
        
        function baselineSigmaMap = getSlcBaselineSigmaMap(obj, slcName)
            baselineSigmaMap = obj.slcBaselineSigmaMap(slcName);
        end% getSlcBaselineSigmaMap
        
        function blAvgSigmaValue = getSlcBasleinAvgStDeviationValue(obj, slcName)
            baselineAvgMap = obj.slcBaselineAvgMap(slcName);
            mask = obj.slcMaskMap(slcName);
            [x, y] = ind2sub(size(mask), find(mask));
            blAvgSigmaValue = [];
            for k = 1 : length(x)
                blAvgSigmaValue = [blAvgSigmaValue  baselineAvgMap(x(k),y(k))];
            end
            blAvgSigmaValue = std(blAvgSigmaValue);
        end%getSlcBasleinAvgStDeviationValue
        
        function sgtBaselineAvgTab = getSlcSgtBaselineAvgTab(obj, slcName)
            sgtBaselineAvgTab = obj.slcSgtBaselineAvgMap(slcName);
        end%getSlcSgtBaselineAvgMap
        
        function sgtBaselineStdTab = getSlcSgtBaselineStdTab(obj, slcName)
            sgtBaselineStdTab = obj.slcSgtBaselineStdMap(slcName);
        end%getSlcSgtBaselineAvgMap
        
        function myoBaselineAvgTab = getSlcMyoBaselineAvgTab(obj, slcName)
            myoBaselineAvgTab = obj.slcMyoBaselineAvgMap(slcName);
        end%getSlcSgtBaselineAvgMap
        
        function myoBaselineStdTab = getSlcMyoBaselineStdTab(obj, slcName)
            myoBaselineStdTab = obj.slcMyoBaselineStdMap(slcName);
        end%getSlcSgtBaselineAvgMap
        
        %Other
        function patientName = getPatientName(obj)
            % we use dicom info to get patientName
            patientName = obj.aifData.dcmInfo(1).PatientName.FamilyName;
        end%getPatientName
        
        function aifData = getPatientAifData(obj)
            aifData = obj.aifData;
        end%getPatientAifData
        
        function slcDataMap = getPatientSlcDataMap(obj)
            slcDataMap = obj.slcDataMap;
        end%getPatientSlcDataMap
        
    end% methods (Access = public)
    %%methods (Access = protected)
    methods (Access = protected)
        function obj = loadAif(obj)
           obj.aifData.dcmInfo = getDicomInfoList(obj.aifPath);
           for k = 1 : length(obj.aifData.dcmInfo)
               tAcq(k, :) = obj.aifData.dcmInfo(k).AcquisitionTime;
           end
           % want acqtime in seconds unit
           obj.aifData.tAcq = getAcqTimes(tAcq) .* 1e-3;
           obj.aifSerie = loadDcm(obj.aifPath);
        end%loadAif
        
        function obj = loadSlc(obj)
            for k = 1 : obj.slcPathMap.length;
                % load slice images
                %             slcSerie
                slcData.dcmInfo = getDicomInfoList(obj.slcPathMap(char(obj.slcKS(k))));
                slcSerie = loadDcm([obj.slcPathMap(char(obj.slcKS(k))) '/MOCO/moco/']);
                for l = 1 : length(slcData.dcmInfo)
                     tAcq(l, :) = slcData.dcmInfo(l).AcquisitionTime;
                end
                % want acqtime in seconds unit
                slcData.tAcq = getAcqTimes(tAcq) .* 1e-3;
                if ~isa(obj.slcSerieMap,'containers.Map')% create map if does not exists
                    obj.slcSerieMap = containers.Map(char(obj.slcKS(k)), slcSerie) ;
                    obj.slcDataMap = containers.Map(char(obj.slcKS(k)), slcData);
                else % else insert into map
                    obj.slcSerieMap(char(obj.slcKS(k))) = slcSerie;
                    obj.slcDataMap(char(obj.slcKS(k))) = slcData;
                end
                
            end
        end%loadSlices
        
        function obj = processAif(obj)
            %extract aif Curve
            [obj.aifCurve, obj.aifData.pkPos, obj.aifData.pdScanNumber, ...
                obj.aifMask, obj.aifData.aifThresh] = ...
                extractAif(obj.aifSerie, false);
            
        end%processAif
        
        function obj = processSlc(obj)
            
            for k = 1 : obj.slcPathMap.length;
                slcSerie = obj.slcSerieMap(char(obj.slcKS(k)));
                try 
                    maskPath = fullfile(obj.savePath, char(obj.slcKS(k)), 'mask.mat');
                    mask = loadmat(maskPath);
                    if ~strcmp('Yes', questdlg('a mask already exists in the save path. Use it?'))
                        throw(MException('dataPreparator:processSlc', 'silently start extractMyo'));
                    end
                catch
                    [mask, ~] = extractMyo(slcSerie, obj.aifData.pkPos, false, char(obj.slcKS(k)));
                end
                
                %store map
                if ~isa(obj.slcMaskMap,'containers.Map')% create map if does not exists
                    obj.slcMaskMap = containers.Map(char(obj.slcKS(k)), mask) ;
                else % else insert into map
                    obj.slcMaskMap(char(obj.slcKS(k))) = mask;
                end
                %store curveSet
                maskPos = find(mask); [H, W] = ind2sub(size(mask), maskPos);
                curveSet = zeros(length(H), size(slcSerie, 3));
                for l = 1 : length(H)
                    curveSet(l, :) = slcSerie(H(l), W(l), :);
                end
                
                if ~isa(obj.slcCurveSetMap,'containers.Map')% create map if does not exists
                    obj.slcCurveSetMap = containers.Map(char(obj.slcKS(k)), curveSet) ;
                else % else insert into map
                    obj.slcCurveSetMap(char(obj.slcKS(k))) = curveSet;
                end
            end
            
        end %processSlc
        
        function checkPathes(obj)
            if ~isdir(obj.aifPath)
                throw(MException('dataPreparator:checkPathes', 'patient path not valid'));
            end
            for k = 1 : obj.slcPathMap.length
                if ~isdir(obj.slcPathMap(char(obj.slcKS(k))))
                    throw(MException('dataPreparator:checkPathes',...
                        sprintf('patient path %s not valid', obj.slcPathMap(char(obj.slcKS(k)))) ));
                end
            end
            
        end%checkPathes
    end%methods (Access = protected)
    
end

