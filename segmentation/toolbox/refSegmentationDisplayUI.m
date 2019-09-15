% refSegmentationDisplayUI.m
% brief: 
% refSegmentationDisplay User Interface
% author: C.Daviller
% date: 24-Oct-2017 


 function  refSegmentationDisplayUI()

 rootpath = 'D:\03_Data\01_Acquisitions\Perfusion\Prisma\Patients\databasePerfusion\nonAjoutes\anaylsesSegmentation';
 patientSet = {'Arthaud_Gerard-new', 'Chassard_Alain-new',...
     'Delahais_Albert-new', 'Jurine_Michel__new',...
     'Outters_Gwenael', 'Rivolier_Alain-new', 'Thioliere_Roger__Mr_new'};
%  tissueClass = 'lesion'; c = '*r';
 tissueClass = 'normal'; c = '*g';
 
 featuresNamesKS = {'TTP', 'ROI surface', 'AUC'};
 ticFeatures = [];
%  patientSet = {'Outters_Gwenael'};
 for k = 1: length(patientSet)
%      close all;
     fprintf('running patient %s\n', char(patientSet(k)));
     temp = refSegmentationDisplay(fullfile(rootpath, char(patientSet(k))), tissueClass);
     if ~isempty(removeErrorPoints(temp)) 
        displayFeaturesSpace(removeErrorPoints(temp), featuresNamesKS, c);
     end
     ticFeatures =[ticFeatures temp];
     disp('press any key to continue');
     %pause;
 end
  
  removeErrorPoints(ticFeatures)
  dispTicFeatures = removeErrorPoints(ticFeatures);
  
  cprintf('orange', 'found %d errors over %d points\n', size(ticFeatures, 2) - size(dispTicFeatures, 2), size(ticFeatures, 2));
  cprintf('green',  'displayed %d points\n', size(dispTicFeatures, 2));
  
  
  %inner functions
     function features = removeErrorPoints(features)
         tmp = [];
         cpt = 1;
         for l = 1 : size(features, 2)
             if [-1; -1; -1] ~= features(:, l)
                 tmp(:, cpt) = features(:, l);
                 cpt = cpt + 1; 
             end
         end
         features = tmp;
     end%removeErrorPoints
 
end