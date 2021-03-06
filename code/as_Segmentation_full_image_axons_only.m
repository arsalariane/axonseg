function as_Segmentation_full_image_axons_only(im_fname,SegParameters,blocksize,overlap,output)
% as_Segmentation_full_image(im_fname,SegParameters,blocksize (# of pixels),overlap,output)
% as_Segmentation_full_image('Control_2.tif', 'SegParameters.mat',2000,100,'Control_2_results')
%
% im_fname: input image (filename)
% SegParameters: output of SegmentationGUI
% blocksize: input image is divided in smaller pieces in order to limit memory usage..
% See also: SegmentationGUI

%% INPUTS
if ~exist('im_fname','var') || isempty(im_fname)
    im_fname=uigetfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';...
          '*.*','All Files' });
end

if ~exist('SegParameters','var') || isempty(SegParameters)
    SegParameters=uigetfile({'*.mat'});
end

load(SegParameters);

if ~exist('blocksize','var') || isempty(blocksize)
    blocksize=1000;
end
if ~exist('overlap','var') || isempty(overlap)
    overlap=200;
end
if ~exist('output','var') || isempty(output)
    [~,name]=fileparts(im_fname);
    output=[name '_Segmentation'];
end

if ~exist(output,'dir'), mkdir(output); end
output=[output filesep];

disp('reading the image')
handles.data.img=imread(im_fname);
if length(size(handles.data.img))==3
    handles.data.img=rgb2gray(handles.data.img(:,:,1:3));
end

%% SEGMENTATION

disp('Starting segmentation..')
AxSeg=as_improc_blockwising(@(x) fullimage(x,SegParameters),handles.data.img,blocksize,overlap,1);
% clean conflicts
%AxSeg=as_blockwise_fun(@(x,y) myelinCleanConflict(x,y,0.5),AxSeg, 1,0);

save([output, 'bwmyelin_seg_results'], 'myelin_seg_results', 'blocksize', 'overlap', 'PixelSize', '-v7.3')
[ axonlist ] = as_myelinseg_blocks_bw2list( AxSeg, PixelSize, blocksize, overlap);
img=cell2mat(cellfun(@(x) x.img, AxSeg,'Uniformoutput',0));
img=as_improc_rm_overlap(img,blocksize,overlap);


%% SAVE
% save axonlist
save([output 'axonlist_full_image.mat'], 'axonlist', 'img', 'PixelSize','-v7.3')
delete([output, 'bwmyelin_seg_results.mat'])


% save jpeg
% save axon display
axons_map=as_display_label(axonlist, size(img),'axonEquivDiameter','axon');
maxdiam=ceil(prctile(cat(1,axonlist.axonEquivDiameter),99));
RGB = ind2rgb8(axons_map,hot(maxdiam*10));
img_diam=0.5*RGB+0.5*repmat(img,[1 1 3]); img_diam=img_diam(1:2:end,1:2:end,:); % divide resolution by two --> some bugs in large images: https://www.mathworks.com/matlabcentral/answers/299662-imwrite-generates-incorrect-files-by-mixing-up-colors
imwrite(img_diam,[output 'axonEquivDiameter_(axons)_0�m_' num2str(maxdiam) '�m.jpg'])

% save myelin display
myelin_map=as_display_label(axonlist, size(img),'axonEquivDiameter','myelin');
RGB = ind2rgb8(myelin_map,hot(maxdiam*10));
imwrite(0.5*RGB+0.5*repmat(img,[1 1 3]),[output 'axonEquivDiameter_(myelins)_0�m_' num2str(maxdiam) '�m.jpg']);
copyfile(which('colorbarhot.png'),output)

function [im_out,AxSeg]=fullimage(im_in,segParam)

% Apply initial parameters (invertion, histogram equalization, convolution)
% to the full image

if segParam.invertColor, im_in=imcomplement(im_in); end
if segParam.histEq, im_in=histeq(im_in,segParam.histEq); end;
if segParam.Deconv,im_in=Deconv(im_in,segParam.Deconv); end;
if segParam.Smoothing, im_in=as_gaussian_smoothing(im_in); end;

AxSeg=step1_full(im_in,segParam);    
    
% Step 2 - discrimination for axon segmentation

if isfield(segParam,'parameters') && isfield(segParam,'DA_classifier')
    AxSeg = as_AxonSeg_predict(AxSeg,segParam.DA_classifier, segParam.parameters,im_in);
else
    AxSeg=step2_full(AxSeg,segParam);
end

[im_out]=AxSeg;

% %Myelin Segmentation
% [AxSeg_rb,~]=RemoveBorder(AxSeg,segParam.PixelSize);
% backBW=AxSeg & ~AxSeg_rb; % backBW = axons that have been removed by RemoveBorder
% [im_out] = myelinInitialSegmention(im_in, AxSeg_rb, backBW,0,1);
