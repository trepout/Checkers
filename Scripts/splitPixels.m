% This script is part of the Checker workflow (step 1 & 2)
% It takes as inputs the list of fiducials detected by R4TR and the tilt
% angles to output a single file where fiducials are merged

%% References
%
%   created by ST 01/11/23
%
%   Buckley G., Ramm G. and Trépout S., 'GoldDigger and Checkers, computational developments in
%   cryo-scanning transmission electron tomography to improve the quality of reconstructed volumes'
%   Journal, volume (year), page-page.
%
%   Ramaciotti Centre for CryoEM
%   Monash University
%   15, Innovation Walk
%   Clayton 3168
%   Victoria (The Place To Be)
%   Australia
%   https://www.monash.edu/researchinfrastructure/cryo-em/our-team


%% Need to add path containing MRC reader
addpath(genpath('/home/strepout/st67/Soft/tomography'))

%% Code

clear

% Inpainting parameters
garcia=1;
if garcia == 1
    iterationsG = 150;
end

tiltSeries = ReadMRC('TS_001/TS_001.ali');
nbTilt = size(tiltSeries,3);

ts1 = zeros(size(tiltSeries,1),size(tiltSeries,2),nbTilt);
ts2 = zeros(size(tiltSeries,1),size(tiltSeries,2),nbTilt);

for kk = 1 : nbTilt
            
    % Read the image
    temp = tiltSeries(:,:,kk);
    
    % Allocate in memory
    temp1 = zeros(size(temp,1),size(temp,2));
    temp2 = zeros(size(temp,1),size(temp,2));
    
    % Split it in two (pixel-wise)
    temp1(1 : 2 : size(tiltSeries,1),1 : 2 : size(tiltSeries,2)) = temp(1 : 2 : size(tiltSeries,1),1 : 2 : size(tiltSeries,2));
    temp2(2 : 2 : size(tiltSeries,1),2 : 2 : size(tiltSeries,2)) = temp(2 : 2 : size(tiltSeries,1),2 : 2 : size(tiltSeries,2));
        
    % Inpainting
    if garcia == 1 
        
        temp1(temp1(:) == 0) = nan;
        temp2(temp2(:) == 0) = nan;
        
        tic
        temp1Inp = inpaintn(temp1,iterationsG);
        temp2Inp = inpaintn(temp2,iterationsG);
        toc
    
    end
    
    ts1(:,:,kk) = temp1Inp;
    ts2(:,:,kk) = temp2Inp;    
            
end

WriteMRC(ts1,1,'TS_001/TS_001a_DCT.mrc',2);
WriteMRC(ts2,1,'TS_001/TS_001b_DCT.mrc',2);

