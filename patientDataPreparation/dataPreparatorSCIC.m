classdef dataPreparatorSCIC < dataPreparator
   
    properties
        aifPDScans;
        aifNotPresentFlag;% flag indicating that aif images are not available. 
        slcPdScanMap
        
        slcPDScansInfoMap;
        
       slcT1Map;
    end
        methods (Access = public)
            
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
                rmSlcCount = 0;
                for k = 1 : 3;
                    if ~obj.slcPathMap.isKey(char(obj.slcKS(k - rmSlcCount)))
                        obj.slcKS(k - rmSlcCount) =  '';
                        rmSlcCount = rmSlcCount + 1;
                    end
                end
                try 
                    obj.checkPathes();
                catch e
                    if strcmp(e.message, 'patient path not valid');
                        if strcmp(questdlg('aif not available. want to use base folder instead?'), 'Yes')
                            obj.aifNotPresentFlag = false;
                            obj.aifPath = fullfile(opt.path, 'base');
                        else
                            rethrow(e);    
                        end
                    else
                        rethrow(e);
                    end
                end
                obj.prepDicomData(obj.aifPath);
                for k = 1 : length(obj.slcKS)
                    obj.prepDicomData(obj.slcPathMap(char(obj.slcKS(k))));
                end
                obj.loadAif();
                obj.loadSlc();
                obj.prepareSliceBaselineSigmaMap();
                obj.prepareSliceBaselineLengthMap();
                obj.prepareSliceBaselineAvgMap();
                obj.savePath = opt.savePath;
            end
            
            function run(obj)
                % aif
                obj = obj.processAif();
                % process  aif tcc
                obj.aifTIC2CTC()
                % fit AIF
                [obj.aifCtcFit, obj.aifFitParams] = aifFit(obj.aifCtc, obj.aifData.tAcq);
                obj.aifBaselineLength =  obj.aifData.tAcq(processBaseline(obj.aifCtcFit, 1, 4));
                obj.aifTimeToPeak = obj.aifData.tAcq(find(obj.aifCtcFit == max(obj.aifCtcFit), 1, 'first'));
                
                % slices
                obj.processSlc();
                % for each slice
                for k = 1 : length(obj.slcKS)
                    acqParam = obj.getAcqParams(char(obj.slcKS(k)));
                    acqParam.f = 0;
                    pdScans = obj.slcPdScanMap( char(obj.slcKS(k)) );
                    imSerie = obj.slcSerieMap( char(obj.slcKS(k)) );
                    imSerie(:, :, 1) = imSerie(:,:,3);
                    imSerie(:, :, 2) = imSerie(:,:,3);
                    mask = obj.slcMaskMap(char(obj.slcKS(k)));
                    t1Vect = 0.005 : 0.001 : 4;
                    
                    adjPDScans = obj.adjustPDScanSignal(pdScans, imSerie, acqParam, t1Vect, mask);
%                     adjPDScans = pdScans;
     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     opt.mask = mask;
%                     opt.pdScanImg = pdScans(:, :, 1);
%                     tool = pdScanRegistrationTool();
%                     opt.imSerie(:, :, 1 : 3) = pdScans ;
%                     opt.imSerie(:, :, 4 : 3 + size(imSerie, 3)) = imSerie;
%                     opt.imPos = 15;
% %                     % scicTool is not used for antenna correction here.
% %                     % it only enables to coregister and to "smooth" myocardium
% %                     % on PD scans as they are not regitered correctly yet
%                     tool = scicTool();
%                     tool = tool.prepare(opt);
%                     tool.run();
%                     pdScans =  tool.getPdScanSmoothedImSerie();
% %                     pdScans(:, :, 1) =  tool.getCorrPdScanImg();
% %                     pdScans(:, :, 2) = pdScans(:, :, 1);
% %                     pdScans(:, :, 3) = pdScans(:, :, 1);
%                     adjPDScans = pdScans(:, :, 1:3);
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    t1Map = SCIC_T1(adjPDScans, imSerie, acqParam, t1Vect, mask);
                    ctcSet = R1ToGd(1 ./ t1Map);
                    %store ctcSet in the map
                    if ~isa(obj.slcCtcSetMap,'containers.Map')% create map if does not exists
                        obj.slcCtcSetMap = containers.Map(char(obj.slcKS(k)), ctcSet) ;
                        obj.slcT1Map = containers.Map(char(obj.slcKS(k)), t1Map) ;
                    else % else insert into map
                        obj.slcCtcSetMap(char(obj.slcKS(k))) = ctcSet;
                        obj.slcT1Map(char(obj.slcKS(k))) =  t1Map ;
                    end
                    [obj.slcBaselineAvgMap(char(obj.slcKS(k))),...
                        obj.slcBaselineSigmaMap(char(obj.slcKS(k))), ...
                         obj.slcBaselineLengthMap(char(obj.slcKS(k)))] = ...
                                         obj.calculateSlcStats(char(obj.slcKS(k)));
                    obj.calculateSegmentStat(char(obj.slcKS(k)));
                    obj.caculateMyoStats(char(obj.slcKS(k)));
                end
            end %run
            
            %getters
            function t1Map = getT1Map(obj, slcName)
                t1Map = obj.slcT1Map(slcName);
            end
        end %methods (Access = public)
        
        methods (Access = protected)
            
            function prepDicomData(obj, path)
                tmpPath = fullfile(path, 'tmp');
                if isdir(tmpPath)
                    cprintf('green', 'dataPreparator:prepDicomData: step already done for %s . no reason to do it again.\n', path);
                    return;
                end
                dirList = dir(path);
                [~, ind] = sort_nat({dirList.name});
                dirList = dirList(ind);
                mkdir(fullfile(tmpPath, '01_PDScans'));
                mkdir(fullfile(tmpPath, '02_images'));
                
                for k = 3 : 5
                    copyfile(fullfile(path, dirList(k).name),  fullfile(path, 'tmp\01_PDScans'));
                end
                for  k = 6 : length(dirList)
                    copyfile(fullfile(path, dirList(k).name),  fullfile(path, 'tmp\02_images'));
                end
                
            end%prepDicomData
            
            function obj = loadAif(obj)
                obj.aifData.dcmInfo = ...
                    getDicomInfoList(fullfile(obj.aifPath, 'tmp\02_images'));
                
                for k = 1 : length(obj.aifData.dcmInfo)
                    tAcq(k, :) = obj.aifData.dcmInfo(k).AcquisitionTime;
                end
                %set 1st Aif acquisition as the initial acquisition time
                obj.tAcqInitStr =  tAcq(1,:);
                % want acqtime in seconds unit
                obj.aifData.tAcq = getAcqTimes(tAcq, obj.tAcqInitStr) .* 1e-3;
                obj.aifPDScans = loadDcm(fullfile(obj.aifPath, 'tmp\01_PDScans'));
                
                obj.aifSerie = loadDcm(fullfile(obj.aifPath, 'tmp\02_images'));
            end%loadAif
            
            function obj = loadSlc(obj)
                for k = 1 : obj.slcPathMap.length;
                    % load slice images
                    pdScansPath = fullfile(obj.slcPathMap(char(obj.slcKS(k))), 'tmp\01_PDScans');
                    imagesPath  = fullfile(obj.slcPathMap(char(obj.slcKS(k))), 'tmp\02_images');
                    
                    slcData.pdScan.dcmInfo = getDicomInfoList(pdScansPath);
                    slcData.images.dcmInfo = getDicomInfoList(imagesPath);
                    
                    pdScans = loadDcm(pdScansPath);
                    slcSerie = loadDcm(imagesPath);
                    
                    for l = 1 : length(slcData.images.dcmInfo)
                        disp(l);
                        tAcq(l, :) = slcData.images.dcmInfo(l).AcquisitionTime;
                    end
                    
                    % want acqtime in seconds unit
                    slcData.tAcq = getAcqTimes(tAcq, obj.tAcqInitStr) .* 1e-3;
                    
                    if ~isa(obj.slcSerieMap,'containers.Map')% create map if does not exists
                        obj.slcPdScanMap = containers.Map(char(obj.slcKS(k)), pdScans) ;
                        obj.slcSerieMap = containers.Map(char(obj.slcKS(k)), slcSerie) ;
                        obj.slcDataMap = containers.Map(char(obj.slcKS(k)), slcData);
                    else % else insert into map
                        obj.slcPdScanMap(char(obj.slcKS(k))) = pdScans;
                        obj.slcSerieMap(char(obj.slcKS(k))) = slcSerie;
                        obj.slcDataMap(char(obj.slcKS(k))) = slcData;
                    end
                end
            end %loadSlc
            
            % aif time intensity curve to time concentration curve
            function aifTIC2CTC(obj)
                pdScanAvg = mean(obj.aifPDScans, 3);
                r1mapStack = T1Aif(pdScanAvg, obj.aifSerie, obj.aifMask, 0.001 : 0.001 : 4);
                gdMapStack = R1ToGd(1 ./ r1mapStack);
                for k = 1 : size(gdMapStack, 3)
                    tmp = gdMapStack(:, :, k);
                    obj.aifCtc(k) = mean(tmp(obj.aifMask == 1));
                end
            end%aifTIC2TCC
            
            
            function acqParams = getAcqParams(obj, slcName)
                disp('tr should be extracted from DICOM files');
                dcmData = obj.slcDataMap(slcName);
     
                acqParams.faT1 =  dcmData.images.dcmInfo(1).FlipAngle * pi / 180;
                acqParams.faPD = dcmData.pdScan.dcmInfo(1).FlipAngle * pi / 180;
                
                acqParams.totalLines = dcmData.images.dcmInfo(1).AcquisitionMatrix(4); %k-space lines
                if 0 == acqParams.totalLines
                    acqParams.totalLines = dcmData.images.dcmInfo(1).AcquisitionMatrix(3);
                    if 0 == acqParams.totalLines
                        throw(MException('dataPreparatorSCIC:getAcqParams', ...
                            'error trying to get number of line encoding'));
                    end
                end
                acqParams.grappaFactor = dcmData.images.dcmInfo(1).lAccelFactPE;
                acqParams.refLines = dcmData.images.dcmInfo(1).lRefLinesPE;
                acqParams.patMode = dcmData.images.dcmInfo(1).ucPATMode;
                acqParams.refScanMode = dcmData.images.dcmInfo(1).ucRefScanMode; % 0x01: UNDEFINED, 0x02 inplace (integrated), 0x04: EXTRA (separate), 0x08: prescan, 0x10: Intrinsic average
                % 0x20: Intrinsic repetition (TPAT), 0x40 Intrinsic phase, 0x80 Inplace Let (single echo train acquires reference lines and imaging lines
                % 0x100: extra epi (epi sequence supplies extra reference lines)
                
                if acqParams.refScanMode == 2 % inplace (e.g integrated)
                    acqParams.n = double(floor((acqParams.totalLines)/ acqParams.grappaFactor));
                elseif acqParams.refScanMode == 4 % extra (e.g separate)
                    acqParams.n = double(floor((acqParams.totalLines + acqParams.refLines) / acqParams.grappaFactor));
                elseif acqParams.refScanMode == 32 %Intrinsic repetion = TPAT
                    acqParams.refLines = 0;
                    acqParams.n = double(floor((acqParams.totalLines)/ acqParams.grappaFactor));
                else
                    throw(MException('signal2concentration:UnknownBehaviour', 'unknown behaviour for this parameter value'));
                end
                
                acqParams.tr = 2e-3; %ms
                acqParams.ti = dcmData.images.dcmInfo(1).InversionTime * 1e-3;
                acqParams.td = acqParams.ti - ...
                            acqParams.tr * (2 + acqParams.n / 2);
                          
            end%getAcqParams
            
            function [blAvgMap, blSigmaMap, blLenMap] = calculateSlcStats(obj, slcName)
                mask = obj.slcMaskMap(slcName);
                slcData = obj.slcDataMap(slcName);
                ctcSet = obj.slcCtcSetMap(slcName);
                
                [H, W] =  size(mask);
                blSigmaMap = zeros(H, W);
                blAvgMap = zeros(H, W);
                
                %find the closest value of slc tAcq vector to the aif
                %baseline length
                tmp = slcData.tAcq - obj.aifBaselineLength;
                blLenTimePos = find(tmp >= 0, 1, 'first');
                blLen = slcData.tAcq(blLenTimePos);
                
                blLenMap = mask .* blLen;
                
                for k = 1 : H
                    for l = 1 : W
                        if mask(k, l)
                          blAvgMap(k, l)   = mean(ctcSet(k, l, 1 : blLenTimePos));
                          blSigmaMap(k, l) = std (ctcSet(k, l, 1 : blLenTimePos));
                        end
                    end
                end
                
            end%calculateSlcStats
            
            function calculateSegmentStat(obj, slcName)
                ctcSet = obj.slcCtcSetMap(slcName);
                mask = obj.slcMaskMap(slcName);
                slcData = obj.slcDataMap(slcName);
                %get the junction btw
                h = figure; imagesc(ctcSet(:, :, 25)); title('Choose the jonction between RV/LV');
                [pc, pl] = ginput(1);
                close(h); junc = [round(pl), round(pc)];
                tmp = regionprops(mask, 'Centroid'); center = flip(floor(tmp.Centroid));
                switch slcName 
                    case 'apex'
                        nbSectors = 4;
                    otherwise 
                        nbSectors = 6;
                end
                [~, maskStack] = Sector_from_roi_cda(center, junc, mask, ctcSet, nbSectors);
                
                tmp = slcData.tAcq - obj.aifBaselineLength;
                blLenTimePos = find(tmp >= 0, 1, 'first');
                                
                %calculate the segment average ctc for each acquisition on baseline
                for k = 1 : size(maskStack, 3)
                    for l = 1 : blLenTimePos
                        curCtcAcq = ctcSet(:, :, l);
                        avgSectorCtc(l) = mean(curCtcAcq(find(maskStack(:, :, k))));
                        % segmentBlAvgMap(k)   = mean(segmentBlAvgMap(find(maskStack(:, :, k) > 0)));
                        % segmentBlStdMap(k)   = std(segmentBlAvgMap(find(maskStack(:, :, k) > 0)));
                    end
                    segmentBlAvg(k) = mean(avgSectorCtc);
                    segmentBlStd(k) = std(avgSectorCtc);
                end
                obj.slcSgtBaselineAvgMap = mapInsert(obj.slcSgtBaselineAvgMap, slcName, segmentBlAvg);
                obj.slcSgtBaselineStdMap = mapInsert(obj.slcSgtBaselineStdMap, slcName, segmentBlStd);
            end%calculateSegmentStat
            
            function caculateMyoStats(obj, slcName)
                ctcSet = obj.slcCtcSetMap(slcName);
                mask = obj.slcMaskMap(slcName);
                slcData = obj.slcDataMap(slcName);
                tmp = slcData.tAcq - obj.aifBaselineLength;
                blLenTimePos = find(tmp >= 0, 1, 'first');
                for k = 1 : blLenTimePos
                    curCtcAcq = ctcSet(:, :, k);
                    avgMyoCtc(k) = mean(curCtcAcq(find(mask)));
                end
                obj.slcMyoBaselineAvgMap = mapInsert(obj.slcMyoBaselineAvgMap, slcName, mean(avgMyoCtc));
                obj.slcMyoBaselineStdMap = mapInsert(obj.slcMyoBaselineStdMap, slcName, std(avgMyoCtc));
            end%caculateMyoStats
            
            function pdScanAdj = adjustPDScanSignal(obj, pdScans, imSerie, acqParam, t1Vect, mask)
                [~, Sth] = SCIC_T1(pdScans, imSerie, acqParam, t1Vect, mask);
                % we want T1 to be equal to 2.5s
                S_T1_myo = Sth(find(t1Vect > 1.58, 1, 'first'));
                [H, W] = size(mask);
                pdScanAdj = pdScans;
                for l = 1 : H
                    for m = 1 : W
                        if mask(l, m) == 1
                            pdScanAdj(l, m, 1 : 3)  = ones(1,3) .* (imSerie(l, m, 1) / S_T1_myo);
                        end
                    end
                end
            end%adjustPDScanSignal
            
        end % methods (Access = protected)

    
end % classdef dataPreparatorSCIC