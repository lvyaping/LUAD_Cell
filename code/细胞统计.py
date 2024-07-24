import pandas as pd
import os 
import re
from collections import Counter
import os
os.environ["CUDA_VISIBLE_DEVICES"] = "1" 

raw_path = '/data2_image_192_168_10_11/data/public_dir/lvyp/project/dalian/data_tiles/Hospital_LUAD/'
data = pd.read_csv("/home/lvyp/Project/dalianlung_project/data/temp.csv",header=0)
id_name = data['name'].tolist()

listX=[]
for i in id_name:
    get_name = i
    o_path = raw_path+get_name+"/Hovernet_Output_From_Color_Normalization/normal/qupath/"
    ispath = os.path.exists(o_path)  #判断路径是否存在
    if ispath is True:
        path = os.listdir(o_path)
        for j in path:
            fin_path = o_path+j
            listX.append(fin_path)
    else:
        print(get_name)
        continue
#listX.remove('/data/data/TCGA/breast/Hovernet_Output_From_Color_Normalization/TCGA-D8-A1XL-01Z-00-DX1.FDF07020-8F40-4C00-9023-E5F40E0D8A7C.xml/qupath/TCGA-D8-A1XL-01Z-00-DX1.FDF07020-8F40-4C00-9023-E5F40E0D8A7C_roi0_53732_14443.tsv')
person_prob_dict = dict()
for i in listX:
    people_name = i.split("/")[-5][:-4]
    #people_name = '-'.join(people_name.split('-')[:3])
    print(people_name)
    df = pd.read_csv(i, sep='\t')
    name= df['name'].tolist()
    alll = len(name)
    name_list=set(name)
    print(name_list)
    if people_name not in person_prob_dict.keys():
        person_prob_dict[people_name] = {
                'epithelium': 0, 
                'tumer_cell': 0,
                'lymphocytes': 0,
                'stroma_cell': 0,
                'dead_cell': 0,
                'number': 1,}
    else: 
        person_prob_dict[people_name]['number'] += 1
    for i in name_list:
        count =name.count(i)
        person_prob_dict[people_name][i] +=count

numb=[]
for key in person_prob_dict.keys():
    numb.append([key,person_prob_dict[key]['epithelium'],
                person_prob_dict[key]['tumer_cell'],
                person_prob_dict[key]["lymphocytes"],
                person_prob_dict[key]['stroma_cell'],
                person_prob_dict[key]['dead_cell'],
                person_prob_dict[key]['number']])
#Epithelial_cells	Tumor_cells	lymphocytes	Stromal_cell	Necrosis
total = ['name','Background','Epithelial','Lymphocyte','Macrophage','Neutrophil','number']
pre = pd.DataFrame(numb,columns=total)
print("准备储存数据")
pre.to_csv(f'/home/lvyp/Project/dalianlung_project/data/医院细胞_normal.csv',index=False)





   