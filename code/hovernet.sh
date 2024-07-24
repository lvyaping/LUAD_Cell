export CUDA_VISIBLE_DEVICES=1
python pipelines/StructureUnifier.py  /data/pipelines/structureunifier/Procedures.tsv  /data2_image_192_168_10_11/data/public_dir/lvyp/project/dalian/data_tiles/TCGA/TCGA-80-5608/     --specify_row_index "extractcellularfeaturefrompng"
