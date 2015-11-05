

img_path_1 = uigetimagefile;
img = imread(img_path_1);


cx=4;
cy=4;
c=1;

figure(1);

for size_f=2:1:5
    for std=2:1:5

        H = fspecial('gaussian',size_f, std);
        img_smooth = imfilter(img,H);
        subplot(cx,cy,c);
        title(['gaussian filter size : ' num2str(size_f) '  & std : ' num2str(std)]); 
        imshow(img_smooth);
        hold on;
   

c=c+1;

    end
   
end
        
hold off;