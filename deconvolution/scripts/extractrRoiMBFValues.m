% extractrRoiMBFValues.m
% brief: 
%
%
% references:
%
%
% input:
% arg1: ...
% arg2: ... 
% output:
%
% arg3: ...
% arg4: ...
%
%
% keywords:
% author: C.Daviller
% date: 05-Apr-2018 


 function extractrRoiMBFValues()
     rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\3T\';
     patientDataSet = {'0001_ARGE', '1001_BODA', '0003_CHAL', ...
         '0005_COCO', '0009_DEAL',  '0002_FACL',...
         '0004_JUMI', '1002_NEMO', '0007_OUGW',...
         '0012_RIAL', '0018_SALI', '0006_THRO'};
    nbPatients = length(patientDataSet);
    slcKS = {'base', 'mid', 'apex'};
    nbSlc = length(slcKS);
    roiLabelsKS = {'lesion', 'normal'};
    nbRoiLabels = length(roiLabelsKS);
    
    methodsKS = {'Bayesian', 'Fermi'};
    nbMethods = length(methodsKS);
    
    %                   MBF Values x (nb Patients *  nbMethods   *  nb of roi     x nb Slices
    roiMbfValsTab = nan(500,          nbPatients  *  nbMethods   *  nbRoiLabels,      nbSlc  );
    
    for k = 1 : length(patientDataSet)
        disp(patientDataSet(k))
        curPatient = char(patientDataSet(k));
        for l = 1 : length(slcKS)
            curSlc = char(slcKS(l));
            %load slice mbf map
            bayesMbfMap = loadmat(fullfile(rootPath, curPatient, 'autoDeconvolution', char(methodsKS(1)), curSlc, 'mbfMap.mat'));
            fermiMbfMap = loadmat(fullfile(rootPath, curPatient, 'autoDeconvolution', char(methodsKS(2)), curSlc, 'mbfMap.mat'));
            roiMap = loadmat(fullfile(rootPath, curPatient, 'segmentation', 'ManualMultiRoiMapDisplay', ['labelsMask_' curSlc '.mat']));
            roisInfo = xml2struct(fullfile(rootPath, curPatient, 'segmentation', 'ManualMultiRoiMapDisplay', ['rois_' curSlc '.xml']));
            roisInfo = roisInfo.rois;
            if iscell(roisInfo.roi)
                roisInfo.roi = cell2mat(roisInfo.roi);
            end
            
            nbRoi = max(roiMap(:));
            %check that roiMap and roisInfos agree about number of rois
            if numel(roisInfo.roi) ~= nbRoi
                throw(MException('extractRoiMBFValues:roiNumberCheck', 'numbers of rois are not equals'));
            end
            
            mbfBayesStr = [];
            mbfFermiStr = [];
            
            linOffset = zeros(1, 2);
            for m = 1 : nbRoi
                [x, y] = ind2sub(size(roiMap), find(roiMap == m));
                % validity check
                if numel(x) ~= str2num(roisInfo.roi(m).surface.Text)
                    throw(MException('extractRoiMBFValues:roiSurfaceCheck', 'roi is not valid'));
                end
                
                mbfBayesStr = sprintf('%s\n roiID: %d, name %s, surface: %d\n', mbfBayesStr, m, roisInfo.roi(m).name.Text, numel(x));
                mbfFermiStr = sprintf('%s\n roiID: %d, name %s, surface: %d\n', mbfFermiStr, m, roisInfo.roi(m).name.Text, numel(x));
                %select roi label for column redirection
                switch roisInfo.roi(m).name.Text
                        case 'normal'
                            roiLabel = 2; %normal roi is labeled 2. other a
                        case 'lesion'
                            roiLabel = 1;
                        case 'lesion2'
                            roiLabel = 1; %put all lesions in the same column
                        otherwise
                            cprintf('Orange', 'roi labeled %s (patient: %s) will not be added to the results summary\n', roisInfo.roi(m).name.Text, curPatient);
                            continue;
                end
                curRoiBayesMbfVal = zeros(numel(x), 1);
                curRoiFermiMbfVal = zeros(numel(x), 1);
                for n = 1 : numel(x)
                    curRoiBayesMbfVal(n) = bayesMbfMap(x(n), y(n));
                    curRoiFermiMbfVal(n) = fermiMbfMap(x(n), y(n));
                    mbfBayesStr = sprintf('%s%0.02f\n', mbfBayesStr, curRoiBayesMbfVal(n));
                    mbfFermiStr = sprintf('%s%0.02f\n', mbfFermiStr, curRoiFermiMbfVal(n));
                    
                    colOffset = (k - 1) * nbMethods * 2 + roiLabel; % offset = patient index * nb methods * nb of rois + curent roi num
                    roiMbfValsTab(linOffset(roiLabel) + n, colOffset, l) = curRoiBayesMbfVal(n);
                    colOffset = (k - 1) * 2 * 2  + 2 + roiLabel; %nb patients offset = patient index * nb methods * nb max of rois + nbMax of rois + curent roi num 
                    roiMbfValsTab(linOffset(roiLabel) + n, colOffset, l) = curRoiFermiMbfVal(n);
                end
                %update lineoffset and add a space to ease rois distinctly
                linOffset(roiLabel) = linOffset(roiLabel) + numel(x) + 1;
                %write results in a string
                mbfBayesStr = sprintf('%s\n', mbfBayesStr);
                mbfFermiStr = sprintf('%s\n', mbfFermiStr);
            end
            fID = fopen(fullfile(rootPath, curPatient, 'autoDeconvolution', [curSlc '_roisMBF.txt']), 'w');
            if 0 < fID
                try
                    fprintf(fID, 'bayesian\n%s\nfermi\n%s\n', mbfBayesStr, mbfFermiStr);
                catch
                    error('error');
                    fclose(fID);
                end
                fclose(fID);
            end
        end
    end
    
    for k = 1 : length(slcKS)
        fid = fopen(fullfile(rootPath, '0000_Results', [char(slcKS(k)) '_roisMbfValues.csv']), 'w');
        if 0 < fid
            try
                for  l = 1 : size(roiMbfValsTab, 1)
                    fprintf(fid, '%0.02f,', roiMbfValsTab(l, : , k));
                    fprintf(fid, '\n', roiMbfValsTab(l, : , k));
                end
            catch
                
                fclose(fid);
            end
            fclose(fid);
        else
            throw(MException('extractRoiMBFValues:file', 'could not open file %s', fullfile(rootPath, '0000_Results', [char(slcKS(k)) '_roisMbfValues.csv'])));
        end
    end
end