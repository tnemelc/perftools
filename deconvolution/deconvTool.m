classdef deconvTool < handle
    %deconvolution base class
    %   author clément Daviller
    properties (Access = protected)
        oversampleFact;
        slcName; %name of the slice (apex, mid or base)
        normAifCtc; % arterial input function
        deconvMask; % mask were to apply deconvolution
        roiMaskSet;% list of regions were to process deconvolution on average curve
        ctcSet; %phantom Ctc set (noised)
        roiCtcSet; % Set of CTC for each roi
        roiRepresentativeCtcSet; % set of ctc that are the most representative of roi average curve
        roiRepresentativePosSet;
        roiRepresentativeCtcFitSet; %set of fit of ctc that are the most representative of roi average curve
        tAcqAif;    %acquisition times vector of AIF
        tAcqSlc;    %acquisition times vector of Slice
        tAcq;       %sorted merge of tAcqAif and tAcqSlc
        tSim;       %regular temporal grid of tAcq (tAcq(1) : step : tAcq(end)) 
        patchWidth;
        %results
        mbfPriorMap;% starting possible estimates of mbf map 
        mbvPriorMap;% starting possible estimates of mbv map
        mbfMap; %map storing mbf values used in patient and pantom mode
        mbvMap;
        delayMap;% map storing calculated delay map
        
        mbfRoiMapSet;% set of avg roi estimated mbf map 
        mbvRoiMapSet;% set of avg roi estimated mbv map
        
        mbfSigRoiMap;% 2D array storing roi mbf measurement uncertainty
        
        fitResidue;
        fitCtcSet;
        fitRoiCtcSet;% Set of fitted roi Ctc 
        processTime;
        mbfSigmaMap;% map storing measurement variations on noise realizations. Used for squarred digital phantom
        mbvSigmaMap;% map storing measurement variations on noise realizations. Used for squarred digital phantom
        
        blLenMap; %baseline length map processed on fit ctcSet
        blSigmaMap; %Baseline noise sigma map. Loaded from patientDataPrep output
                    % used for measurement uncertainty calculation

        bsMbfMap; %bootStrap average mbf map
        bsMbvMap;%bootStrap average mbv map
        processMeasUncertaintyFlag; %process Meas Uncertainty Flag
        mbfMeasUncertaintyMap; % mbf measurement uncertainty map
        
        roiMbfUncertaintyTab; %table of roi mbf uncertainty 
        roiRepresentativeMbfUncertaintyTab; %table of roi mbf uncertainty 
        
        mbvMeasUncertaintyMap; % mbv measurement uncertainty map
        nbBsIterations;  % number of bootstrap iterations.
        
        lutNoiseMeasSigma; % look up table giving measurement uncertainty 
                           % from baseline noise sigma
        
        ttpMap; % map storing time to peak values
    end
%% public methods
    methods (Access = public)
        function obj = prepare(obj, opt) %normAifCtc, ctcSet, tAcq, opt, mask, roiMaskSet)
            %time acquisition vector for AIF
            switch opt.deconvMode
                case 'patient'
                    obj.tAcqAif = dfloor(loadmat(fullfile(opt.aifDataPath, 'tAcq.mat')), 1);
                    aif = loadmat(fullfile(opt.aifDataPath, 'aifCtcFit.mat'));
                case 'phantom'
                    aif = loadmat(fullfile(opt.aifDataPath, 'aifSimu.mat'));
                    obj.tAcqAif = dfloor(loadmat(fullfile(opt.slicePath, 'tAcq.mat')), 1);
            end
            nbAcq = floor(length(obj.tAcqAif) * opt.timePortion);
            obj.tAcqAif = obj.tAcqAif(1 : nbAcq);
            obj = obj.setAif(aif(1 : nbAcq));
            %time acquisition vector for slice
            obj.tAcqSlc = dfloor(loadmat(fullfile(opt.slicePath, 'tAcq.mat')), 1);
            obj.tAcqSlc = obj.tAcqSlc(1 : nbAcq);
            
            %global time acquisition
            obj.tAcq = mergeSorted(obj.tAcqAif, obj.tAcqSlc);
            
%             tmpRes = obj.tAcq(2) - obj.tAcq(1); 
           % obj.tSim = obj.tAcq(1) : (tmpRes / obj.oversampleFact) : obj.tAcq(end);
           obj.tSim = 0 : 0.5 : obj.tAcqAif(end);
%             obj.tSim =  obj.tAcqAif(1) : (tmpRes / obj.oversampleFact) : obj.tAcqAif(end);
            
            switch opt.deconvMode
                case 'phantom'
                    dataSet = loadmat(fullfile(opt.slicePath, 'noisedCtc.mat'));
                    obj.ctcSet = dataSet(:, :, 1:nbAcq);
                    [H, W, ~] = size(obj.ctcSet);
                    obj.deconvMask = ones(H, W);
                    obj.patchWidth = opt.patchWidth;
                case 'patient'
                    dataSet = loadmat(fullfile(opt.slicePath, 'ctcSet.mat'));
                    obj.ctcSet = dataSet(:, :, 1:nbAcq);
                    obj.deconvMask = loadmat(fullfile(opt.slicePath, 'mask.mat'));
                    obj.patchWidth = 1;
            end
            
            try
                %try to load segmented images
                switch opt.deconvMode
                    case 'phantom'
                        labeledImgPath = fullfile(opt.slicePath, 'labelsMask.mat');
                        labeledImg = loadmat(labeledImgPath);
                        myoMask = labeledImg;
                        myoMask(labeledImg > 0) = 1;
                        obj.roiMaskSet = labeledImg;
                    case 'patient'
                        [labeledImgPath, slcName] = fileparts(opt.slicePath); %retreive slice name
                        labeledImgPath  = fullfile(fileparts(labeledImgPath), 'segmentation/ManualMultiRoiMapDisplay', ['labelsMask_' slcName '.mat']);
                        labeledImg = loadmat(labeledImgPath);
                        myoMask = loadmat(fullfile(opt.slicePath, 'mask.mat'));
                        myoMask(labeledImg > 0) = 1;
                        obj.roiMaskSet =  labeledImg + myoMask;
                        cprintf('green', 'deconvTool::prepare: ROI mask loaded\n');
                end
            catch
                % no further roi, just calculate the mean myocardium ctc roi
                cprintf('green', 'deconvTool::prepare:  no ROI mask. will load mask.mat instead\n');
                try
                    obj.roiMaskSet = loadmat(fullfile(opt.slicePath, 'mask.mat'));
                catch 
                    cprintf('green', 'deconvTool::prepare:  no mask.mat. nothing loaded instead\n');
                end
            end
            obj = obj.createRoiCtc();

            obj.processMeasUncertaintyFlag = opt.processMeasUncertainty;
            
            obj.processTime = 0;
            obj.nbBsIterations = 1000;%number of bootstrap repetitions
            
            %name of the slice
            [~, obj.slcName] = fileparts(opt.slicePath);
        end%prepare
        
        function obj = processBaselineLengthMap(obj)
            [H, W] = size(obj.deconvMask);
            obj.blLenMap = zeros(H, W);
            
            for k = 1 : H
                 for l = 1 : W
                     if obj.deconvMask(k, l)
                        obj.blLenMap(k, l) = processBaseline(squeeze(obj.fitCtcSet(k, l, :)), 3, 4);
                     end
                 end
             end
        end%processBaselineLengthMap
        
        function processBaselineSigmaMap(obj)
            %make sure that processBaselineLengthMap has been prcessed
            %first
            [H, W, ~] = size(obj.fitCtcSet);
            obj.blSigmaMap = zeros(H, W);
            
            for k = 1 : H
                for l = 1 : W
                    if obj.deconvMask(k, l)
                        obj.blSigmaMap(k, l) = std(obj.ctcSet(k, l, 1 : obj.blLenMap(k, l)));
                    end
                end
             end
        end%processBaselineSigmaMap
        
        function obj = createRoiCtc(obj)
            [H, W] = size(obj.roiMaskSet);
            nbRoi = max(obj.roiMaskSet(:));
            obj.roiCtcSet = zeros(length(obj.tAcqAif), nbRoi);
            for k = 1 : nbRoi
                pos = find(obj.roiMaskSet() == k);
                [X, Y] = ind2sub([H, W], pos);
                avgRoiCtc = zeros(size(obj.ctcSet, 3), 1);
                for l = 1 : length(X)
                    avgRoiCtc = avgRoiCtc + squeeze(obj.ctcSet(X(l), Y(l), :));
                end
                obj.roiCtcSet(:, k) = avgRoiCtc ./ length(X);
            end
        end%createRoiCtc
        
        function obj = processSigmaMaps(obj)
            [H, W] = size(obj.mbfMap);
            step = (obj.patchWidth - 1);
            for k = 1 : obj.patchWidth : H
                for l = 1 : obj.patchWidth : W
                    patch = obj.mbfMap(k : k + step, l : l + step);
                    obj.mbfSigmaMap((k + step) / obj.patchWidth, (l  + step) / obj.patchWidth) = ... 
                          std(patch(:));
                    patch = obj.mbvMap(k : k + step, l : l + step);
                   obj.mbvSigmaMap((k + step) / obj.patchWidth, (l + step) / obj.patchWidth) = ... 
                          std(patch(:));
                end
            end
            
        end%processSigmaMaps
%setters
        function obj = setAif(obj, normAifCtc)
            obj.normAifCtc = normAifCtc;
        end%setAif
        
        function obj = setCtcSet(obj, ctcSet)
                obj.ctcSet = ctcSet;
        end% setCtcSet
        
        function obj = setAifTAcq(obj, tAcq)
            obj.tAcqAif = tAcq;
        end%setTAcq
        
        function obj = setRoiMaskSet(obj, roiMaskSet)
            obj.roiMaskSet = roiMaskSet;
        end
        
        function obj = setRoiCtcSet(obj, roiCtcSet)
            obj.roiCtcSet = roiCtcSet;
        end% setRoiCtcSet
%getters
        function mbfMap = getMbfMap(obj, mode, roiIdx, unit)
            if 2 > nargin
                mode = 'pixels';
                unit = 'ml/s/g';
            elseif 4 > nargin
                unit = 'ml/s/g';
            end
            if strcmp('ml/min/g', unit)
                factor = 60;
            else
                factor = 1;
            end
            switch mode
                case 'pixels'
                    mbfMap = obj.mbfMap .* factor;
                case 'rois'
                    mbfMap = obj.mbfRoiMapSet(:, :, roiIdx) .* factor;
                case 'invisible'
                    mbfMap = zeros(256, 256);
            end
        end%getMbfMap
        
        function mbf = getMbf(obj, xCoor, yCoor, unit)
            if 4 > nargin
                unit = 'ml/s/g';
            end
            if strcmp('ml/min/g', unit)
                factor = 60;
            else
                factor = 1;
            end
            mbf = obj.mbfMap(xCoor, yCoor) .*factor;
        end%getMbf
        
        function mbvMap = getMbvMap(obj, mode, roiIdx)
            if 2 > nargin
                mode = 'pixels';
            end
            switch mode
                case 'pixels'
                    mbvMap = obj.mbvMap;
                case 'rois'
                    mbvMap = obj.mbvRoiMapSet(:, :, roiIdx);
                case 'invisible'
                    mbvMap = zeros(256, 256);
            end
        end%getMbvMap
        
        function mbfMapSet = getMbfRoiMapSet(obj, unit)
            if 2 > nargin
                unit = 'ml/s/g';
            end
            if strcmp('ml/min/g', unit)
                factor = 60;
            else
                factor = 1;
            end
            mbfMapSet = obj.mbfRoiMapSet .* factor;
        end%getMbfRoiMapSet
        
        function mbvMapSet = getMbvRoiMapSet(obj)
            mbvMapSet = obj.mbvRoiMapSet;
        end%getMbvRoiMapSet
        
        function mbv = getMbv(obj, xCoor, yCoor)
            mbv = obj.mbvMap(xCoor, yCoor);
        end%getMbv
        
        function mbfSigmaMap = getMbfSigmaMap(obj, unit)
            if 2 > nargin
                unit = 'ml/s/g';
            end
            if strcmp('ml/min/g', unit)
                factor = 60;
            else
                factor = 1;
            end
            mbfSigmaMap = obj.mbfSigmaMap .* factor;
        end%getMbfSigmaMap
        
        function mbvSigmaMap = getMbvSigmaMap(obj)
            mbvSigmaMap = obj.mbvSigmaMap;
        end%getMbfSigmaMap
        
        function delayMap = getDelayMap(obj)
            delayMap = obj.delayMap;
        end%getDelayMap
        
        function ctcSet = getCtcSet(obj)
            ctcSet = obj.ctcSet;
        end%getCtcSet
        
        function roiCtcSet = getRoiCtcSet(obj)
            roiCtcSet = obj.roiCtcSet;
        end% getRoiCtcSet
        
        function fitCtcSet = getFitCtcSet(obj)
            fitCtcSet = obj.fitCtcSet;
        end% getFitCtcSet
        
        function fitRoiCtcSet = getFitRoiCtcSet(obj)
            fitRoiCtcSet = obj.fitRoiCtcSet;
        end%getFitRoiCtcSet
        
        function ctc = getCtc(obj, xCoor, yCoor)
            ctc = squeeze(obj.ctcSet(xCoor, yCoor, :));
        end%getnCtc
        
        function ctcFit = getCtcFit(obj, xCoor, yCoor)
            ctcFit = squeeze(obj.fitCtcSet(xCoor, yCoor, :));
        end%getCtcFit
        
        function residue = getResidue(obj, xCoor, yCoor)
            residue = squeeze(obj.fitResidue(xCoor, yCoor, :));
        end%getFitResidue
        
        function residueSet = getResidueSet(obj, xCoor, yCoor)
            residueSet = obj.fitResidue;
        end%getFitResidueSet
        
        function tAcq = getTAcqAif(obj)
            tAcq = obj.tAcqAif;
        end%getTAcq
        
        function tAcq = getTAcqSlc(obj)
            tAcq = obj.tAcqSlc;
        end%getTAcq
        
        function processTime = getProcessingTime(obj)
            processTime = obj.processTime;
        end%getProcessingTime
        
        function ttpMap = getTimeToPeakMap(obj)
            ttpMap = obj.ttpMap;
        end% getTimeToPeakMap
        
        function roiMaskSet = getRoiMaskSet(obj)
            roiMaskSet = obj.roiMaskSet;
        end %getRoiMaskSet
        
        function roiId = getRoiId(obj, x, y)
            if isempty(obj.roiMaskSet)
                roiId = 1;
            else
                roiId = obj.roiMaskSet(x, y);
            end
        end%getRoiId
        
        function nbRoi = getNbRoi(obj)
            nbRoi = max(obj.roiMaskSet(:));
        end%getNbRoi
        
        function [x, y] = getRoiVoxels(obj, roiId)
            [H, W] = size(obj.roiMaskSet);
            roiVoxelsIdx = find(obj.roiMaskSet == roiId);
            [x, y] = ind2sub([H, W], roiVoxelsIdx);
        end%getRoiPixels
        
        function roiSurf = getRoiSurf(obj, roiId)
            roiPixelsIdx = find(obj.roiMaskSet == roiId);
            roiSurf = length(roiPixelsIdx);
        end%getRoiSurf
        
        function avgRoiCtc = getAvgRoiCtc(obj, roiId)
            %roiVoxelsIdx = find(obj.roiMaskSet == roiId);
            %[H, W, T] = size(obj.ctcSet);
            %ctcSetList = reshape(obj.ctcSet, (H * W), T);
            %ctcRoiList = ctcSetList(roiVoxelsIdx, :);
            %avgRoiCtc = mean(ctcRoiList, 1);
            avgRoiCtc = obj.roiCtcSet(:, roiId);
        end%getAvgRoiCtc
        
        function avgRoiCtcFit = getAvgRoiCtcFit(obj, roiId)
            avgRoiCtcFit = obj.fitRoiCtcSet(:, roiId);
        end%getAvgRoiCtcFit
        
        function normAifCtc = getNormaAifCtc(obj)
            normAifCtc = obj.normAifCtc;
        end%getNormaAifCtc
        
        function roiMbf = getRoiMbf(obj, x, y)
            roiMbf = obj.mbfRoiMapSet(x, y);
        end%getRoiMbf
        
        function roiMbf = getRoiMbfByIdx(obj, roiIdx)
            [x, y] = ind2sub(size(obj.roiMaskSet), find(obj.roiMaskSet == roiIdx, 1, 'first'));
            if ~isempty(x)
                roiMbf = obj.getRoiMbf(x, y);
            else
                roiMbf = -1;
            end
        end%getRoiMbf
        
        function roiMbv = getRoiMbv(obj, x, y)
            roiMbv = obj.mbvRoiMapSet(x, y);
        end%getRoiMbv
        
        function bfUncertainty = getMbfUncertainty(obj, x, y)
            bfUncertainty = obj.mbfMeasUncertaintyMap(x, y);
        end%getBfUncertainty
        
        function bfUncertainty = getRoiMbfUncertainty(obj, roiId)
            bfUncertainty = obj.roiMbfUncertaintyTab(roiId);
        end
        
        function bfUncertaintyMap = getMbfUncertaintyMap(obj, unit)
            if nargin < 2
                unit = 'ml/s/g';
            end
            
            switch unit
                case 'ml/s/g'
                    factor = 1;
                case 'ml/min/g'
                    factor = 60;
            end
            bfUncertaintyMap = obj.mbfMeasUncertaintyMap .* factor;
        end%getMbfUncertaintyMap
        
        function blLengthMap = getBlLengthMap(obj)
            blLengthMap = obj.blLenMap;
        end%getBlLengthMap
        
        function nbBsIterations = getNbBsIterations(obj)
            nbBsIterations = obj.nbBsIterations;
        end%getNbBsIterations
        
        function bsMbfMap = getBsMbfMap(obj)
           bsMbfMap = obj.bsMbfMap; 
        end%getBsMbfMap
        
        function bsMbvMap = getBsMbvMap(obj)
           bsMbvMap = obj.bsMbvMap; 
        end%getBsMbvMap
        
        function [x, y] = getRoiRepresentativePosSet(obj)
            nbRoi = numel(obj.roiRepresentativePosSet);
            x = zeros(nbRoi, 1);
            y = zeros(nbRoi, 1);
            for k = 1 : nbRoi
                x(k) = obj.roiRepresentativePosSet(k).x;
                y(k) = obj.roiRepresentativePosSet(k).y;
            end
        end%getRoiRepresentativePosSet
    end
    
%% Abstract public methods
    methods (Abstract, Access = public)
           runDeconvolution(obj);
           runRoiDeconvolution(obj);
    end%methods (Abstract, Access = public)
%% protected methods
    methods (Access = protected)
%         processMeasurementUncertainty(obj);
        function processUncertaintyOnRoiRepresentativeCurve(obj)
            % for each roi, search the most representative voxel level curve 
            % as the one having the closest  behavior
            obj.processRoiRepresentativeCtc();
            mask = ones(1, size(obj.roiRepresentativeCtcSet, 2));
            bsTool = bootstrapTool('wild', obj.roiRepresentativeCtcSet, ...
                                        obj.roiRepresentativeCtcFitSet, mask, obj.normAifCtc, obj.nbBsIterations);
            rCexp = bsTool.run();         
            
            outStruct = obj.runCtcSetDeconvolution(rCexp);
            ctcBsMeasTab = reshape(outStruct.bf.em, size(obj.roiRepresentativeCtcSet, 2), obj.nbBsIterations)';
            for k = 1 : size(ctcBsMeasTab, 2)
                obj.roiMbfUncertaintyTab(k).avg = mean(ctcBsMeasTab(:, k)); 
                obj.roiMbfUncertaintyTab(k).std = std(ctcBsMeasTab(:, k));
                obj.roiMbfUncertaintyTab(k).minVal = min(ctcBsMeasTab(:, k));
                obj.roiMbfUncertaintyTab(k).maxVal = max(ctcBsMeasTab(:, k));
            end
        end%processUncertaintyOnRoiRepresentativeCurve
        
        function processRoiRepresentativeCtc(obj)
            nbRoi = obj.getNbRoi();
            [H, W] = size(obj.roiMaskSet);
            obj.roiRepresentativeCtcSet = zeros(size(obj.roiCtcSet));
            for k = 1 : nbRoi
                curRoiCtc = obj.roiCtcSet(:, k);
                [x, y] = ind2sub([H, W], find(obj.roiMaskSet == k));
                sse = zeros(1, length(x));
                for l = 1 : length(x)
                    sse(l) = sum( (curRoiCtc - squeeze(obj.ctcSet(x(l), y(l), :)) ).^2 );
                end
                minPos = find(sse == min(sse), 1, 'first');
                
                obj.roiRepresentativePosSet(k).x = x(minPos);
                obj.roiRepresentativePosSet(k).y = y(minPos);
                
                obj.roiRepresentativeCtcSet(:, k) = obj.ctcSet(x(minPos), y(minPos), :);
                obj.roiRepresentativeCtcFitSet(:, k) = obj.getCtcFit(x(minPos), y(minPos));
            end
        end%getRoiRepresentativeCurves
        
    end%methods (Access = protected)
    
    methods (Abstract, Access = public)
        runCtcSetDeconvolution(obj);
    end
    
end%classdef

