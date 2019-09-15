% SCIC_T1UI.m
% brief: 
% SCIC_T1 User Interface
% author: C.Daviller
% date: 28-Aug-2017 


 function  SCIC_T1UI()
    close all;
    
    path = 'D:\03_Data\01_Acquisitions\Perfusion\Prisma\Patients\databasePerfusion\nonAjoutes\Boncompain_Daniel_AIF_inferieur\CV_epi_DS_AIF_810_STRESS_58_MOCO_matlab';
    path = 'D:\03_Data\01_Acquisitions\Perfusion\Prisma\Patients\databasePerfusion\nonAjoutes\Boncompain_Daniel_AIF_inferieur\CV_epi_DS_AIF_810_STRESS_MOCO_NORM_FILT_63_matlab';
    path = 'D:\03_Data\01_Acquisitions\Fantome\FantomeGadoCDA\Prisma\dualAcquisition\2017_06_27\CV_EPI_DS_AIF_810_0007_matlab';
    
    fm = figureMgr.getInstance();
    fm.closeAll();
    % variable declaration
    pathPdScans = []; pathImSerie = [];
    pdScans = []; imSerie = [];
    pdScanDcmInfo = []; imSerieDcmInfo = [];
    pdScanData = []; imSerieData = [];
    mask = []; roiMask = [];
    H = []; W = [];
    
    loadData(path);
    acqParam.tr = imSerieData.tr;
    acqParam.td = imSerieData.td;
    acqParam.faT1 = imSerieData.fa * pi / 180;
    acqParam.faPD = pdScanData.fa * pi / 180;
    acqParam.f = 0.0;% (f is the fraction of M0 that remains along the direction of the
    % static magnetic field, B0, after application of the saturation pulse)
    acqParam.n = floor(imSerieData.nbPE / 2); %number of imaging RF pulses (“shots”)
    
    t1 = 0.005 : 0.005 : 4;
    
    %% kernel call
%     if ~isempty(mask)
%         t1Map = SCIC_T1(pdScans, imSerie(:, :, 6), acqParam, t1, mask);
%     else
        t1Map = SCIC_T1(pdScans + 300, imSerie(:,:,2:end), acqParam, t1, mask);
%     end
    
%% arrange results for display
     [t1mapAvg, t1mapStd] = roiStatistics(t1Map, roiMask); 

    %% save
    savemat(fullfile(path, 't1Map.mat'), t1Map);
    savemat(fullfile(path, 't1mapAvg.mat'), t1mapAvg);
    savemat(fullfile(path, 't1mapStd.mat'), t1mapStd);
    
    
     
    %% display results
    fm.newFig('results');
    subplot(1, 3, 1); imagesc(t1Map(:,:,1)); title('t1map (pixelwise)'); axis off image; color map;
    subplot(1, 3, 2); imagesc(t1mapAvg(:,:,1)); title('t1map (pixelwise)'); axis off image; color map;
    subplot(1, 3, 2); imagesc(t1Map(:,:,17)); title('t1map (pixelwise)'); axis off image; color map;
    subplot(1, 3, 3); imagesc(t1Map(:,:,30)); title('t1map (pixelwise)'); axis off image; color map;
    
    % compare result to ground truth
%     T1compare();
    %% inner functions
    
     function loadData(rootPath)
         %% load data
         pathPdScans = fullfile(rootPath, '01_PDScans');
         pathImSerie = fullfile(rootPath, '02_images');
         
         %image serie
         imSerie = loadDcm(pathImSerie);
         pdScans = loadDcm(pathPdScans);
         [H, W, ~] = size(imSerie);
         
         try
             mask = loadmat(fullfile(pathImSerie, 'mask'));
             try
                roiMask = loadmat(fullfile(pathImSerie, 'roiMask'));
             catch
                 disp('no region mask, only one region must exit');
             end
         catch
             switch questdlg('could not load mask. Wanna create one?')
                 case 'Yes' 
                     createMask();
                     savemat(fullfile(pathImSerie, 'mask'), mask);
                     savemat(fullfile(pathImSerie, 'roiMask'), roiMask);
                 case 'No'
                     mask = [];
                 otherwise
                     mask = [];
             end
         end
         
         % dicom headers
         imSerieDcmInfo = getDicomInfoList(pathImSerie);
         pdScanDcmInfo = getDicomInfoList(pathPdScans);
         
         %extract PDScan Data
         pdScanData.fa = pdScanDcmInfo(1).FlipAngle ;%pdscan flip angle
         pdScanData.totalLines = pdScanDcmInfo(1).AcquisitionMatrix(4); %k-space lines
         pdScanData.grappaFactor = pdScanDcmInfo(1).lAccelFactPE;
         pdScanData.refLines = pdScanDcmInfo(1).lRefLinesPE;
         pdScanData.patMode = pdScanDcmInfo(1).ucPATMode;% 0x01: NONE 0x02: grappa 0x04 SENSE 0x08: MODE_2D 0x10 CAIPIRINA 0x20 SLICE ACCELERATION
         pdScanData.refScanMode = pdScanDcmInfo(1).ucRefScanMode; % 0x01: UNDEFINED, 0x02 inplace (integrated), 0x04: EXTRA (separate), 0x08: prescan, 0x10: Intrinsic average
         % 0x20: Intrinsic repetition (TPAT), 0x40 Intrinsic phase, 0x80 Inplace Let (single echo train acquires reference lines and imaging lines
         % 0x100: extra epi (epi sequence supplies extra reference lines)
         if pdScanData.refScanMode == 2 % inplace (e.g integrated)
             pdScanData.nbPE = double(floor((pdScanData.totalLines)/ pdScanData.grappaFactor));
         elseif pdScanData.refScanMode == 4 % extra (e.g separate)
             pdScanData.nbPE = double(floor((pdScanData.totalLines + pdScanData.refLines)/ pdScanData.grappaFactor));
         elseif pdScanData.refScanMode == 32 %Intrinsic repetion = TPAT
             pdScanData.refLines = 0;
             pdScanData.nbPE = double(floor((pdScanData.totalLines)/ pdScanData.grappaFactor));
         else
             throw(MException('signal2concentration:UnknownBehaviour', 'unknown behaviour for this parameter value'));
         end
         pdScanData.tr = 2 * pdScanDcmInfo(1).EchoTime * 1e-3;
         
         
         %extract image serie
         imSerieData.fa = imSerieDcmInfo(1).FlipAngle ;%pdscan flip angle
         imSerieData.totalLines = imSerieDcmInfo(1).AcquisitionMatrix(3); %k-space lines
         imSerieData.grappaFactor = imSerieDcmInfo(1).lAccelFactPE;
         imSerieData.refLines = imSerieDcmInfo(1).lRefLinesPE;
         imSerieData.patMode = imSerieDcmInfo(1).ucPATMode;% 0x01: NONE 0x02: grappa 0x04 SENSE 0x08: MODE_2D 0x10 CAIPIRINA 0x20 SLICE ACCELERATION
         imSerieData.refScanMode = imSerieDcmInfo(1).ucRefScanMode; % 0x01: UNDEFINED, 0x02 inplace (integrated), 0x04: EXTRA (separate), 0x08: prescan, 0x10: Intrinsic average
         % 0x20: Intrinsic repetition (TPAT), 0x40 Intrinsic phase, 0x80 Inplace Let (single echo train acquires reference lines and imaging lines
         % 0x100: extra epi (epi sequence supplies extra reference lines)
         if imSerieData.refScanMode == 2 % inplace (e.g integrated)
             imSerieData.nbPE = double(floor((imSerieData.totalLines)/ imSerieData.grappaFactor));
         elseif imSerieData.refScanMode == 4 % extra (e.g separate)
             imSerieData.nbPE = double(floor((imSerieData.totalLines + imSerieData.refLines)/ imSerieData.grappaFactor));
         elseif imSerieData.refScanMode == 32 %Intrinsic repetion = TPAT
             imSerieData.refLines = 0;
             imSerieData.nbPE = double(floor((imSerieData.totalLines)/ imSerieData.grappaFactor));
         else
             throw(MException('signal2concentration:UnknownBehaviour', 'unknown behaviour for this parameter value'));
         end
         %imSerieData.tr = 2 * imSerieDcmInfo(1).EchoTime * 1e-3;
         
         imSerieData.tr = 2 * 1e-3;
         
         imSerieData.ti = imSerieDcmInfo(1).InversionTime * 1e-3;
         
         imSerieData.td = imSerieData.ti - imSerieData.tr * (2 + imSerieData.nbPE / 2);
         
     end
 
     function createMask()
         mask = zeros(H, W);
         roiMask = zeros(H, W);
         switch questdlg('could not load mask. Wanna create one?', 'mask question', 'rectangular', 'multi-regions', 'rectangular');
             case 'rectangular' 
                 figure; imagesc(imSerie(:, :, 2)); colormap(gray); axis off image; 
                 [CropROI, rect] = imcrop;
                 mask(rect(2) : (rect(2) + rect(4)), rect(1) : (rect(1) + rect(3))) = 1;
                 title ('Select your ROI using the mouse');
             case 'multi-regions'
                 mask = drawMultiRegion(imSerie(:, :, 17), mask);
             otherwise
                 trhow(MException('SCIC_T1UI:createMask', 'could not interpret dialog response'));
         end
     end
 
    function mask = drawMultiRegion(img, mask)
         h = fm.newFig('SamplesRegions');
         roiCtr = 1;
         minVal = min(img(:));
         maxVal = max(img(:));
         img = (img + abs(minVal)) / maxVal - minVal;
         roiCount = 1;
         while 1
             subplot(1,2,1); %imagesc(img);
             title('draw sample region');
             tmp = roipoly(img);
             mask = mask + tmp;
             roiMask = roiMask + tmp .* roiCount; roiCount = roiCount + 1;
             subplot(1,2,2); imagesc(mask); axis off image;
             if ~strcmp('Yes', questdlg('draw new region?'))
                 return
             end
         end
         close(h);
     end
 end