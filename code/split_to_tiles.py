# 导入数据
import sys
from glob import glob
from os.path import join
import openslide
import pandas as pd
import numpy as np
import cv2
import xml.dom.minidom
import h5py
import argparse
from datetime import datetime
import os
os.environ['CUDA_LAUNCH_BLOCKING'] = '3'


# 路径问题
path_wd = os.path.dirname(sys.argv[0])
sys.path.append(path_wd)
if not path_wd == '':
    os.chdir(path_wd)
need_save = False


#定义去除轮廓干扰区域
def get_area_ratio(img):
    """去除轮廓内的干扰区域
    :param img: 滑动窗口
    :return: 面积比
    """
    img = np.array(img)

    img = cv2.GaussianBlur(img, (3, 3), 0)
    img_gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    thresh, img_binary = cv2.threshold(img_gray, 200, 255, cv2.THRESH_BINARY)

    # 得到轮廓
    contous, heriachy = cv2.findContours(img_binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    area_list = []
    for contou in contous:
        area = cv2.contourArea(contou)
        area_list.append(area)

    img_w = img.shape[0]
    img_h = img.shape[1]
    area_ratio = sum(area_list)/(img_h * img_w)
    return area_ratio


# 判断是否是肿瘤区域内
def judge_position(contours, point_list):
    """去除轮廓以外选中的干扰区域
    :param contours: 轮廓
    :param point_list: 滑窗的顶点和中心坐标列表
    :return: 是否在轮廓中的状态列表 1在轮廓中 -1 不在轮廓中
    """
    value_list = []
    for point in point_list:
        value = cv2.pointPolygonTest(contours, point, False)
        # yield value
        value_list.append(value)
    return value_list


# 读取XML文件
def load_xml(file_path):
    """读取xml文件，
    返回总坐标列表xy_list:存放一张图片上所有画出域的点 """

    # 用于打开一个xml文件，并将这个文件对象dom变量
    dom = xml.dom.minidom.parse(file_path)
    # 对于知道元素名字的子元素，可以使用getElementsByTagName方法获取
    annotations = dom.getElementsByTagName('Annotation')

    # 存放所有的 Annotation
    xyi_in_annotations = []
    xyn_in_annotations = []

    for Annotation in annotations:

        # 存放一个 Annotation 中所有的 X,Y值
        xy_in_annotation = []

        # 读取 Coordinates 下的 X Y 的值
        coordinates = Annotation.getElementsByTagName("Coordinate")
        for Coordinate in coordinates:
            list_in_annotation = []
            x = int(float(Coordinate.getAttribute("X")))
            y = int(float(Coordinate.getAttribute("Y")))

            list_in_annotation.append(x)
            list_in_annotation.append(y)

            xy_in_annotation.append(list_in_annotation)

        name_area = Annotation.getAttribute("Name")
        if name_area == "normal":
            xyn_in_annotations.append(xy_in_annotation)
        if name_area != "normal":
            xyi_in_annotations.append(xy_in_annotation)

    xy_tuple = (xyi_in_annotations, xyn_in_annotations)

    return xy_tuple


# 读取h5文件
def read_h5(h5_path):
    f = h5py.File(h5_path, 'r')
    slide_list = []
    for name in f:
        for dataset_name in f[name]:
            slide_list.append(dataset_name.tolist())        
    f.close()
    return slide_list


# 读取xml文件
def read_xml(xml_path):
    xy_list = load_xml(xml_path)
    tumor_list = []
    for i in range(len(xy_list)):
        if len(xy_list[i]) == 0:
            continue
        for points in xy_list[i]:
            contours = np.array(points)
            tumor_list.append(contours)
    return tumor_list


def main(images_dir_root,images_dir_split,h5_dir_root,picture_w,points_con_thre,area_ratio_thre,temp,temp_path):
    image_dir_list = glob(images_dir_root)
    for image_dir in image_dir_list:

        if temp == True:
            # 如果已经有指定的数据集，则
            temp_data = pd.read_csv(temp_path,header=0)
            n = temp_data['name'].tolist()
            xml_files = []
            for xml_name in n:
                fin_name = image_dir + "/" + xml_name
                xml_files.append(fin_name)
            print(f"runing the specified data set,the number of datasets is:{len(xml_files)}")

        else:
            # 如果不需要筛选特定的数据，用这一行
            xml_files = glob(join(image_dir, '*.xml'))
            print(f"runing the full data set,the number of datasets is:{len(xml_files)}")
        

        if len(xml_files) == 0:
            # raise FileNotFoundError
            continue
        for index_xml in range(len(xml_files)):
            image_address = xml_files[index_xml].split("xml")[0] + "svs"
            (filepath, filename) = os.path.split(image_address)
            h5_name = filename.split("svs")[0] + "h5"

            tiles_dir = '-'.join(filename.split('-')[:3])
            currentDateAndTime = datetime.now()
            print(f"processing:{tiles_dir},time:{currentDateAndTime}")

            if os.path.exists(os.path.join(images_dir_split, tiles_dir)):
                print(f"the {tiles_dir} path already  exists")
                continue
            else :
                    os.mkdir(os.path.join(images_dir_split, tiles_dir))
            norm_path = os.path.join(images_dir_split, tiles_dir,'normal')


            if not os.path.exists(norm_path):
                    os.mkdir(norm_path)
            tumor_path = os.path.join(images_dir_split, tiles_dir,'tumor')
            if not os.path.exists(tumor_path):
                    os.mkdir(tumor_path)

            slide = openslide.open_slide(image_address)
            tumor_list = read_xml(xml_files[index_xml])
            h5_list = read_h5( h5_dir_root+h5_name )
            i_name = 0
            for pixel_cooeds in h5_list:
                i_name += 1
                x,y = pixel_cooeds[0], pixel_cooeds[1]
                # 去除轮廓外干扰区域
                point_list = [(x+int(picture_w/2), y+int(picture_w/2)), (x, y), (x+picture_w, y),(x, y+picture_w), (x+picture_w, y+picture_w)]

                if_norm=[]
                for i in range(len(tumor_list)):
                    count_list = judge_position(tumor_list[i], point_list)
                    if count_list.count(1.0) < points_con_thre or count_list[0] == -1.0:
                        if_norm.append("Y")
                    else:
                        if_norm.append("N")
                
                if "N" not in if_norm:
                    ret = slide.read_region((x, y), 0, (picture_w, picture_w)).convert('RGB')
                            # 去除轮廓内的白色
                    ratio = get_area_ratio(ret)
                    if ratio < area_ratio_thre:
                        #print("get the {0}th normal picture".format(i_name))
                        # img_resion.append(ret)
                        ret.save(norm_path+"/"+str(i_name)+"_"+str(pixel_cooeds)+".orig.png")
                else:
                    ret = slide.read_region((x, y), 0, (picture_w, picture_w)).convert('RGB')
                            # 去除轮廓内的白色
                    ratio = get_area_ratio(ret)
                    if ratio < area_ratio_thre:
                        #print("get the {0}th normal picture".format(i_name))
                        # img_resion.append(ret)
                        ret.save(tumor_path+"/"+str(i_name)+"_"+str(pixel_cooeds)+".orig.png")   

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='svs to tiles')
    parser.add_argument('--images_dir_root', type=str, default="/data/data/TCGA/lung/Raw_Data")
    parser.add_argument('--images_dir_split', type=str, default="/data2_image_192_168_10_11/data/public_dir/lvyp/project/大连-肺癌-复发转移/data_tiles/TCGA/")
    parser.add_argument('--h5_dir_root', type=str, default="/data/data/TCGA/lung/CLAM/patches/")
    parser.add_argument('--picture_w', type=int, default=256)
    parser.add_argument('--points_con_thre', type=int, default=3)
    parser.add_argument('--area_ratio_thre', type=float, default=0.3)
    parser.add_argument('--prepare_types', type=str, default="svs")
    parser.add_argument('--temp',default=True, action='store_false')
    parser.add_argument('--temp_path', type=str, default="/home/lvyp/Project/dalianlung_project/data/temp.csv")
    args = parser.parse_args()


    print('Processing svs images to tiles')
    available_policies = ["svs", "ndpi"]
    assert args.prepare_types in available_policies, "svs or ndpi slide support only"
    main(args.images_dir_root,
         args.images_dir_split,
         args.h5_dir_root,
         args.picture_w,
         args.points_con_thre,
         args.area_ratio_thre,
         args.temp,
         args.temp_path)