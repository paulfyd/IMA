from PIL import Image
import matplotlib.image as mpimg
import matplotlib.pyplot as plt
import numpy as np
import cv2

image=cv2.imread('/home/paul/Bureau/Skin_Lesion_DataSet-master-melanoma/melanoma/ISIC_0000046.jpg')
print(image)

fig=plt.figure(figsize=(1,2))

#plt.show()

kernel=np.ones((10,10),np.float32)/100
image_débruitée=cv2.filter2D(image,-1,kernel)
print(image_débruitée)

fig.add_subplot(2,1,2) 
plt.imshow(image_débruitée)
plt.show()




