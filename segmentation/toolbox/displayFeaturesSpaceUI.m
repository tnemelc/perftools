% displayFearturesSpaceUI.m
% brief: 
% displayFearturesSpace User Interface
% author: C.Daviller
% date: 28-Oct-2017 


 function  displayFeaturesSpaceUI()

 dimvectorTab = [ 1      2   10   12   12   15   30   30   32   35; % roi surface
                 30     70   70   70   70   70   25   25   25   25; % time to peak
                 1000 1000 1020 1020 1020 1040 1500 1502 1510 1511]; %AUC
	dimensionsNameKS = {'ROI surface'; 'TTP'; 'AUC'};
             
    displayFeaturesSpace(dimvectorTab, dimensionsNameKS);
end