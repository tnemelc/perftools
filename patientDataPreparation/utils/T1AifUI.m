% T1AifUI.m
% brief: 
% T1Aif User Interface
% author: C.Daviller
% date: 06-Sep-2017 


 function  T1AifUI()
 
 
%  %%patient
 path = 'D:\03_Data\01_Acquisitions\Perfusion\Prisma\Patients\databasePerfusion\nonAjoutes\Boncompain_Daniel_AIF_inferieur\CV_epi_DS_AIF_810_STRESS_AIF_57_matlab';
 imageType = 'patient';
%% phantom
% path = 'D:\03_Data\01_Acquisitions\Fantome\FantomeGadoCDA\Prisma\dualAcquisition\2017_06_27\CV_EPI_DS_AIF_810_AIF_0006_matlab';
% imageType =  'phantom';
%%
 pathPdScans = []; pathImSerie = [];
 pdScans = []; imSerie = [];
 pdScanDcmInfo = []; imSerieDcmInfo = [];
 pdScanData = []; imSerieData = [];
 mask = []; roiMask = [];
 H = []; W = [];
 
 loadData(path);
 t1 = 0.005 : 0.005 : 5;
 pdScanAvg = mean(pdScans, 3);
 %% call actual function
t1Map =  T1Aif(pdScanAvg, imSerie, mask, t1);

% get region average
switch imageType
    case 'patient'
        for k = 1 : size(t1Map, 3)
            [t1Map(:, :, k), ~] = roiStatistics(t1Map(:, :, k), roiMask);
        end
    case 'phantom'
        t1Map = roiStatistics(t1Map, roiMask);
end

figure; imagesc(t1Map(:,:,1));
savemat(fullfile(path, 't1Map.mat'), t1Map);


 
 %% inner functions
     function loadData(rootPath)
         %load data
         pathPdScans = fullfile(rootPath, '01_PDScans');
         pathImSerie = fullfile(rootPath, '02_images');
         
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
                 mask = drawMultiRegion(pdScans(:, :, 1), mask);
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